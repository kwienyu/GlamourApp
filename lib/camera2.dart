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
  bool _isFaceDetected = false;
  bool _isFaceAligned = false;
  bool _isGoodLighting = false;
  bool _isUsingFrontCamera = true;

  Timer? _detectionSimulationTimer;
  bool _shouldShowGreenBorder = false;
  Timer? _greenBorderTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _startSimulatedFaceDetection();
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
      print("Error initializing camera: $e");
    }
  }

  void _switchCamera() async {
    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
    });
    _initializeControllerFuture = _initializeCamera();
  }

  void _startSimulatedFaceDetection() {
    _detectionSimulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final simulatedFaceDetected = Random().nextBool();
        final simulatedFaceAligned = Random().nextBool();
        final simulatedGoodLighting = Random().nextBool();

        final newAllFollowed = simulatedFaceDetected && simulatedFaceAligned && simulatedGoodLighting;

        setState(() {
          _isFaceDetected = simulatedFaceDetected;
          _isFaceAligned = simulatedFaceAligned;
          _isGoodLighting = simulatedGoodLighting;
        });

        if (newAllFollowed && !_shouldShowGreenBorder) {
          _greenBorderTimer?.cancel();
          _shouldShowGreenBorder = true;
          setState(() {});

          _greenBorderTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && _allInstructionsFollowed) {
              setState(() {
                _shouldShowGreenBorder = false;
              });
            }
          });
        } else if (!newAllFollowed && _shouldShowGreenBorder) {
          _greenBorderTimer?.cancel();
          _shouldShowGreenBorder = false;
          setState(() {});
        }
      }
    });
  }

  bool get _allInstructionsFollowed =>
      _isFaceDetected && _isFaceAligned && _isGoodLighting;

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
        const SnackBar(content: Text("Failed to capture image. Please try again.")),
      );
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectionSimulationTimer?.cancel();
    _greenBorderTimer?.cancel();
    super.dispose();
  }

  Widget _buildTipChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.9) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
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
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),

                Positioned.fill(
                  child: CustomPaint(
                    painter: DashedOvalPainter(
                      isFaceDetected: _isFaceDetected,
                      isFaceAligned: _isFaceAligned,
                      isGoodLighting: _isGoodLighting,
                    ),
                  ),
                ),

                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Text(
                        "Capture your face",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTipChip("✓ Look straight", _isFaceDetected),
                              const SizedBox(width: 8),
                              _buildTipChip("✓ Find good lighting", _isGoodLighting),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTipChip("✓ Keep your face inside frame", _isFaceAligned),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _shouldShowGreenBorder ? Colors.green : Colors.grey,
                            width: 4,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _allInstructionsFollowed ? () => _takePicture(context) : null,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.white.withOpacity(0.9),
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: _allInstructionsFollowed ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class DashedOvalPainter extends CustomPainter {
  final bool isFaceDetected;
  final bool isFaceAligned;
  final bool isGoodLighting;

  DashedOvalPainter({
    required this.isFaceDetected,
    required this.isFaceAligned,
    required this.isGoodLighting,
  });

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
      ..color = (isFaceDetected && isFaceAligned && isGoodLighting) ? Colors.green : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 10.0;
    final dashSpace = 6.0;
    final path = Path()..addOval(ovalRect);
    drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  void drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (final ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double next = min(dashWidth, pathMetric.length - distance);
        final Path extractPath = pathMetric.extractPath(distance, distance + next);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
