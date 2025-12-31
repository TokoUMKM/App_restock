import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- MODELS & PROVIDERS ---
import '../models/product.dart';
import '../providers/product_provider.dart';

// --- SCREENS ---
import 'add_product_screen.dart';
import 'edit_product_screen.dart'; 

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      
      // [SOLUSI 1] FloatingActionButton DIHAPUS agar tidak menumpuk
      // floatingActionButton: null, 

      body: CustomScrollView(
        slivers: [
          // --- HEADER & SEARCH ---
          SliverAppBar(
            pinned: true,
            title: const Text("Manajemen Stok"),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            
            // [SOLUSI 1] Tombol Tambah Barang Pindah ke Sini (Pojok Kanan Atas)
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                },
                tooltip: "Tambah Barang Baru",
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2962FF), size: 28),
              ),
              const SizedBox(width: 12), // Memberi sedikit jarak dari pinggir layar
            ],

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Cari produk...",
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF2962FF))),
                  ),
                  onChanged: (value) {
                    // TODO: Implementasi filter search local jika diperlukan
                  },
                ),
              ),
            ),
          ),

          // --- LIST DATA PRODUK ---
          products.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text("Belum ada barang", style: TextStyle(color: Colors.grey))),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildProductCard(context, product, ref);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
          
          // Padding bawah agar list paling bawah tidak tertutup navigasi
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- WIDGET KARTU PRODUK ---
  Widget _buildProductCard(BuildContext context, Product product, WidgetRef ref) {
    // 1. Logika Penentuan Status
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (product.currentStock <= product.minStock) {
      statusText = "Restock!";
      statusColor = const Color(0xFFD50000); 
      statusBgColor = const Color(0xFFFFEBEE);
    } else if (product.currentStock <= (product.minStock * 2)) {
      statusText = "Warning";
      statusColor = const Color(0xFFEF6C00); 
      statusBgColor = const Color(0xFFFFF3E0);
    } else {
      statusText = "Aman";
      statusColor = const Color(0xFF2E7D32); 
      statusBgColor = const Color(0xFFE8F5E9);
    }

    return Dismissible(
      key: Key(product.id.toString()),
      background: Container(
        color: Colors.red, 
        alignment: Alignment.centerRight, 
        padding: const EdgeInsets.only(right: 20), 
        child: const Icon(Icons.delete, color: Colors.white)
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Barang?"),
            content: Text("Yakin ingin menghapus ${product.name}?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (product.id != null) {
          ref.read(productListProvider.notifier).deleteProduct(product.id!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} dihapus")));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Barang
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 16),
              
              // Detail Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      "Stok: ${product.currentStock} ${product.unit}  |  Min: ${product.minStock}", 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                    ),
                  ],
                ),
              ),

              // Tombol Edit
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: "Edit Data",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));
                },
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2))
                ),
                child: Text(
                  statusText, 
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}