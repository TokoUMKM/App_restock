import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart'; 

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product; 

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
    
    // 2. Set Supplier Lama
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
      final updatedProduct = Product(
        id: widget.product.id, // ID Tetap
        sku: _skuController.text,
        name: _nameController.text,
        currentStock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        price: int.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
        supplierId: _selectedSupplierId, 
        unit: widget.product.unit, 
        category: widget.product.category, 
        description: widget.product.description,
        userId: widget.product.userId,
      );

      await ref.read(productListProvider.notifier).updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk berhasil diperbarui!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
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
      backgroundColor: const Color(0xFFF4F7FC), // Background Abu-Biru Modern
      appBar: AppBar(
        title: const Text("Edit Produk", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- KARTU 1: INFORMASI UTAMA ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Dasar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  
                  _buildModernTextField(
                    controller: _skuController,
                    label: "SKU / Barcode",
                    icon: Icons.qr_code_2_rounded,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildModernTextField(
                    controller: _nameController,
                    label: "Nama Produk",
                    icon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 16),

                  _buildModernTextField(
                    controller: _priceController,
                    label: "Harga Jual (Rp)",
                    icon: Icons.monetization_on_outlined,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- KARTU 2: STOK & SUPPLIER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Stok & Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _stockController,
                          label: "Stok Saat Ini",
                          icon: Icons.inventory_2_outlined,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _minStockController,
                          label: "Min. Stok",
                          icon: Icons.warning_amber_rounded,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // DROPDOWN MODERN
                  DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    isExpanded: true, // PENTING: Mencegah Overflow Text
                    decoration: InputDecoration(
                      labelText: "Supplier",
                      prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: suppliers.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier.id,
                        child: Text(
                          supplier.name, 
                          overflow: TextOverflow.ellipsis, // PENTING: Potong teks panjang
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSupplierId = value),
                    hint: const Text("Pilih Supplier"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFF2962FF).withOpacity(0.4),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                  : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30), // Padding bawah aman
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER TEXTFIELD ---
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool isCurrency = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isCurrency ? const Color(0xFF2962FF) : Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5)),
      ),
    );
  }
}