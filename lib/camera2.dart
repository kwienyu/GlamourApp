import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'customization.dart';

class CameraPage extends StatefulWidget {
  final String selectedUndertone;
  final String selectedMakeupType;
  final String selectedMakeupLook;
  final String userId;
  final String? skinTone; // Added skinTone parameter

  const CameraPage({
    super.key,
    required this.selectedUndertone,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
    required this.userId,
    this.skinTone, // Added as optional parameter
  });

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  String? _imagePath;
  bool _isFaceDetected = false;
  bool _isInsideFrame = false;
  bool _isUsingFrontCamera = true;

  Timer? _detectionSimulationTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _startSimulatedFaceDetection();
    
    // Optional: Log the skin tone if it's provided
    if (widget.skinTone != null) {
      print('User skin tone: ${widget.skinTone}');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == (_isUsingFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      _controller = CameraController(selectedCamera, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Camera init error: $e");
    }
  }

  void _switchCamera() async {
    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
    });
    _initializeControllerFuture = _initializeCamera();
  }

  void _startSimulatedFaceDetection() {
    _detectionSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;

      setState(() {
        _simulateFaceDetection();
        _simulateInsideFrame();
      });
    });
  }

  void _simulateFaceDetection() {
    _isFaceDetected = Random().nextBool();
  }

  void _simulateInsideFrame() {
    if (_isFaceDetected) {
      _isInsideFrame = Random().nextBool();
    } else {
      _isInsideFrame = false;
    }
  }

  bool get _isReadyForCapture =>
      _isFaceDetected && _isInsideFrame;

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      if (_controller == null || !_controller!.value.isInitialized) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.png');
      final XFile file = await _controller!.takePicture();
      await file.saveTo(imagePath);

      if (!mounted) return;

      setState(() => _imagePath = imagePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomizationPage(
            imagePath: imagePath,
            selectedMakeupType: widget.selectedMakeupType,
            selectedMakeupLook: widget.selectedMakeupLook,
            userId: widget.userId,  
            undertone: widget.selectedUndertone,
            skinTone: widget.skinTone, // Pass skinTone to CustomizationPage
          ),
        ),
      );
    } catch (e) {
      print("Capture error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture image.")),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectionSimulationTimer?.cancel();
    super.dispose();
  }

  Widget _buildTipChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || _controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),

              Positioned.fill(
                child: CustomPaint(
                  painter: DashedOvalPainter(
                    showGreen: _isReadyForCapture,
                  ),
                ),
              ),

              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Text(
                  "Capture your face",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Positioned(
                bottom: 70,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 36),
                  onPressed: _switchCamera,
                ),
              ),

              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTipChip("✓ Look straight"),
                        const SizedBox(width: 8),
                        _buildTipChip("✓ Good lighting"),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildTipChip("✓ Face inside frame"),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isReadyForCapture ? Colors.green : Colors.grey,
                          width: 4,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isReadyForCapture ? () => _takePicture(context) : null,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.white.withOpacity(0.9),
                          disabledBackgroundColor: Colors.white.withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: _isReadyForCapture ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashedOvalPainter extends CustomPainter {
  final bool showGreen;

  DashedOvalPainter({required this.showGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width * 0.75;
    final double height = size.height * 0.45;
    final Offset center = Offset(size.width / 2, size.height * 0.4);
    final Rect ovalRect = Rect.fromCenter(center: center, width: width, height: height);

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final clipPath = Path()..addOval(ovalRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), clipPath),
      Paint()..blendMode = BlendMode.clear,
    );

    final paint = Paint()
      ..color = showGreen ? Colors.green : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(ovalRect);
    _drawDashedPath(canvas, path, paint, 10.0, 6.0);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final Path segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}