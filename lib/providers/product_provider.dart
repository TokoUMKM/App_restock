// Lokasi: lib/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

// Dummy Data untuk simulasi berbagai kondisi stok
final List<Product> _dummyProducts = [
  Product(
      id: '1',
      name: 'Beras Pandan Wangi',
      currentStock: 3,
      daysRemaining: 1.5,
      status: StockStatus.danger // Simulasi barang kritis
      ),
  Product(
      id: '2',
      name: 'Minyak Goreng Sunco 2L',
      currentStock: 12,
      daysRemaining: 4.0,
      status: StockStatus.warning // Simulasi barang mulai menipis
      ),
  Product(
      id: '3',
      name: 'Indomie Goreng',
      currentStock: 45,
      daysRemaining: 15.0,
      status: StockStatus.safe // Simulasi aman
      ),
  Product(
      id: '4',
      name: 'Gula Pasir Gulaku',
      currentStock: 2,
      daysRemaining: 0.5,
      status: StockStatus.danger),
];

// Provider untuk disebar ke seluruh UI
final productListProvider = Provider<List<Product>>((ref) {
  return _dummyProducts;
});

// Provider khusus untuk menghitung jumlah notifikasi bahaya (Merah)
final dangerCountProvider = Provider<int>((ref) {
  final products = ref.watch(productListProvider);
  return products.where((p) => p.status == StockStatus.danger).length;
});
