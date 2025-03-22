import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class GlamVaultPage extends StatefulWidget {
  
  @override
  _GlamVaultPageState createState() => _GlamVaultPageState();
}

class _GlamVaultPageState extends State<GlamVaultPage> {
  CameraController? _cameraController;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // Capture photo and save it
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDir.path}/captured_image.jpg';

      // Save the image
      final File savedImage = File(imageFile.path);
      await savedImage.copy(imagePath);

      setState(() {
        _capturedImage = File(imagePath);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved successfully!')),
      );
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Glam Vault')),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
          if (_capturedImage != null)
            Image.file(_capturedImage!, height: 200), // Show captured image
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _capturePhoto,
            child: Text('Capture Photo'),
          ),
        ],
      ),
    );
  }
}
