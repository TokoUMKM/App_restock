import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart'; 

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _priceController = TextEditingController();

  // STATE UNTUK DROPDOWN SUPPLIER
  String? _selectedSupplierId;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Harga wajib diisi!")),
      );
      return;
    }

    // Optional: Paksa user pilih supplier
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Supplier dulu agar bisa restock otomatis!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newProduct = Product(
        sku: _skuController.text.isEmpty 
            ? "SKU-${DateTime.now().millisecondsSinceEpoch}"
            : _skuController.text,
        name: _nameController.text,
        currentStock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        price: int.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
        supplierId: _selectedSupplierId,
        unit: 'Pcs',
        category: 'Umum'
      );

      await ref.read(productListProvider.notifier).addProduct(newProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Barang berhasil disimpan!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. DENGARKAN DATA SUPPLIER (Langsung List<Supplier>)
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Barang Baru"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informasi Dasar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // SKU
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: "Kode SKU / Barcode",
                hintText: "Scan atau ketik manual",
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),

            // Nama Produk
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Nama Produk *",
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Harga
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Harga Jual (Rp) *",
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // --- PILIH SUPPLIER (DROPDOWN FIX) ---
            DropdownButtonFormField<String>(
              value: _selectedSupplierId,
              decoration: const InputDecoration(
                labelText: "Supplier (Penyedia Barang) *",
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
                helperText: "Penting untuk fitur auto-order WhatsApp",
              ),
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier.id,
                  child: Text(
                    supplier.name, 
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: suppliers.isEmpty 
                  ? null 
                  : (value) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                    },
              hint: suppliers.isEmpty 
                ? const Text("Belum ada data supplier...") 
                : const Text("Pilih Supplier"),
            ),
            
            const SizedBox(height: 32),

            // --- STOK ---
            const Text("Manajemen Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Stok Awal",
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      suffixText: "Unit",
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Batas Minimum",
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2962FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) 
              : const Text("SIMPAN PRODUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}