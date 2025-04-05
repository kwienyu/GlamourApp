import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'customization.dart';  

class CameraPage extends StatefulWidget {
  final String selectedUndertone;
  final String selectedMakeupType;
  final String selectedMakeupLook;

  const CameraPage({
    super.key,
    required this.selectedUndertone,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
  });

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  String? _imagePath;  

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.high);
      await _controller!.initialize();

      if (mounted) {
        setState(() {}); 
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  // Function to capture the image
  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception("Camera is not initialized");
      }

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.png');

      final file = await _controller!.takePicture();
      await file.saveTo(imagePath);

      if (mounted) {
        setState(() {
          _imagePath = imagePath;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomizationPage(
              imagePath: _imagePath!,
              selectedMakeupType: widget.selectedMakeupType,
              selectedMakeupLook: widget.selectedMakeupLook,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to capture image. Please try again.")),
      );
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2), 
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => _takePicture(context),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
                child: const Icon(Icons.camera_alt, size: 50, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
