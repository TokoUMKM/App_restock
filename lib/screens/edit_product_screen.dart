import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart'; 

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product; // Data produk yang mau diedit

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _priceController;

  String? _selectedSupplierId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Isi form dengan data lama (Pre-fill)
    _skuController = TextEditingController(text: widget.product.sku);
    _nameController = TextEditingController(text: widget.product.name);
    _stockController = TextEditingController(text: widget.product.currentStock.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
    _priceController = TextEditingController(text: widget.product.price.toString());
    
    // 2. Set Supplier Lama (Jika ada)
    _selectedSupplierId = widget.product.supplierId;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama dan Harga wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Buat object Product baru dengan ID yang SAMA (PENTING)
      final updatedProduct = Product(
        id: widget.product.id, // ID tidak boleh berubah
        sku: _skuController.text,
        name: _nameController.text,
        currentStock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        price: int.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
        supplierId: _selectedSupplierId, // Supplier yang baru dipilih (atau lama)
        unit: widget.product.unit, // Pertahankan unit lama jika tidak diedit
        category: widget.product.category, 
        description: widget.product.description,
        userId: widget.product.userId,
      );

      // 4. Panggil Provider Update
      await ref.read(productListProvider.notifier).updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk berhasil diperbarui!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Produk"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Detail Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: "SKU / Barcode", prefixIcon: Icon(Icons.qr_code), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Produk", prefixIcon: Icon(Icons.label_outline), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Harga Jual (Rp)", prefixIcon: Icon(Icons.monetization_on_outlined), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // --- DROPDOWN SUPPLIER (PENTING UNTUK MELENGKAPI DATA) ---
            DropdownButtonFormField<String>(
              value: _selectedSupplierId, // Akan otomatis memilih supplier lama jika ID cocok
              decoration: const InputDecoration(
                labelText: "Supplier",
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
                helperText: "Ganti supplier jika data kosong/salah",
              ),
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier.id,
                  child: Text(supplier.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSupplierId = value),
              hint: const Text("Pilih Supplier"),
            ),
            
            const SizedBox(height: 24),
            const Text("Aturan Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Stok Sekarang", prefixIcon: Icon(Icons.inventory_2_outlined), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Min. Stok", prefixIcon: Icon(Icons.warning_amber_rounded), border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}