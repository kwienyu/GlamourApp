import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'makeuphub.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isUsingFrontCamera = true;
  bool _isProcessing = false;
  late BuildContext _scaffoldContext;
  bool _isLoading = false;
  String? _faceShape;
  String? _skinTone;
  bool _showResults = false;
  String? _userEmail;
  File? _capturedImage;
  Color _ovalColor = Colors.white; // Track oval frame color
  bool _faceDetected = false; // Track if face is detected
  bool _faceInFrame = false; // Track if face is within oval frame
  Timer? _faceCheckTimer; // Timer for checking face position

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _loadUserEmail();
    _startFaceDetectionTimer();
  }

  @override
  void dispose() {
    _faceCheckTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startFaceDetectionTimer() {
    _faceCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_controller != null && _controller!.value.isInitialized && !_isProcessing && _capturedImage == null) {
        _checkFacePosition();
      }
    });
  }

  Future<void> _checkFacePosition() async {
    // In a real app, you would use a face detection library here
    // For this example, we'll simulate face detection
    
    // Simulate face detection - replace with actual face detection logic
    bool faceDetected = Random().nextDouble() > 0.3; // 70% chance of detecting face
    bool faceInFrame = Random().nextDouble() > 0.5; // 50% chance of face being in frame
    
    setState(() {
      _faceDetected = faceDetected;
      _faceInFrame = faceInFrame;
      
      // Update oval color based on face position
      if (!_faceDetected) {
        _ovalColor = Colors.white; // No face detected
      } else if (!_faceInFrame) {
        _ovalColor = Colors.red; // Face detected but not in frame
      } else {
        _ovalColor = Colors.green; // Face detected and in frame
      }
    });
  }

  Future<void> _loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null || email.isEmpty) {
        throw Exception('Please login first to save your results');
      }
      setState(() {
        _userEmail = email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
          const SnackBar(content: Text("Failed to initialize camera")),
        );
      }
    }
  }

  void _switchCamera() async {
    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
      _showResults = false;
      _capturedImage = null;
      _ovalColor = Colors.white; // Reset color when switching camera
    });
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _takePicture() async {
    try {
      if (_userEmail == null || _userEmail!.isEmpty) {
        throw Exception('Please login first to use this feature');
      }

      // Only allow capture when face is in frame and stable (green)
      if (_ovalColor != Colors.green) {
        throw Exception('Please position your face properly within the frame');
      }

      setState(() {
        _isProcessing = true;
        _showResults = false;
        _capturedImage = null;
      });
      
      await _initializeControllerFuture;
      if (_controller == null || !_controller!.value.isInitialized) return;

      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      if (!mounted) return;
      
      setState(() {
        _capturedImage = imageFile;
      });

      await _analyzeImage(imageFile);
      
    } catch (e) {
      print("Capture error: $e");
      if (mounted) {
        ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

 Future<void> _analyzeImage(File imageFile) async {
  try {
    setState(() {
      _isLoading = true;
      _showResults = false; // Ensure this is reset before new analysis
    });

    // Add timeout to the request
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('https://glamouraika.com/api/upload_image')
    )..fields['email'] = _userEmail!;

    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    // Add timeout and better error handling
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('The connection timed out');
      },
    );

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['face_shape'] == null || jsonResponse['skin_tone'] == null) {
        throw Exception('Could not detect face shape and skin tone. Please try again with a clearer photo.');
      }

       // Debug prints to verify values
      print('Face shape: ${jsonResponse['face_shape']}');
      print('Skin tone: ${jsonResponse['skin_tone']}');

      setState(() {
        _faceShape = jsonResponse['face_shape'];
        _skinTone = jsonResponse['skin_tone'];
        _showResults = true;
        _isLoading = false;
      });
        // Show glitter popup
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                insetPadding: EdgeInsets.all(20),
                backgroundColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.pink.shade50,
                        Colors.purple.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glitter particles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GlitterPainter(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sparkle icon
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.5,
                                  colors: [
                                    Colors.pink.shade200,
                                    Colors.purple.shade200,
                                    Colors.pink.shade400,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: Icon(
                                Icons.auto_awesome,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Results Saved!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade800,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Your face shape and skin tone results\nhave been saved to your profile",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "GOT IT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
      final errorData = await response.stream.bytesToString();
      final errorMessage = json.decode(errorData)['message'] ?? 'Analysis failed. Please try again.';
      throw Exception(errorMessage);
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}


@override
Widget build(BuildContext context) {
  _scaffoldContext = context;
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Scaffold(
    body: Stack(
      children: [
        // Show either camera preview or captured image
        if (_capturedImage == null)
          FutureBuilder<void>(
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
                      painter: DashedOvalPainter(color: _ovalColor),
                    ),
                  ),
                  // Add guidance text based on oval color
                  if (_ovalColor == Colors.red)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Please position your face within the frame',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  if (_ovalColor == Colors.green)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Hold still and tap the capture button',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else
          Stack(
            fit: StackFit.expand,
            children: [
              // Full screen image with explicit fit
              Image.file(
                _capturedImage!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low, // Helps with rendering performance
              ),
              
              // Show loading or results
              if (_isLoading)
                Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor: Colors.pinkAccent,
                    rightDotColor: Colors.pinkAccent,
                    size: screenWidth * 0.1,
                  ),
                )
              else if (_showResults && _faceShape != null && _skinTone != null)
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _buildResultsPanel(),
                  ),
                ),
            ],
          ),

        // App bar title - shown in both modes
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Text(
            _capturedImage == null ? "Capture your face" : "Your Captured Photo",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Camera switch button - only visible when in camera mode
        if (_capturedImage == null)
          Positioned(
            bottom: 70,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 36),
              onPressed: _isProcessing ? null : _switchCamera,
            ),
          ),

        // Capture button - only visible when in camera mode
        if (_capturedImage == null)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _takePicture,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white.withOpacity(0.9),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.black,
                  ),
                ),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

 Widget _buildResultsPanel() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Analysis Results",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Face Shape: ${_faceShape!.toUpperCase()}",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Skin Tone: ${_skinTone!.toUpperCase()}",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeupHubPage(
          skinTone: _skinTone!,
          capturedImage: _capturedImage!, // Pass the File directly
        ),
      ),
    );
  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  "Proceed",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedOvalPainter extends CustomPainter {
  final Color color;
  
  DashedOvalPainter({this.color = Colors.white});

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
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(ovalRect);
    _drawDashedPath(canvas, path, paint, 10.0, 6.0);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    for (final metric in path.computeMetrics()) {
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

class _GlitterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw random glitter particles
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final opacity = random.nextDouble() * 0.7 + 0.3;
      
      paint.color = Colors.white.withOpacity(opacity);
      if (random.nextBool()) {
        paint.color = Colors.pink.shade200.withOpacity(opacity);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}