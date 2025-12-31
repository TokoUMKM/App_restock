import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart'; // [PENTING] Import provider supplier
import '../services/whatsapp_service.dart'; 
import '../models/product.dart';
import '../models/supplier_model.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  // LOGIKA GROUPING (Tetap Group by ID agar unik)
  Map<String, List<Product>> _groupBySupplierId(List<Product> products) {
    final Map<String, List<Product>> grouped = {};
    
    for (var p in products) {
      // Kunci Default
      String supplierKey = "unknown"; 
      
      if (p.supplierId != null && p.supplierId!.isNotEmpty) {
        supplierKey = p.supplierId!; 
      }
      
      if (!grouped.containsKey(supplierKey)) {
        grouped[supplierKey] = [];
      }
      grouped[supplierKey]!.add(p);
    }
    return grouped;
  }

  // [BARU] Helper untuk mencari Nama Supplier dari List Supplier
  String _getSupplierName(String supplierId, List<Supplier> suppliers) {
    if (supplierId == "unknown") return "Tanpa Supplier";
    
    // Cari supplier yang ID-nya cocok
    final found = suppliers.firstWhere(
      (s) => s.id == supplierId,
      orElse: () => Supplier(id: "", name: "Supplier Tidak Dikenal", phoneNumber: ""),
    );
    
    return found.name;
  }

  // [BARU] Helper untuk mencari No HP Supplier (Untuk tombol WA)
  String _getSupplierPhone(String supplierId, List<Supplier> suppliers) {
    if (supplierId == "unknown") return "";
    
    final found = suppliers.firstWhere(
      (s) => s.id == supplierId,
      orElse: () => Supplier(id: "", name: "", phoneNumber: ""),
    );
    
    return found.phoneNumber;
  }

  Future<void> _orderPerSupplier(String supplierPhone, List<Product> items) async {
    if (supplierPhone.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Halo, saya mau restock barang berikut:");
    buffer.writeln("");
    
    for (var p in items) {
      int orderQty = (p.minStock * 2) - p.currentStock;
      if (orderQty < 1) orderQty = 5; 
      buffer.writeln("- ${p.name} (${orderQty} ${p.unit})");
    }
    
    buffer.writeln("");
    buffer.writeln("Mohon info total harga & ketersediaan. Terima kasih.");

    await WhatsAppLauncher.sendOrder(supplierPhone, buffer.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final suppliers = ref.watch(supplierListProvider); // [BARU] Ambil data supplier
    
    // Filter barang kritis
    final dangerList = products.where((p) => p.currentStock <= p.minStock).toList();
    
    // Grouping data berdasarkan ID Supplier
    final groupedData = _groupBySupplierId(dangerList);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Analisis Belanja", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER SUMMARY
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.priority_high_rounded, color: Colors.red.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Barang Kritis", style: TextStyle(color: Colors.grey)),
                      Text("${dangerList.length} Item", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("Daftar Belanja (Per Supplier)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            if (dangerList.isEmpty)
              _buildEmptyState()
            else
              // Render List
              ...groupedData.entries.map((entry) {
                final String supplierId = entry.key;
                final List<Product> items = entry.value;
                
                // [FIX] Ubah ID menjadi Nama & No HP Asli
                final String realName = _getSupplierName(supplierId, suppliers);
                final String realPhone = _getSupplierPhone(supplierId, suppliers);

                return _buildOrderCard(realName, realPhone, items);
              }),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String supplierName, String supplierPhone, List<Product> items) {
    bool isUnknown = supplierName == "Tanpa Supplier" || supplierName == "Supplier Tidak Dikenal";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // CARD HEADER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.store, color: isUnknown ? Colors.grey : const Color(0xFF2962FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName, // Sekarang menampilkan Nama, bukan ID
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text("${items.length} Barang perlu dibeli", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (!isUnknown && supplierPhone.isNotEmpty)
                  IconButton(
                    onPressed: () => _orderPerSupplier(supplierPhone, items),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFE8F5E9)),
                    icon: const Icon(Icons.send, color: Color(0xFF2E7D32), size: 20),
                    tooltip: "Kirim Order WA",
                  )
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 0.5),

          // LIST BARANG
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (ctx, i) {
              final p = items[i];
              int orderQty = (p.minStock * 2) - p.currentStock;
              if (orderQty < 1) orderQty = 5;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.circle, size: 8, color: Colors.red),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  "$orderQty ${p.unit}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                ),
              );
            },
          ),
          
          // FOOTER (Jika unknown)
          if (isUnknown)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))
              ),
              child: const Text(
                "Lengkapi data supplier di menu Edit Produk agar bisa order otomatis.",
                style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                textAlign: TextAlign.center,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("Stok Aman Terkendali", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}