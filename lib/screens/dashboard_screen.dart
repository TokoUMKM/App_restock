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

  // Data User untuk Header
  String _ownerName = "Pemilik Toko";
  String _shopName = "Toko Saya";

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load nama user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();            
      _checkStockForNotification(); 
    });
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      setState(() {
        _ownerName = meta?['full_name'] ?? "Juragan";
        _shopName = meta?['shop_name'] ?? "UMKM Pintar";
      });
    }
  }

  void _checkStockForNotification() {
    final products = ref.read(productListProvider);
    if (products.isNotEmpty) NotificationService.checkAndShowStockAlert(products);
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    const String key = 'has_seen_tutorial_dashboard_v2'; // Ganti key biar tutorial muncul lagi di UI baru
    bool seen = prefs.getBool(key) ?? false;

    if (!seen) {
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([
          _fourAnalysisKey, 
          _twoManualKey,    
          _threeReportKey,  
        ]);
        await prefs.setBool(key, true);
      }
    }
  }

  List<Map<String, dynamic>> _normalizeChartData(List<Map<String, dynamic>> backendData) {
    List<Map<String, dynamic>> normalized = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = now.subtract(Duration(days: i));
      String dayName = DateFormat('E', 'id_ID').format(targetDate); 
      var dataFound = backendData.firstWhere((element) => element['day_name'].toString().toLowerCase().contains(DateFormat('E').format(targetDate).toLowerCase()), orElse: () => {'total_qty': 0});
      normalized.add({'day': dayName, 'qty': (dataFound['total_qty'] as num).toDouble()});
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final criticalProducts = products.where((p) => p.currentStock == 0 || p.currentStock <= p.minStock).toList();
    final totalStock = products.fold(0, (sum, item) => sum + item.currentStock);

    // Navigasi
    void openCamera() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
    void openInputManual() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())); 
    void openReports() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
    void openSupplier() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierScreen()));
    void openAnalysis() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(productListProvider.notifier).loadProducts();
          ref.refresh(weeklySalesProvider);
          _checkStockForNotification(); 
          _loadUserData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- HEADER MODERN ---
            SliverToBoxAdapter(
              child: ModernDashboardHeader(
                ownerName: _ownerName,
                shopName: _shopName,
                onResetTutorial: () {
                   SharedPreferences.getInstance().then((prefs) {
                     prefs.remove('has_seen_tutorial_dashboard_v2'); 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tutorial di-reset. Restart halaman.")));
                   });
                },
              ),
            ),

            // --- KONTEN DASHBOARD ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Padding sedikit diperbesar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Insight Card (Stok Kritis)
                    Showcase(
                      key: _fourAnalysisKey, 
                      title: 'Analisa Stok', 
                      description: 'Cek barang kosong/menipis di sini.', 
                      child: _buildInsightCard(context, products, criticalProducts.length, openAnalysis)
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Ringkasan Total
                    _buildUnifiedMetricCard(products.length, totalStock),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Action List
                    const Text("Aksi Cepat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100, // Tinggi diperbesar sedikit agar tidak kepotong
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none, // Agar shadow tidak terpotong
                        children: [
                          _buildActionBtn("Scan Struk", Icons.qr_code_scanner_rounded, const Color(0xFF2962FF), onTap: openCamera),
                          Showcase(
                            key: _twoManualKey, 
                            title: 'Input Manual', 
                            description: 'Tambah barang tanpa scan.', 
                            child: _buildActionBtn("Input Manual", Icons.edit_note_rounded, Colors.teal, onTap: openInputManual)
                          ),
                          Showcase(
                            key: _threeReportKey, 
                            title: 'Laporan', 
                            description: 'Lihat performa toko.', 
                            child: _buildActionBtn("Laporan", Icons.bar_chart_rounded, Colors.orange, onTap: openReports)
                          ),
                          _buildActionBtn("Supplier", Icons.local_shipping_rounded, Colors.indigo, onTap: openSupplier),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Grafik Penjualan
                    const Text("Grafik 7 Hari Terakhir", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20), 
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              const Text("Barang Terjual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)), 
                              ref.watch(weeklySalesProvider).maybeWhen(
                                data: (d) => Text("Total: ${d.fold(0, (s, i) => s + (i['total_qty'] as num).toInt())}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF))), 
                                orElse: () => const SizedBox()
                              )
                            ]
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 150, 
                            child: ref.watch(weeklySalesProvider).when(
                              loading: () => const Center(child: CircularProgressIndicator()), 
                              error: (err, stack) => Center(child: Text("Gagal memuat data", style: TextStyle(color: Colors.red))), 
                              data: (salesData) {
                                final normalizedData = _normalizeChartData(salesData);
                                double maxY = 0; for (var item in normalizedData) { if (item['qty'] > maxY) maxY = item['qty']; } if (maxY == 0) maxY = 10;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround, 
                                  crossAxisAlignment: CrossAxisAlignment.end, 
                                  children: normalizedData.map((d) => _buildBar(d['day'].toString(), d['qty'], maxY)).toList()
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildInsightCard(BuildContext context, List<Product> products, int dangerCount, VoidCallback onTap) {
    bool isStoreEmpty = products.isEmpty; bool isSafe = dangerCount == 0;
    Color bgColor, borderColor, iconColor, textColor; IconData icon; String title, subtitle;
    if (isStoreEmpty) { bgColor = Colors.white; borderColor = Colors.grey.shade300; iconColor = Colors.grey; textColor = Colors.grey.shade700; title = "Toko Kosong"; subtitle = "Mulai tambahkan barang."; icon = Icons.store_mall_directory_outlined; } 
    else if (!isSafe) { bgColor = const Color(0xFFFFF0F0); borderColor = const Color(0xFFFFCDD2); iconColor = Colors.red; textColor = Colors.red.shade900; title = "Perlu Restock!"; subtitle = "$dangerCount barang stoknya kritis."; icon = Icons.warning_rounded; } 
    else { bgColor = Colors.green.shade50; borderColor = Colors.green.shade200; iconColor = Colors.green; textColor = Colors.green.shade900; title = "Stok Aman"; subtitle = "Semua barang tersedia."; icon = Icons.check_circle_rounded; }
    
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]), child: Row(children: [Icon(icon, color: iconColor, size: 36), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), Text(subtitle, style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)))])), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)])));
  }

  Widget _buildUnifiedMetricCard(int totalSku, int totalUnit) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [Expanded(child: Column(children: [Text("$totalSku", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)), const Text("Jenis Barang", style: TextStyle(color: Colors.grey, fontSize: 12))])), Container(height: 40, width: 1, color: Colors.grey.shade200), Expanded(child: Column(children: [Text("$totalUnit", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)), const Text("Total Unit Stok", style: TextStyle(color: Colors.grey, fontSize: 12))]))]));
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(padding: const EdgeInsets.only(right: 20), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(children: [Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(icon, color: color, size: 28)), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87))])));
  }

  Widget _buildBar(String label, double value, double max) {
    double percentage = max == 0 ? 0 : value / max; if (percentage > 1) percentage = 1;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [Stack(alignment: Alignment.bottomCenter, children: [Container(width: 12, height: 100, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))), Container(width: 12, height: 100 * percentage, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF2962FF), Color(0xFF448AFF)]), borderRadius: BorderRadius.circular(6)))]), const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: value > 0 ? FontWeight.bold : FontWeight.normal))]);
  }
}

// --- CLASS BARU: MODERN HEADER ---
class ModernDashboardHeader extends StatelessWidget {
  final String ownerName;
  final String shopName;
  final VoidCallback onResetTutorial;

  const ModernDashboardHeader({
    super.key, 
    required this.ownerName, 
    required this.shopName,
    required this.onResetTutorial,
  });

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
        color: Color(0xFF2962FF), // Warna Biru Utama
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
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
                    Text(
                      "${getGreeting()},", 
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ownerName, // Nama Pemilik (Dinamis)
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  shopName, // Nama Toko (Dinamis)
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Tombol Reset Tutorial (Icon kecil di kanan atas)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: "Bantuan / Reset Tutorial",
              onPressed: onResetTutorial,
            ),
          )
        ],
      ),
    );
  }
}