import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  int _selectedCameraIndex = 0;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera
  void _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController.initialize();
    if (!mounted) return;
    setState(() {});
  }

  // Capture the photo
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  // Switch Camera (Front or Back)
  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
      _initializeCamera();
    });
  }

  // Dispose the camera
  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),

              // --- Centered Camera Screen ---
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9, // Adjust size
                  height: MediaQuery.of(context).size.width * 1.5, // Reduced height
                  margin: const EdgeInsets.only(top: 60), // Margin to avoid overlap
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _imageFile == null
                        ? FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                return CameraPreview(_cameraController);
                              } else {
                                return const Center(child: CircularProgressIndicator());
                              }
                            },
                          )
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Buttons: Switch Camera + Capture Look ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                    onPressed: _switchCamera,
                  ),
                  const SizedBox(width: 20),

                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Look'),
                  ),
                ],
              ),
            ],
          ),

          // --- Back Button in Upper Left Corner ---
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

