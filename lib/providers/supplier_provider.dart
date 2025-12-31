import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier_model.dart'; 
import '../services/supabase_services.dart';

// Class Notifier: Mengelola Logic (Tambah, Edit, Hapus)
class SupplierListNotifier extends StateNotifier<List<Supplier>> {
  final SupabaseService _service;

  SupplierListNotifier(this._service) : super([]) {
    loadSuppliers(); // Load data saat aplikasi jalan
  }

  // 1. LOAD DATA
  Future<void> loadSuppliers() async {
    try {
      final data = await _service.getSuppliers();
      state = data;
    } catch (e) {
      print("Error loading suppliers: $e");
    }
  }

  // 2. ADD SUPPLIER
  Future<void> addSupplier(String name, String phone) async {
    try {
      await _service.addSupplier(name, phone);
      await loadSuppliers(); // Reload dari DB untuk dapat ID baru
    } catch (e) {
      throw e;
    }
  }

  // 3. UPDATE SUPPLIER
  Future<void> updateSupplier(String id, String name, String phone) async {
    try {
      await _service.updateSupplier(id, name, phone);
      // Update lokal agar UI langsung berubah (Optimistic Update)
      state = [
        for (final s in state)
          if (s.id == id)
            Supplier(id: id, name: name, phoneNumber: phone)
          else
            s
      ];
    } catch (e) {
      throw e;
    }
  }

  // 4. DELETE SUPPLIER
  Future<void> deleteSupplier(String id) async {
    try {
      await _service.deleteSupplier(id);
      // Hapus lokal agar UI langsung berubah
      state = state.where((s) => s.id != id).toList();
    } catch (e) {
      await loadSuppliers(); // Fallback jika gagal
      throw e;
    }
  }
}

// DEFINISI PROVIDER (PENTING: Tipe StateNotifierProvider)
final supplierListProvider = StateNotifierProvider<SupplierListNotifier, List<Supplier>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return SupplierListNotifier(service);
});