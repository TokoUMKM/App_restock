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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productListProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // LOGIKA FILTER PENCARIAN
    final displayProducts = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    // --- LOGIC BAYAR ---
    Future<void> processPayment() async {
      if (cartItems.isEmpty) return;

      // 1. Snapshot Data untuk Struk
      final itemsToPrint = List<CartItem>.from(cartItems);
      final totalToPrint = cartNotifier.totalPrice;

      // 2. Ambil Data Toko (Metadata Supabase)
      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata ?? {};
      
      final shopName = meta['shop_name'] ?? "Toko Saya";
      final shopAddress = meta['shop_address'] ?? "";
      final shopPhone = meta['shop_phone'] ?? "";
      final ownerName = meta['full_name'] ?? "Admin";

      try {
        // Kurangi Stok
        for (var item in cartItems) {
          if (item.product.id != null) {
            await ref.read(productListProvider.notifier).sellProduct(item.product.id!, item.qty);
          }
        }

        cartNotifier.clearCart();

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 50), SizedBox(height: 10), Text("Transaksi Sukses")]),
              content: const Text("Stok diperbarui. Pilih metode cetak:", textAlign: TextAlign.center),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowButtonSpacing: 8, 
              actions: [
                // 1. TOMBOL TUTUP
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("Tutup", style: TextStyle(color: Colors.grey))
                ),
                
                // 2. TOMBOL PDF (SHARE WA)
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18), 
                  label: const Text("PDF / Share"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    PdfInvoiceService.printReceipt(
                      items: itemsToPrint, 
                      total: totalToPrint, 
                      cashierName: ownerName, 
                      shopName: shopName,
                      shopAddress: shopAddress,
                      shopPhone: shopPhone
                    );
                  },
                ),

                // 3. TOMBOL THERMAL (CETAK KERTAS)
                ElevatedButton.icon(
                  icon: const Icon(Icons.print, size: 18), 
                  label: const Text("Cetak Thermal"),
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
                        cashierName: ownerName
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Info: $e")));
                      // Buka halaman setting printer jika error/belum connect
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()));
                    }
                  },
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Kasir", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_disabled_outlined, color: Colors.black54),
            tooltip: "Setting Printer",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Reset Keranjang",
            onPressed: () => cartNotifier.clearCart(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari nama barang...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    }) 
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. GRID PRODUK
          Expanded(
            child: displayProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("Barang tidak ditemukan", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160, 
                      childAspectRatio: 0.75, 
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      final p = displayProducts[index];
                      final inCart = cartItems.firstWhere(
                        (item) => item.product.id == p.id, 
                        orElse: () => CartItem(product: p, qty: 0)
                      );
                      return _buildProductCard(p, inCart.qty, cartNotifier, currency);
                    },
                  ),
          ),

          // 2. PANEL BAWAH (MODIFIED FOR SCAN BUTTON)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // PENTING: Pisahkan kiri dan kanan
                children: [
                  
                  // --- KIRI: INFO HARGA ---
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${cartNotifier.totalItems} Barang", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currency.format(cartNotifier.totalPrice),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showCartDetail(context, ref, currency),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text("Lihat Rincian >", style: TextStyle(color: Color(0xFF2962FF), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- TENGAH: GAP UNTUK TOMBOL SCAN ---
                  // Memberi jarak 74px agar tombol Scan (70px) tidak menabrak UI
                  const SizedBox(width: 74), 

                  // --- KANAN: TOMBOL BAYAR ---
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty ? null : processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("BAYAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  // WIDGET KARTU
  Widget _buildProductCard(Product p, int qty, CartNotifier notifier, NumberFormat currency) {
    bool isOutOfStock = p.currentStock <= 0;
    bool isSelected = qty > 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : () => notifier.addItem(p),
      onLongPress: isOutOfStock ? null : () => notifier.decreaseItem(p.id!), 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2962FF) : Colors.grey.shade200, 
            width: isSelected ? 2 : 1
          ),
          boxShadow: [
            if (!isOutOfStock) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.grey.shade100 : (isSelected ? Colors.blue.shade50 : Colors.grey.shade50),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Center(
                      child: Icon(
                        isOutOfStock ? Icons.block : Icons.inventory_2_outlined,
                        size: 32,
                        color: isOutOfStock ? Colors.grey : (isSelected ? const Color(0xFF2962FF) : Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8, right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF2962FF),
                        child: Text("$qty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                ],
              ),
            ),
            
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
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
                        color: isOutOfStock ? Colors.grey : Colors.black87,
                        height: 1.2
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(p.price),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOutOfStock ? Colors.grey : const Color(0xFF2962FF)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Stok: ${p.currentStock}",
                          style: TextStyle(fontSize: 10, color: isOutOfStock ? Colors.red : Colors.grey.shade600),
                        ),
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

  // BOTTOM SHEET DETAIL
  void _showCartDetail(BuildContext context, WidgetRef ref, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final items = ref.watch(cartProvider);
          final notifier = ref.read(cartProvider.notifier);
          
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Rincian Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
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
                            subtitle: Text(currency.format(item.product.price * item.qty), style: const TextStyle(color: Colors.blue)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16), 
                                    onPressed: () => notifier.decreaseItem(item.product.id!),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16), 
                                    onPressed: () => notifier.addItem(item.product),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
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