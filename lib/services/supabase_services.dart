import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/supplier_model.dart'; // Pastikan nama file model sesuai

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ========================================================================
  // 1. MODULE: PRODUCTS
  // ========================================================================

  Future<List<Product>> getProducts() async {
    final response = await _client
        .from('products')
        .select()
        .order('name', ascending: true);
    
    return (response as List).map((json) => Product.fromMap(json)).toList();
  }

  Future<void> addProduct(Product product) async {
    final user = _client.auth.currentUser;
    if (user == null) throw "Sesi berakhir, silakan login ulang.";

    final data = product.toMap();
    data['user_id'] = user.id; 
    if (data['id'] == null) data.remove('id'); 
    
    final response = await _client.from('products').insert(data).select().single();
    
    if (product.currentStock > 0) {
      await _client.from('transactions').insert({
        'product_id': response['id'],
        'user_id': user.id,
        'type': 'IN',
        'qty': product.currentStock,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) throw "ID Produk tidak ditemukan";
    await _client.from('products').update(product.toMap()).eq('id', product.id!);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<void> sellProduct(String productId, int qty) async {
    await _client.rpc('sell_product', params: {
      'p_id': productId,
      'qty_sold': qty,
    });
  }

  // ========================================================================
  // 2. MODULE: SUPPLIERS (FIXED LOGIC)
  // ========================================================================

  Future<List<Supplier>> getSuppliers() async {
    final response = await _client
        .from('suppliers')
        .select()
        .order('name', ascending: true);
    
    return (response as List).map((json) => Supplier.fromMap(json)).toList();
  }

  Future<void> addSupplier(String name, String phone) async {
    final user = _client.auth.currentUser;
    await _client.from('suppliers').insert({
      'name': name,
      'phone_number': phone,
      'user_id': user?.id,
    });
  }

  // [BARU] Tambah Supplier & Langsung Kembalikan ID (Penting untuk Scan Struk)
  Future<String> addSupplierAndGetId(String name, String phone) async {
    final user = _client.auth.currentUser;
    
    final response = await _client.from('suppliers').insert({
      'name': name,
      'phone_number': phone,
      'user_id': user?.id,
    }).select().single();
    
    return response['id'].toString();
  }

  // [BARU] Cari Supplier by Phone (Cek Duplikat)
  Future<Supplier?> getSupplierByPhone(String phone) async {
    final response = await _client
        .from('suppliers')
        .select()
        .eq('phone_number', phone)
        .maybeSingle(); 
    
    if (response == null) return null;
    return Supplier.fromMap(response);
  }

  Future<void> updateSupplier(String id, String name, String phone) async {
    await _client.from('suppliers').update({
      'name': name,
      'phone_number': phone, 
    }).eq('id', id);
  }
  Future<void> deleteSupplier(String id) async {
    await _client
        .from('products')
        .update({'supplier_id': null}) 
        .eq('supplier_id', id);
    await _client.from('suppliers').delete().eq('id', id);
  }

  // ========================================================================
  // 3. MODULE: SMART SCAN HELPER
  // ========================================================================

  Future<Product?> findProductByName(String productName) async {
    final response = await _client
        .from('products')
        .select()
        .ilike('name', productName) 
        .maybeSingle(); 

    if (response == null) return null;
    return Product.fromMap(response);
  }

  Future<void> restockProduct(String productId, int currentStock, int quantityToAdd) async {
    final user = _client.auth.currentUser;
    
    await _client.from('products').update({
      'current_stock': currentStock + quantityToAdd,
    }).eq('id', productId);

    await _client.from('transactions').insert({
      'product_id': productId,
      'user_id': user?.id,
      'type': 'IN',
      'qty': quantityToAdd,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ========================================================================
  // 4. MODULE: REPORTING & PROFILE
  // ========================================================================

  Future<List<Map<String, dynamic>>> getTransactionReport() async {
    final response = await _client.rpc('get_transaction_report');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAssetReport() async {
    final response = await _client.rpc('get_asset_report');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getWeeklySales() async {
    try {
      final response = await _client.rpc('get_weekly_sales');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw "Gagal memuat grafik: $e";
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await _client.from('profiles').select().eq('id', user.id).maybeSingle();
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());