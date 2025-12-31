import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;

  // 1. Handling Permission
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      // Permission.photos, // Uncomment jika perlu untuk iOS 14+
    ].request();

    return statuses[Permission.camera]!.isGranted;
  }

  // 2. Modul Kamera (Initialize)
  Future<CameraController?> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high, // Gunakan High agar hasil crop tidak buram
      enableAudio: false,
    );

    await _controller!.initialize();
    return _controller;
  }

  // 3. Ambil Foto (Raw)
  // Kita tidak compress di sini, karena akan dicrop dulu
  Future<File?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    final XFile rawImage = await _controller!.takePicture();
    return File(rawImage.path);
  }

 // For image_cropper version 5.0.0
  Future<File?> cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Potong Struk',
            toolbarColor: const Color(0xFF2962FF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Potong Struk',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}