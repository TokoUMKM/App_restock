import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';

class SupplierScreen extends ConsumerWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Daftar Supplier",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          barrierDismissible: false, // Mencegah tutup tidak sengaja
          builder: (context) => const SupplierDialog(), // Dialog dipisah jadi Widget
        ),
        backgroundColor: const Color(0xFF2962FF),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: suppliers.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return SupplierListItem(
                  key: ValueKey(supplier.id), // Safety Key
                  supplier: supplier,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 64, color: Colors.blueGrey.shade200),
          ),
          const SizedBox(height: 16),
          Text("Belum ada supplier",
              style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// --- 1. WIDGET ITEM TERPISAH (Performance) ---
class SupplierListItem extends ConsumerWidget {
  final Supplier supplier;

  const SupplierListItem({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE3F2FD),
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : "?",
            style: const TextStyle(
                color: Color(0xFF2962FF), fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Text(supplier.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(supplier.phoneNumber,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Edit",
              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SupplierDialog(supplier: supplier),
              ),
            ),
            IconButton(
              tooltip: "Hapus",
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 22),
              onPressed: () => _confirmDelete(context, ref, supplier),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Supplier?", style: TextStyle(color: Colors.red)),
        content: Text("Yakin ingin menghapus '${supplier.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup konfirmasi dulu
              try {
                await ref
                    .read(supplierListProvider.notifier)
                    .deleteSupplier(supplier.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Supplier berhasil dihapus")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Gagal: $e")));
                }
              }
            },
            child: const Text("Hapus",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- 2. DIALOG STATEFUL (Untuk Loading State) ---
class SupplierDialog extends ConsumerStatefulWidget {
  final Supplier? supplier; // Null = Add, Not Null = Edit

  const SupplierDialog({super.key, this.supplier});

  @override
  ConsumerState<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends ConsumerState<SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? "");
    _phoneController =
        TextEditingController(text: widget.supplier?.phoneNumber ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // Mulai Loading

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (widget.supplier != null) {
        // UPDATE
        await ref
            .read(supplierListProvider.notifier)
            .updateSupplier(widget.supplier!.id, name, phone);
      } else {
        // ADD
        await ref.read(supplierListProvider.notifier).addSupplier(name, phone);
      }

      if (mounted) {
        Navigator.pop(context); // Tutup dialog jika SUKSES
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.supplier != null
              ? "Data diperbarui"
              : "Supplier ditambahkan"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); // Stop Loading jika GAGAL
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEdit ? "Edit Supplier" : "Tambah Supplier",
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView( // Agar tidak overflow keyboard
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Nama Supplier",
                  prefixIcon: const Icon(Icons.business_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Nomor WhatsApp",
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // Validasi Nomor HP Sederhana
                validator: (val) {
                  if (val == null || val.isEmpty) return "Nomor wajib diisi";
                  if (val.length < 9) return "Nomor tidak valid";
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Batal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2962FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Simpan"),
        ),
      ],
    );
  }
}