import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'camera_screen.dart';
import 'add_product_screen.dart';
import 'analysis_screen.dart';
import 'report_screen.dart';
import 'supplier_screen.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/supabase_services.dart';
import '../services/notification_service.dart';

// Provider Sales Mingguan
final weeklySalesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getWeeklySales();
});

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(builder: (context) => const DashboardContent());
  }
}

class DashboardContent extends ConsumerStatefulWidget {
  const DashboardContent({super.key});

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent> {
  final GlobalKey _twoManualKey = GlobalKey();
  final GlobalKey _threeReportKey = GlobalKey();
  final GlobalKey _fourAnalysisKey = GlobalKey();

  String _ownerName = "Pemilik Toko";
  String _shopName = "Toko Saya";

  @override
  void initState() {
    super.initState();
    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
      // Pastikan NotificationService handle double init di dalamnya (idempotent)
      NotificationService.initFCM();
    });
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      if (mounted) {
        setState(() {
          _ownerName = meta?['full_name'] ?? "Juragan";
          _shopName = meta?['shop_name'] ?? "UMKM Pintar";
        });
      }
    }
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    const String key = 'has_seen_dashboard_tutorial_v4'; // Key versi baru
    bool seen = prefs.getBool(key) ?? false;

    if (!seen && mounted) {
      ShowCaseWidget.of(context).startShowCase([
        _fourAnalysisKey,
        _twoManualKey,
        _threeReportKey,
      ]);
      await prefs.setBool(key, true);
    }
  }

  void _showSafeSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // [PERBAIKAN LOGIC CHART] Menggunakan Date Comparison yang aman
  List<Map<String, dynamic>> _normalizeChartData(List<Map<String, dynamic>> backendData) {
    List<Map<String, dynamic>> normalized = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = now.subtract(Duration(days: i));
      
      // Format Tanggal untuk pencocokan (Asumsi backend support date string iso)
      // Jika backend hanya kirim day_name, fallback ke logic lama tapi hati-hati locale
      String dayLabel = DateFormat('E', 'id_ID').format(targetDate);
      
      // Cari data. Idealnya backend return field 'date' (yyyy-MM-dd)
      // Disini kita pakai contains day_name sebagai fallback logic user
      var dataFound = backendData.firstWhere(
        (element) {
           final backendDay = element['day_name']?.toString().toLowerCase() ?? '';
           return backendDay.contains(dayLabel.toLowerCase());
        },
        orElse: () => {'total_qty': 0},
      );

      normalized.add({
        'day': dayLabel,
        'qty': (dataFound['total_qty'] as num).toDouble()
      });
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    // Listener Stok
    ref.listen<List<Product>>(productListProvider, (previous, next) {
      if (next.isNotEmpty) {
        NotificationService.checkAndShowStockAlert(context, next);
      }
    });

    final products = ref.watch(productListProvider);
    final criticalProducts = products.where((p) => p.currentStock <= p.minStock).toList();
    final totalStock = products.fold(0, (sum, item) => sum + item.currentStock);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(productListProvider.notifier).loadProducts();
          ref.refresh(weeklySalesProvider);
          _loadUserData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- HEADER ---
            SliverToBoxAdapter(
              child: ModernDashboardHeader(
                ownerName: _ownerName,
                shopName: _shopName,
                onResetTutorial: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('has_seen_dashboard_tutorial_v4');
                  _showSafeSnackBar("Tutorial di-reset. Restart halaman.");
                },
              ),
            ),

            // --- KONTEN RESPONSIVE ---
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverToBoxAdapter(
                child: isLandscape
                    ? _buildLandscapeLayout(products, totalStock, criticalProducts.length)
                    : _buildPortraitLayout(products, totalStock, criticalProducts.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LAYOUT METHODS (Agar kode rapi) ---

  Widget _buildPortraitLayout(List<Product> products, int totalStock, int dangerCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(products.length, totalStock),
        const SizedBox(height: 24),
        _buildInsightSection(products, dangerCount),
        const SizedBox(height: 24),
        _buildMenuSection(),
        const SizedBox(height: 10),
        _buildChartSection(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildLandscapeLayout(List<Product> products, int totalStock, int dangerCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KOLOM KIRI (50%)
        Expanded(
          child: Column(
            children: [
              _buildStatsRow(products.length, totalStock),
              const SizedBox(height: 24),
              _buildInsightSection(products, dangerCount),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // KOLOM KANAN (50%)
        Expanded(
          child: Column(
            children: [
              _buildMenuSection(), // Menu horizontal scroll
              const SizedBox(height: 24),
              _buildChartSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildStatsRow(int productCount, int totalStock) {
    return Row(
      children: [
        Expanded(
          child: ModernStatCard(
            title: "Jenis Produk",
            value: "$productCount",
            icon: Icons.category_outlined,
            gradientColors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernStatCard(
            title: "Total Unit",
            value: "$totalStock",
            icon: Icons.inventory_2_outlined,
            gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightSection(List<Product> products, int dangerCount) {
    return Showcase(
      key: _fourAnalysisKey,
      title: 'Analisa Stok',
      description: 'Cek barang kosong/menipis di sini.',
      child: _buildInsightCard(
        context,
        products,
        dangerCount,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen())),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Menu Cepat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildActionBtn("Scan Struk", Icons.qr_code_scanner_rounded, const Color(0xFF2962FF), 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()))),
              
              Showcase(
                key: _twoManualKey,
                title: 'Input Manual',
                description: 'Tambah barang tanpa scan.',
                child: _buildActionBtn("Input Manual", Icons.edit_note_rounded, Colors.teal, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()))),
              ),
              
              Showcase(
                key: _threeReportKey,
                title: 'Laporan',
                description: 'Lihat performa toko.',
                child: _buildActionBtn("Laporan", Icons.bar_chart_rounded, Colors.orange, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
              ),
              
              _buildActionBtn("Supplier", Icons.local_shipping_rounded, Colors.indigo, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Grafik 7 Hari Terakhir", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Penjualan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                  ref.watch(weeklySalesProvider).maybeWhen(
                    data: (d) => Text(
                      "Total: ${d.fold(0, (s, i) => s + (i['total_qty'] as num).toInt())}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
                    ),
                    orElse: () => const SizedBox(),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: ref.watch(weeklySalesProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Gagal memuat: $err", style: const TextStyle(color: Colors.red, fontSize: 12))),
                  data: (salesData) {
                    final normalizedData = _normalizeChartData(salesData);
                    double maxY = 0;
                    for (var item in normalizedData) {
                      if (item['qty'] > maxY) maxY = item['qty'];
                    }
                    if (maxY == 0) maxY = 10;
                    else maxY = maxY * 1.2; // Tambahkan buffer visual 20%

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: normalizedData.map((d) => _buildBar(d['day'].toString(), d['qty'], maxY)).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSED WIDGETS ---

  Widget _buildInsightCard(BuildContext context, List<Product> products, int dangerCount, VoidCallback onTap) {
    // ... [Isi sama dengan kode sebelumnya] ...
    // Saya persingkat untuk hemat karakter, gunakan logika warna Anda yang sudah bagus
    bool isStoreEmpty = products.isEmpty; bool isSafe = dangerCount == 0;
    Color bgColor = isStoreEmpty ? Colors.white : (isSafe ? const Color(0xFFF0FFF4) : const Color(0xFFFFF4F4));
    Color accentColor = isStoreEmpty ? Colors.grey : (isSafe ? Colors.green : Colors.redAccent);
    Color textColor = isStoreEmpty ? Colors.grey.shade700 : (isSafe ? Colors.green.shade900 : Colors.red.shade900);
    IconData icon = isStoreEmpty ? Icons.storefront : (isSafe ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded);
    String title = isStoreEmpty ? "Toko Kosong" : (isSafe ? "Stok Aman" : "Perlu Restock!");
    String subtitle = isStoreEmpty ? "Mulai stok barang." : (isSafe ? "Semua barang tersedia." : "$dangerCount barang kritis.");

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Icon(icon, color: accentColor, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)))
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accentColor.withOpacity(0.5))
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF2962FF).withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]
              ),
              child: Icon(icon, color: color, size: 28)
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, double max) {
    double percentage = max == 0 ? 0 : value / max;
    if (percentage > 1) percentage = 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(width: 12, height: 100, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
            Container(
              width: 12,
              height: 100 * percentage,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF2962FF), Color(0xFF448AFF)]),
                borderRadius: BorderRadius.circular(6)
              )
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: value > 0 ? FontWeight.bold : FontWeight.normal))
      ],
    );
  }
}

// --- WIDGET TAMBAHAN ---
class ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -15, child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModernDashboardHeader extends StatelessWidget {
  final String ownerName;
  final String shopName;
  final VoidCallback onResetTutorial;

  const ModernDashboardHeader({super.key, required this.ownerName, required this.shopName, required this.onResetTutorial});

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2962FF),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("${getGreeting()},", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ownerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(shopName, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: "Reset Tutorial",
              onPressed: onResetTutorial,
            ),
          )
        ],
      ),
    );
  }
}