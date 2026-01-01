import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/pdf_service.dart';
import '../services/thermal_service.dart'; 
import '../screens/printer_settings_screen.dart';    

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // Format Mata Uang
  final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- [PERBAIKAN] HELPER SNACKBAR AGAR TIDAK GANGGU BOTTOM BAR ---
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars(); // Hapus antrian alert lama
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF323232),
        behavior: SnackBarBehavior.floating, // PENTING: Agar melayang
        // PENTING: Margin bawah 100px agar muncul DI ATAS Bottom Bar & Tombol Scan
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ===========================================================================
  // 1. PILIH METODE PEMBAYARAN
  // ===========================================================================
  void _showPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // --- OPSI 1: TUNAI (AKTIF) ---
                  Expanded(
                    child: _buildPaymentOption(
                      icon: Icons.money_rounded,
                      label: "Tunai",
                      color: const Color(0xFF2E7D32), // Hijau Modern
                      isActive: true,
                      onTap: () {
                        Navigator.pop(context); 
                        _processCashPayment(); 
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // --- OPSI 2: QRIS (COMING SOON) ---
                  Expanded(
                    child: _buildPaymentOption(
                      icon: Icons.qr_code_2_rounded,
                      label: "QRIS\n(Segera Hadir)",
                      color: Colors.grey, 
                      isActive: false,
                      onTap: () {
                        // [UPDATE] Gunakan helper snackbar baru
                        _showSnack("Fitur QRIS sedang dalam pengembangan.", isError: true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon, 
    required String label, 
    required Color color, 
    required bool isActive,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : Colors.grey.shade200, 
            width: 1.5
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. LOGIKA PEMBAYARAN TUNAI
  // ===========================================================================
  void _processCashPayment() {
    final total = ref.read(cartProvider.notifier).totalPrice;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Tunai"),
        content: Text("Terima pembayaran sebesar:\n${currency.format(total)}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeTransaction("Tunai"); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Terima & Cetak"),
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. FINALISASI TRANSAKSI (UPDATE DB & CETAK)
  // ===========================================================================
  Future<void> _finalizeTransaction(String paymentMethod) async {
    final cartItems = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    
    if (cartItems.isEmpty) return;

    final itemsToPrint = List<CartItem>.from(cartItems);
    final totalToPrint = cartNotifier.totalPrice;

    // Ambil Data Toko
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    final shopName = meta['shop_name'] ?? "Toko Saya";
    final shopAddress = meta['shop_address'] ?? "";
    final shopPhone = meta['shop_phone'] ?? "";
    final ownerName = meta['full_name'] ?? "Kasir";

    try {
      // Loading Indicator
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator())
      );

      // A. Update Database (Kurangi Stok)
      for (var item in cartItems) {
        if (item.product.id != null) {
          await ref.read(productListProvider.notifier).sellProduct(item.product.id!, item.qty);
        }
      }

      // B. Bersihkan Keranjang
      cartNotifier.clearCart();
      
      if (context.mounted) Navigator.pop(context); // Tutup Loading

      // C. Dialog Sukses & Cetak
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60), 
                const SizedBox(height: 12), 
                Text("Lunas via $paymentMethod", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ],
            ),
            content: Text("Total: ${currency.format(totalToPrint)}\nPilih metode cetak struk:", textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("Tutup", style: TextStyle(color: Colors.grey))
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18), 
                label: const Text("PDF"),
                onPressed: () {
                  Navigator.pop(ctx);
                  PdfInvoiceService.printReceipt(
                    items: itemsToPrint, 
                    total: totalToPrint, 
                    cashierName: ownerName, 
                    shopName: shopName,
                    shopAddress: shopAddress,
                    shopPhone: shopPhone,
                    paymentMethod: paymentMethod 
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18), 
                label: const Text("Print"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF), foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ThermalPrinterService().printReceipt(
                      items: itemsToPrint, 
                      total: totalToPrint, 
                      shopName: shopName,      
                      shopAddress: shopAddress, 
                      shopPhone: shopPhone,    
                      cashierName: ownerName,
                      paymentMethod: paymentMethod 
                    );
                  } catch (e) {
                    // [UPDATE] Helper Snack
                    _showSnack("Info Printer: $e");
                  }
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        // [UPDATE] Helper Snack Error
        _showSnack("Gagal memproses: $e", isError: true);
      }
    }
  }

  // ===========================================================================
  // 4. UI BUILD (TAMPILAN UTAMA)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productListProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    // Filter Pencarian
    final displayProducts = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Kasir", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_disabled_outlined, color: Colors.black54),
            tooltip: "Setting Printer",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
          ),
          // Indikator Cart di AppBar
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                tooltip: "Lihat Keranjang",
                onPressed: () => _showCartDetail(context, ref),
              ),
              if (cartNotifier.totalItems > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text("${cartNotifier.totalItems}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: "Reset Keranjang",
            onPressed: () {
              if (cartItems.isNotEmpty) {
                 cartNotifier.clearCart();
                 // [UPDATE] Helper Snack
                 _showSnack("Keranjang dikosongkan");
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari nama barang...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    }) 
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                fillColor: Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // GRID PRODUK
          Expanded(
            child: displayProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300), 
                        const SizedBox(height: 16),
                        const Text("Barang tidak ditemukan", style: TextStyle(color: Colors.grey))
                      ]
                    )
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180, // Sedikit lebih lebar
                      childAspectRatio: 0.7, 
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      final p = displayProducts[index];
                      final inCart = cartItems.firstWhere((item) => item.product.id == p.id, orElse: () => CartItem(product: p, qty: 0));
                      return _buildProductCard(p, inCart.qty, cartNotifier);
                    },
                  ),
          ),
          
          // BOTTOM PANEL
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -4))], 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30))
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${cartNotifier.totalItems} Barang", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(currency.format(cartNotifier.totalPrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87))),
                        InkWell(
                          onTap: () => _showCartDetail(context, ref), 
                          child: const Padding(
                            padding: EdgeInsets.only(top: 6), 
                            child: Row(
                              children: [
                                Text("Lihat Rincian", style: TextStyle(color: Color(0xFF2962FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: Color(0xFF2962FF))
                              ],
                            )
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20), 
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty ? null : _showPaymentMethodDialog, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF), 
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF2962FF).withOpacity(0.4)
                        ),
                        child: const Text("BAYAR", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: KARTU PRODUK ---
  Widget _buildProductCard(Product p, int qty, CartNotifier notifier) {
    bool isOutOfStock = p.currentStock <= 0;
    bool isSelected = qty > 0;
    bool isLowStock = !isOutOfStock && p.currentStock <= p.minStock;

    // Tentukan Warna
    Color iconBgColor;
    Color iconColor;

    if (isOutOfStock) {
      iconBgColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade400;
    } else if (isSelected) {
      iconBgColor = const Color(0xFFE3F2FD); 
      iconColor = const Color(0xFF2962FF); 
    } else if (isLowStock) {
       iconBgColor = const Color(0xFFFFF3E0); 
       iconColor = Colors.orange;
    } else {
      iconBgColor = const Color(0xFFF2FBF4); 
      iconColor = Colors.green;
    }

    return GestureDetector(
      onTap: isOutOfStock ? null : () => notifier.addItem(p),
      onLongPress: isOutOfStock ? null : () => notifier.decreaseItem(p.id!), 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: isSelected ? const Color(0xFF2962FF) : Colors.transparent, 
            width: 2
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BAGIAN ATAS (ICON & BADGE)
            Expanded(
              flex: 3, 
              child: Container(
                decoration: BoxDecoration(
                  color: iconBgColor, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18))
                ), 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isOutOfStock ? Icons.block_rounded : Icons.inventory_2_rounded, 
                      size: 36, 
                      color: iconColor
                    ),
                    if (isSelected) 
                      Positioned(
                        top: 8, right: 8, 
                        child: Container(
                          width: 26, height: 26,
                          decoration: const BoxDecoration(color: Color(0xFF2962FF), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text("$qty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))
                        )
                      )
                  ],
                ),
              )
            ),

            // BAGIAN BAWAH (INFO)
            Expanded(
              flex: 4, 
              child: Padding(
                padding: const EdgeInsets.all(12), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Text(
                      p.name, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(
                        fontWeight: FontWeight.w600, 
                        fontSize: 13, 
                        color: isOutOfStock ? Colors.grey : Colors.black87
                      )
                    ), 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(p.price), 
                          style: TextStyle(
                            fontWeight: FontWeight.w800, 
                            fontSize: 14, 
                            color: isOutOfStock ? Colors.grey : const Color(0xFF2962FF)
                          )
                        ),
                        const SizedBox(height: 4),
                        // --- SISA STOK DISPLAY ---
                        Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : Colors.green)
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOutOfStock ? "Habis" : "Sisa: ${p.currentStock}",
                              style: TextStyle(
                                fontSize: 11,
                                color: isOutOfStock ? Colors.red : Colors.grey.shade600,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  ]
                )
              )
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: DETAIL CART ---
  void _showCartDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final items = ref.watch(cartProvider);
          final notifier = ref.read(cartProvider.notifier);
          
          return Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                // Header Sheet
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Rincian Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                
                // List Item
                Expanded(
                  child: items.isEmpty 
                    ? const Center(child: Text("Keranjang Kosong"))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text(currency.format(item.product.price * item.qty), style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.w600)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.remove_rounded, size: 18), onPressed: () => notifier.decreaseItem(item.product.id!), constraints: const BoxConstraints(), padding: const EdgeInsets.all(8)),
                                  Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add_rounded, size: 18), onPressed: () => notifier.addItem(item.product), constraints: const BoxConstraints(), padding: const EdgeInsets.all(8)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}