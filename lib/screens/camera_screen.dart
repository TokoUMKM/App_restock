import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Service & Model
import '../services/camera_service.dart';
import '../services/ai_services.dart'; 
import '../services/supabase_services.dart';
import '../models/product.dart';
import 'preview_screen.dart'; 

// Providers
final cameraServiceProvider = Provider((ref) => CameraService());
final aiServiceProvider = Provider((ref) => AIService());
final supabaseServiceProviders = Provider((ref) => SupabaseService()); 

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  
  // State Flash
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(cameraServiceProvider).dispose(); // Pakai service dispose
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ref.read(cameraServiceProvider).dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameraService = ref.read(cameraServiceProvider);
    
    // 1. Cek Permission
    final hasPermission = await cameraService.requestPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin kamera ditolak.")),
      );
      Navigator.pop(context);
      return;
    }

    // 2. Init
    final controller = await cameraService.initializeCamera();
    if (controller != null && mounted) {
      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
      });
    }
  }

  // --- LOGIC FLASH ---
  void _toggleFlash() {
    FlashMode nextMode;
    if (_currentFlashMode == FlashMode.off) {
      nextMode = FlashMode.torch; // Senter
    } else if (_currentFlashMode == FlashMode.torch) {
      nextMode = FlashMode.auto;
    } else {
      nextMode = FlashMode.off;
    }

    ref.read(cameraServiceProvider).setFlashMode(nextMode);
    setState(() => _currentFlashMode = nextMode);
  }

  // --- LOGIC FLOW ---
  Future<void> _processFlow() async {
    if (_isAnalyzing) return; 

    try {
      // 1. Capture
      final File? rawFile = await ref.read(cameraServiceProvider).capturePhoto();
      if (rawFile == null) return;
      if (!mounted) return;

      // 2. Navigasi ke Preview (Opsional - Jika ingin langsung crop, hapus blok ini)
      // Pastikan PreviewScreen mengembalikan true jika user setuju
      final bool? proceed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PreviewScreen(imagePath: rawFile.path)),
      );
      if (proceed != true) return; 

      // 3. Crop
      setState(() => _isAnalyzing = true);
      final File? croppedFile = await ref.read(cameraServiceProvider).cropImage(rawFile);
      
      if (croppedFile == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // 4. AI Analyze
      final result = await ref.read(aiServiceProvider).analyzeReceipt(croppedFile);

      if (!mounted) return;

      if (result.success && result.data != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ReceiptReviewSheet(data: result.data!, imageFile: croppedFile),
        );
      } else {
        throw result.error ?? "AI gagal membaca struk.";
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Kamera
          SizedBox.expand(child: CameraPreview(_controller!)),
          
          // 2. Overlay Hitam Transparan
          _buildScannerOverlay(),

          // 3. Header Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        _currentFlashMode == FlashMode.off 
                           ? Icons.flash_off 
                           : (_currentFlashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_auto),
                        color: _currentFlashMode == FlashMode.off ? Colors.white : Colors.yellow,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Text Instruksi
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0, right: 0,
            child: const Center(
              child: Text(
                "Posisikan struk di dalam kotak",
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // 5. Tombol Shutter
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: GestureDetector(
                onTap: _processFlow,
                child: Container(
                  width: 85, height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white24,
                  ),
                  child: Center(
                    child: Container(
                      width: 65, height: 65,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 6. Loading
          if (_isAnalyzing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
      child: Stack(
        children: [
          Container(decoration: const BoxDecoration(color: Colors.transparent)),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2962FF), strokeWidth: 5),
            const SizedBox(height: 25),
            const Text("Sedang Menganalisa Struk...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("AI sedang mengekstrak data barang", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHEET REVIEW HASIL SCAN (Logic Database)
// =============================================================================

class ReceiptReviewSheet extends ConsumerStatefulWidget {
  final ReceiptData data;
  final File imageFile;

  const ReceiptReviewSheet({super.key, required this.data, required this.imageFile});

  @override
  ConsumerState<ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends ConsumerState<ReceiptReviewSheet> {
  bool _isSaving = false;
  late List<ReceiptItem> _editableItems;
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editableItems = List.from(widget.data.items);
    if (widget.data.supplierName != null) {
      _supplierNameController.text = widget.data.supplierName!;
    }
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    super.dispose();
  }

  void _editItem(int index) {
    final item = _editableItems[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final qtyCtrl = TextEditingController(text: item.qty.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Koreksi Data"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Barang")),
            Row(children: [
              Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Harga"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty"))),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _editableItems[index] = ReceiptItem(
                  name: nameCtrl.text,
                  price: int.tryParse(priceCtrl.text) ?? 0,
                  qty: int.tryParse(qtyCtrl.text) ?? 0,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  String _generateSKU() {
    var rng = Random();
    return 'STK-${rng.nextInt(9000) + 1000}';
  }

  Future<void> _saveToDatabase() async {
    if (_editableItems.isEmpty) return;
    setState(() => _isSaving = true);
    
    final supplierName = _supplierNameController.text.trim();
    final supplierPhone = _supplierPhoneController.text.trim();

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      String? finalSupplierId;

      // 1. Handle Supplier
      if (supplierPhone.isNotEmpty) {
        final existingSupplier = await supabaseService.getSupplierByPhone(supplierPhone);
        if (existingSupplier != null) {
          finalSupplierId = existingSupplier.id;
        } else {
          final nameToSave = supplierName.isEmpty ? "Supplier Baru" : supplierName;
          finalSupplierId = await supabaseService.addSupplierAndGetId(nameToSave, supplierPhone);
        }
      }

      // 2. Handle Produk
      int newCount = 0;
      int updatedCount = 0;

      for (var item in _editableItems) {
        final existingProduct = await supabaseService.findProductByName(item.name);

        if (existingProduct != null && existingProduct.id != null) {
          // Update Stok
          await supabaseService.restockProduct(existingProduct.id!, existingProduct.currentStock, item.qty);
          updatedCount++;
        } else {
          // Buat Produk Baru
          final newProduct = Product(
            name: item.name,
            sku: _generateSKU(),
            currentStock: item.qty,
            minStock: 5,
            unit: 'Pcs',
            supplierId: finalSupplierId,
            description: "Scan dari: ${widget.data.supplierName ?? 'Struk'}",
            price: (item.price * 1.2).toInt(),
            category: 'Umum',
          );
          await supabaseService.addProduct(newProduct);
          newCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup Sheet
      Navigator.pop(context); // Tutup Camera Screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil! $newCount barang baru, $updatedCount stok diupdate."),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          const Text("Review Hasil Deteksi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Ketuk untuk edit, geser untuk hapus", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Divider(height: 32),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSupplierForm(),
                const SizedBox(height: 20),
                
                ...List.generate(_editableItems.length, (index) {
                  final item = _editableItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildItemCard(index, item),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              top: 10
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text("Batal"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveToDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Simpan Stok"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, ReceiptItem item) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      onDismissed: (_) => setState(() => _editableItems.removeAt(index)),
      child: InkWell(
        onTap: () => _editItem(index),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Modal: Rp ${item.price}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("x${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.blue.shade100)
      ),
      child: Column(
        children: [
          TextField(
            controller: _supplierNameController,
            decoration: const InputDecoration(labelText: "Nama Supplier", isDense: true, prefixIcon: Icon(Icons.storefront, size: 20), border: InputBorder.none),
          ),
          const Divider(),
          TextField(
            controller: _supplierPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: "No. WA Supplier", isDense: true, prefixIcon: Icon(Icons.phone_android, size: 20), border: InputBorder.none),
          ),
        ],
      ),
    );
  }
}