import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  bool _isFaceDetected = false; // New: to track if a face is detected
  bool _isFaceAligned = false;  // New: to track if the face is aligned properly

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _simulateFaceDetection(); // simulate face detection for now
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

  // Simulation for face detection (replace this with real detection later)
  void _simulateFaceDetection() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isFaceDetected = true; // Let's say a face was detected
        _isFaceAligned = true;  // And it's aligned (you can customize this)
      });
    });
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception("Camera is not initialized");
      }

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.png');

      final XFile file = await _controller!.takePicture();
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
          // Instructions at the top
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    !_isFaceDetected
                        ? "Face not detected. Please position your face inside the guide."
                        : _isFaceAligned
                            ? "Face aligned! You can now take a picture."
                            : "Align your face with the lines on your forehead and chin.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Make sure your face is centered and aligned within the guide lines before clicking the capture button.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Camera preview
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
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // Face verification guide lines
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              painter: VerificationPainter(
                isFaceDetected: _isFaceDetected,
                isFaceAligned: _isFaceAligned,
              ),
            ),
          ),
          // Capture button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: (_isFaceDetected && _isFaceAligned) ? () async {
                  _takePicture(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: (_isFaceDetected && _isFaceAligned)
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.withOpacity(0.5),
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

// Painter for guide lines
class VerificationPainter extends CustomPainter {
  final bool isFaceDetected;
  final bool isFaceAligned;

  VerificationPainter({required this.isFaceDetected, required this.isFaceAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (!isFaceDetected || !isFaceAligned) ? Colors.red : Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw lines for forehead and chin
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.3), Offset(size.width * 0.8, size.height * 0.3), paint); // Forehead line
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.7), Offset(size.width * 0.8, size.height * 0.7), paint); // Chin line
  }

  @override
  bool shouldRepaint(covariant VerificationPainter oldDelegate) {
    return oldDelegate.isFaceDetected != isFaceDetected ||
        oldDelegate.isFaceAligned != isFaceAligned;
  }
}


