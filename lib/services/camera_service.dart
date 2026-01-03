import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;

  // 1. Handling Permission
  // HANYA minta Camera. Storage tidak perlu untuk cache di Android 13+
  Future<bool> requestPermissions() async {
    var status = await Permission.camera.request();
    return status.isGranted;
  }

  // 2. Initialize Camera
  Future<CameraController?> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    _controller = CameraController(
      cameras.first, // Kamera Belakang
      ResolutionPreset.high, // Resolusi tinggi untuk OCR
      enableAudio: false, // Hemat resource & izin mic
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.jpeg 
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setFlashMode(FlashMode.off); // Default Mati
    } catch (e) {
      debugPrint("Camera Init Error: $e");
      return null;
    }
    
    return _controller;
  }

  // 3. Kontrol Flash (Dipanggil dari UI)
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFlashMode(mode);
      } catch (e) {
        debugPrint("Flash Error: $e");
      }
    }
  }

  // 4. Ambil Foto
  Future<File?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    try {
      final XFile rawImage = await _controller!.takePicture();
      return File(rawImage.path);
    } catch (e) {
      debugPrint("Capture Error: $e");
      return null;
    }
  }

  // 5. Crop Image 
  Future<File?> cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressQuality: 85, // Optimasi ukuran file
      compressFormat: ImageCompressFormat.jpg,

      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Potong Struk',
            toolbarColor: const Color(0xFF2962FF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
        ),
        IOSUiSettings(
          title: 'Potong Struk',
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  // 6. Dispose
  void dispose() {
    _controller?.dispose();
  }
}