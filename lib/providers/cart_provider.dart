import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// Model Item Keranjang
class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});
}

// Logic Keranjang (Tambah, Kurang, Hapus, Hitung Total)
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // 1. Tambah ke Keranjang
  void addItem(Product product) {
    // Cek stok dulu
    if (product.currentStock <= 0) return;

    // Cek apakah barang sudah ada di keranjang?
    final index = state.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // Jika ada, tambah qty (tapi jangan melebihi stok fisik)
      if (state[index].qty < product.currentStock) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) 
              CartItem(product: state[i].product, qty: state[i].qty + 1)
            else 
              state[i]
        ];
      }
    } else {
      // Jika belum ada, masukkan baru
      state = [...state, CartItem(product: product)];
    }
  }

  // 2. Kurangi Qty
  void decreaseItem(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    if (state[index].qty > 1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) 
            CartItem(product: state[i].product, qty: state[i].qty - 1)
          else 
            state[i]
      ];
    } else {
      // Jika sisa 1 dikurang, hapus item
      removeItem(productId);
    }
  }

  // 3. Hapus Item
  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  // 4. Bersihkan Keranjang (Setelah bayar)
  void clearCart() {
    state = [];
  }

  // 5. Hitung Total Harga
  int get totalPrice => state.fold(0, (sum, item) => sum + (item.product.price * item.qty));
  
  // 6. Hitung Total Item
  int get totalItems => state.fold(0, (sum, item) => sum + item.qty);
}

// Provider Global
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});