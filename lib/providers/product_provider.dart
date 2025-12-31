import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/supabase_services.dart';

class ProductNotifier extends StateNotifier<List<Product>> {
  final SupabaseService _service;

  ProductNotifier(this._service) : super([]) {
    loadProducts();
  }

  // A. Load Produk (Read)
  Future<void> loadProducts() async {
    try {
      final products = await _service.getProducts();
      state = products;
    } catch (e) {
      // Jangan hanya di-print, lempar ke logging system jika ada
      print("Error loading products: $e");
    }
  }

  // B. Tambah Produk (Create)
  Future<void> addProduct(Product product) async {
    try {
      await _service.addProduct(product);
      // Refresh data agar History Transaksi 'IN' juga terhitung di laporan
      await loadProducts(); 
    } catch (e) {
      rethrow; 
    }
  }

  // C. Update Produk (Update)
  Future<void> updateProduct(Product product) async {
    try {
      await _service.updateProduct(product);
      // Optimasi: Update local state tanpa fetch ulang
      state = [
        for (final p in state)
          if (p.id == product.id) product else p
      ];
    } catch (e) {
      rethrow;
    }
  }

  // D. Hapus Produk (Delete)
  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      // Optimasi: Hapus dari local state langsung
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }

  // E. Jual Produk (Transaction)
  Future<void> sellProduct(String id, int qty) async {
    try {
      // Panggil RPC sell_product yang sudah kita buat di Supabase
      await _service.sellProduct(id, qty);
      
      // Update stok lokal segera untuk UX yang instan
      state = [
        for (final p in state)
          if (p.id == id)
            Product(
              id: p.id,
              sku: p.sku,
              name: p.name,
              currentStock: p.currentStock - qty, // Kurangi stok secara lokal
              minStock: p.minStock,
              price: p.price,
              userId: p.userId,
              supplierId: p.supplierId,
            )
          else
            p
      ];
    } catch (e) {
      rethrow;
    }
  }
}

// Provider Global
final productListProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return ProductNotifier(service);
});