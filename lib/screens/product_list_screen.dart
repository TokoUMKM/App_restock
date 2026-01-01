import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart'; 

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
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
    
    // Filter Search
    final products = allProducts.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        slivers: [
          // --- HEADER SIMPEL & MODERN ---
          SliverAppBar(
            pinned: true, 
            floating: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Manajemen Stok",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
               IconButton(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                 },
                 icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2962FF), size: 28),
                 tooltip: "Tambah Barang",
               ),
               const SizedBox(width: 12),
            ],
            
            // --- SEARCH BAR ---
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Cari barang...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          }) 
                      : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    fillColor: const Color(0xFFF4F7FC),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1)),
                  ),
                ),
              ),
            ),
          ),

          // --- LIST PRODUK ---
          products.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? "Belum ada barang" : "Tidak ditemukan", 
                          style: TextStyle(color: Colors.grey.shade500)
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  // FIX PADDING: Bawah 100 agar tidak tertutup BottomBar
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildSimpleProductCard(context, product, ref);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // Desain Kartu dengan Alert Dialog Seragam Profil
  Widget _buildSimpleProductCard(BuildContext context, Product product, WidgetRef ref) {
    // Logika Warna Status
    Color statusColor;
    String statusText;
    
    if (product.currentStock <= 0) {
      statusColor = const Color(0xFFFF3B30); // Merah
      statusText = "Habis";
    } else if (product.currentStock <= product.minStock) {
      statusColor = const Color(0xFFFF9500); // Orange
      statusText = "Restock";
    } else {
      statusColor = const Color(0xFF34C759); // Hijau
      statusText = "Aman";
    }

    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Dismissible(
      key: Key(product.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)), // Radius samakan dengan card
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // --- LOGIKA ALERT DIALOG DIPERBARUI ---
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            // Style Shape: Rounded 20 (Sama seperti Profil)
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            // Style Title: Merah & Bold (Konsisten untuk aksi bahaya)
            title: const Text("Hapus Barang?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text("Barang '${product.name}' akan dihapus permanen.", style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("HAPUS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (product.id != null) ref.read(productListProvider.notifier).deleteProduct(product.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.inventory_2_outlined, color: Colors.blueGrey.shade400),
                  ),
                  const SizedBox(width: 16),
                  
                  // Info Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("${product.currentStock} ${product.unit}  •  ${currency.format(product.price)}", 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}