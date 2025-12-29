import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;

  // 1. Handling Permission (Android/iOS)
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    return statuses[Permission.camera]!.isGranted;
  }

  // 2. Modul Kamera (Initialize)
  Future<CameraController?> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium, // Medium cukup untuk OCR Gemini agar hemat bandwidth
      enableAudio: false,
    );

    await _controller!.initialize();
    return _controller;
  }

  // 3. Ambil & Compress Image max 1MB
  Future<File?> captureAndCompress() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    // Ambil gambar original
    final XFile rawImage = await _controller!.takePicture();
    final File imageFile = File(rawImage.path);

    // Baca image untuk diproses
    img.Image? decodedImage = img.decodeImage(await imageFile.readAsBytes());
    if (decodedImage == null) return null;

    // Kompresi kualitas ke 80%
    List<int> compressedBytes = img.encodeJpg(decodedImage, quality: 80);

    // (Resize)
    if (compressedBytes.length > 1000000) {
      decodedImage = img.copyResize(decodedImage, width: 1024);
      compressedBytes = img.encodeJpg(decodedImage, quality: 70);
    }

    // Simpan ke temporary directory
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/receipt_processed.jpg');
    return await compressedFile.writeAsBytes(compressedBytes);
  }

  void dispose() {
    _controller?.dispose();
  }
}