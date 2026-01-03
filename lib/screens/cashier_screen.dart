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
  final currency =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER SNACKBAR ---
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ===========================================================================
  // 1. UI BUILD (RESPONSIVE)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productListProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Filter Pencarian
    final displayProducts = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Kasir",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_disabled_outlined,
                color: Colors.black54),
            tooltip: "Setting Printer",
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
          ),
          // Indikator Cart di AppBar
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.black87),
                tooltip: "Lihat Keranjang",
                onPressed: () => _showCartDetail(context),
              ),
              if (cartNotifier.totalItems > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text("${cartNotifier.totalItems}",
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
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
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                fillColor: Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: Color(0xFF2962FF), width: 1.5)),
              ),
            ),
          ),
        ),
      ),
      body: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KIRI: List Produk
                Expanded(flex: 3, child: _buildProductGrid(displayProducts, cartItems, cartNotifier)),
                // KANAN: Panel Pembayaran (Fixed side panel)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: _buildBottomPanel(cartNotifier, cartItems),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // ATAS: List Produk
                Expanded(child: _buildProductGrid(displayProducts, cartItems, cartNotifier)),
                // BAWAH: Panel Pembayaran
                _buildBottomPanel(cartNotifier, cartItems),
              ],
            ),
    );
  }

  // --- SUB WIDGET: PRODUCT GRID ---
  Widget _buildProductGrid(List<Product> products, List<CartItem> cartItems, CartNotifier notifier) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Barang tidak ditemukan",
                style: TextStyle(color: Colors.grey))
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.75, // Sedikit lebih pendek agar muat banyak
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final inCart = cartItems.firstWhere(
            (item) => item.product.id == p.id,
            orElse: () => CartItem(product: p, qty: 0));
        return _buildProductCard(p, inCart.qty, notifier);
      },
    );
  }

  // --- SUB WIDGET: BOTTOM PANEL ---
  Widget _buildBottomPanel(CartNotifier notifier, List<CartItem> cartItems) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -4))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  Text("${notifier.totalItems} Barang",
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(currency.format(notifier.totalPrice),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87))),
                  InkWell(
                    onTap: () => _showCartDetail(context),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text("Lihat Rincian",
                              style: TextStyle(
                                  color: Color(0xFF2962FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Icon(Icons.keyboard_arrow_up_rounded,
                              size: 16, color: Color(0xFF2962FF))
                        ],
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF2962FF).withOpacity(0.4)),
                  child: const Text("BAYAR",
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. LOGIC DIALOG & TRANSAKSI (SAFE ASYNC) ---
  
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
          height: 320,
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
                  Expanded(
                    child: _buildPaymentOption(
                      icon: Icons.money_rounded,
                      label: "Tunai",
                      color: const Color(0xFF2E7D32),
                      isActive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _processCashPayment();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPaymentOption(
                      icon: Icons.qr_code_2_rounded,
                      label: "QRIS\n(Coming Soon)",
                      color: Colors.grey,
                      isActive: false,
                      onTap: () => _showSnack("Fitur segera hadir.", isError: true),
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

  void _processCashPayment() {
    final total = ref.read(cartProvider.notifier).totalPrice;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Tunai"),
        content: Text("Terima pembayaran sebesar:\n${currency.format(total)}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeTransaction("Tunai");
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text("Terima & Cetak"),
          )
        ],
      ),
    );
  }

  Future<void> _finalizeTransaction(String paymentMethod) async {
    final cartItems = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currentContext = context; // Simpan context lokal

    if (cartItems.isEmpty) return;

    // Snapshot data sebelum clear cart
    final itemsToPrint = List<CartItem>.from(cartItems);
    final totalToPrint = cartNotifier.totalPrice;

    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    final shopName = meta['shop_name'] ?? "Toko Saya";
    final shopAddress = meta['shop_address'] ?? "";
    final shopPhone = meta['shop_phone'] ?? "";
    final ownerName = meta['full_name'] ?? "Kasir";

    try {
      showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));

      // A. Update DB
      for (var item in cartItems) {
        if (item.product.id != null) {
          await ref
              .read(productListProvider.notifier)
              .sellProduct(item.product.id!, item.qty);
        }
      }

      cartNotifier.clearCart();

      // Tutup Loading
      if (currentContext.mounted) Navigator.pop(currentContext);

      // B. Show Success Dialog
      if (currentContext.mounted) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                const SizedBox(height: 12),
                Text("Lunas via $paymentMethod",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ],
            ),
            content: Text(
                "Total: ${currency.format(totalToPrint)}\nPilih metode cetak:",
                textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup", style: TextStyle(color: Colors.grey))),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text("PDF"),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog dulu
                  _generatePdf(itemsToPrint, totalToPrint, ownerName, shopName, shopAddress, shopPhone, paymentMethod);
                },
              ),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text("Print"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white),
                onPressed: () {
                   Navigator.pop(ctx); // Tutup dialog dulu
                   _printThermal(itemsToPrint, totalToPrint, ownerName, shopName, shopAddress, shopPhone, paymentMethod);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (Navigator.canPop(currentContext)) Navigator.pop(currentContext);
        _showSnack("Gagal memproses: $e", isError: true);
      }
    }
  }

  // --- 3. BACKGROUND TASKS (PRINTING) ---
  
  Future<void> _generatePdf(List<CartItem> items, int total, String cashier, String shop, String address, String phone, String method) async {
    _showSnack("Menyiapkan PDF...");
    try {
      await PdfInvoiceService.printReceipt(
          items: items,
          total: total,
          cashierName: cashier,
          shopName: shop,
          shopAddress: address,
          shopPhone: phone,
          paymentMethod: method);
    } catch (e) {
      _showSnack("Gagal PDF: $e", isError: true);
    }
  }

  Future<void> _printThermal(List<CartItem> items, int total, String cashier, String shop, String address, String phone, String method) async {
    _showSnack("Mengirim ke Printer...");
    try {
      await ThermalPrinterService().printReceipt(
          items: items,
          total: total,
          shopName: shop,
          shopAddress: address,
          shopPhone: phone,
          cashierName: cashier,
          paymentMethod: method);
    } catch (e) {
      _showSnack("Info Printer: $e", isError: true); // Bukan error fatal, mungkin bluetooth mati
    }
  }

  // --- 4. WIDGET HELPERS (Extracted for readability) ---

  Widget _buildPaymentOption({required IconData icon, required String label, required Color color, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isActive ? color.withOpacity(0.1) : Colors.white, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product p, int qty, CartNotifier notifier) {
    bool isOutOfStock = p.currentStock <= 0;
    bool isSelected = qty > 0;
    bool isLowStock = !isOutOfStock && p.currentStock <= p.minStock;

    Color iconBg = isOutOfStock ? Colors.grey.shade100 : (isSelected ? const Color(0xFFE3F2FD) : (isLowStock ? const Color(0xFFFFF3E0) : const Color(0xFFF2FBF4)));
    Color iconCol = isOutOfStock ? Colors.grey.shade400 : (isSelected ? const Color(0xFF2962FF) : (isLowStock ? Colors.orange : Colors.green));

    return GestureDetector(
      onTap: isOutOfStock ? null : () => notifier.addItem(p),
      onLongPress: isOutOfStock ? null : () => notifier.decreaseItem(p.id!),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF2962FF) : Colors.transparent, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(color: iconBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(isOutOfStock ? Icons.block_rounded : Icons.inventory_2_rounded, size: 36, color: iconCol),
                    if (isSelected)
                      Positioned(top: 8, right: 8, child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Color(0xFF2962FF), shape: BoxShape.circle), alignment: Alignment.center, child: Text("$qty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))))
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isOutOfStock ? Colors.grey : Colors.black87)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currency.format(p.price), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isOutOfStock ? Colors.grey : const Color(0xFF2962FF))),
                        const SizedBox(height: 4),
                        Text(isOutOfStock ? "Habis" : "Sisa: ${p.currentStock}", style: TextStyle(fontSize: 11, color: isOutOfStock ? Colors.red : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(builder: (context, ref, _) {
        final items = ref.watch(cartProvider);
        final notifier = ref.read(cartProvider.notifier);
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Rincian Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))]),
              const Divider(),
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
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
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
      }),
    );
  }
}