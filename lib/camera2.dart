import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';  
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'makeuphub.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

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
  Timer? _faceCheckTimer;
  
  // Face detection properties
  FaceDetector? _faceDetector;
  bool _isFaceStable = false;
  DateTime? _lastFaceMovementTime;
  Rect? _lastFacePosition;
  static const double _stabilityThreshold = 0.03; 
  static const int _stabilityDurationMs = 1500;  
  bool _isProcessingFrame = false;
  bool _isTakingPicture = false;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  // Color indicator state
  Color _ovalColor = Colors.white; // Default color
  bool _isFaceDetected = false;
  bool _isFaceInFrame = false;
  bool _isFaceMoving = false;
  bool _isFaceCentered = false;
  String _faceStatusMessage = "Position your face in the oval"; // Status message

  // Accuracy reporting
  double _lightLevel = 0.0;
  double _faceDetectionConfidence = 0.0;
  final List<Map<String, dynamic>> _accuracyReports = [];

  static const double _maxRotationThreshold = 15.0; 
  static const double _centerThreshold = 0.1; 
  bool isFaceAligned = false;

  // Countdown timer properties
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  bool _isCountingDown = false;
  bool _hasCaptured = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeControllerFuture = _initializeCamera();
    _loadUserEmail();
    _startFaceDetectionTimer();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  @override
  void dispose() {
    _faceCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _controller?.dispose();
    _faceDetector?.close();
    _isTakingPicture = false; 
    super.dispose();
  }

  // Countdown timer methods
  void _startCountdown() {
    if (_isCountingDown || _hasCaptured) return;
    
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        _countdownTimer?.cancel();
        _isCountingDown = false;
        _autoCapturePicture();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdownSeconds = 3;
    });
  }

  Future<void> _analyzeLightingAndConfidence(File imageFile) async {
    try {
      // Convert image to analyze brightness
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return;
      
      double totalLuminance = 0;
      int pixelCount = 0;
      
      // Simple brightness analysis
      for (int x = 0; x < image.width; x += 10) {
        for (int y = 0; y < image.height; y += 10) {
          final pixel = image.getPixel(x, y);
          totalLuminance += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
          pixelCount++;
        }
      }
      
      _lightLevel = (totalLuminance / pixelCount) / 255.0; // Normalized 0-1
      
      // Calculate confidence based on face detection metrics
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector!.processImage(inputImage);
      
      if (faces.isNotEmpty) {
        final face = faces.first;
        _faceDetectionConfidence = (face.leftEyeOpenProbability ?? 0) + 
                                  (face.rightEyeOpenProbability ?? 0) +
                                  (face.smilingProbability ?? 0);
        _faceDetectionConfidence = (_faceDetectionConfidence / 3.0) * 100;
      }
      
      // Save report
      _accuracyReports.add({
        'timestamp': DateTime.now(),
        'light_level': _lightLevel,
        'confidence': _faceDetectionConfidence,
        'face_shape': _faceShape,
        'skin_tone': _skinTone,
      });
      
    } catch (e) {
      print('Lighting analysis error: $e');
    }
  }

  void _showAccuracyReport() {
  showDialog(
    context: _scaffoldContext,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlitterPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
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
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.assessment,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Face Recognition Accuracy",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildReportRow("Current Lighting", "${(_lightLevel * 100).toStringAsFixed(1)}%"),
                              _buildReportRow("Detection Confidence Level", "${_faceDetectionConfidence.toStringAsFixed(1)}%"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            "CLOSE",
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
          ],
        ),
      );
    },
  );
}

Widget _buildReportRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.pink.shade700,
      ),
    ),
  ],
),
);
}

Widget buildHistoryRow(String time, String light, String confidence) {
return Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 3,
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          "Light: $light",
          style: TextStyle(
            fontSize: 12,
            color: Colors.purple.shade700,
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          "Confidence: $confidence",
          style: TextStyle(
            fontSize: 12,
            color: Colors.pink.shade700,
          ),
        ),
      ),
    ],
  ),
);
}

void _startFaceDetectionTimer() {
_faceCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
  if (_controller != null && 
      _controller!.value.isInitialized && 
      !_isProcessing && 
      _capturedImage == null &&
      !_isTakingPicture &&
      !_hasCaptured) {
    _checkFacePosition();
  }
});
}

// Enhanced face coverage detection
bool _isFaceCovered(Face face) {
  final leftEye = face.landmarks[FaceLandmarkType.leftEye];
  final rightEye = face.landmarks[FaceLandmarkType.rightEye];
  final noseBase = face.landmarks[FaceLandmarkType.noseBase];
  final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth];
  final mouthRight = face.landmarks[FaceLandmarkType.rightMouth];
  final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];

  // Check if essential landmarks are detected
  if (leftEye == null || rightEye == null || noseBase == null || 
      mouthLeft == null || mouthRight == null || mouthBottom == null) {
    return true;
  }

  // Check for closed eyes (eye open probability)
  if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
    if (face.leftEyeOpenProbability! < 0.2 || face.rightEyeOpenProbability! < 0.2) {
      return true;
    }
  }

  // Check for glasses (using eye landmarks position)
  final leftEyePos = leftEye.position;
  final rightEyePos = rightEye.position;
  final nosePos = noseBase.position;
  
  // Calculate eye-to-nose distance ratio to detect glasses
  final leftEyeToNoseDistance = _calculateDistance(leftEyePos, nosePos);
  final rightEyeToNoseDistance = _calculateDistance(rightEyePos, nosePos);
  
  // If eyes are unusually far from nose, might indicate glasses
  final faceWidth = face.boundingBox.width;
  if (leftEyeToNoseDistance > faceWidth * 0.4 || rightEyeToNoseDistance > faceWidth * 0.4) {
    return true;
  }

  // Check for mouth coverage
  final mouthCenter = Offset(
    (mouthLeft.position.x + mouthRight.position.x) / 2,
    mouthBottom.position.y.toDouble()
  );
  
  final relativeMouthY = (mouthCenter.dy - face.boundingBox.top) / face.boundingBox.height;
  
  // If mouth is too high relative to face, might be covered
  if (relativeMouthY < 0.6) {
    return true;
  }

  return false;
}

// Helper method to calculate distance between two points
double _calculateDistance(Point<int> p1, Point<int> p2) {
  return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
}

// Detect if user is wearing glasses
bool _isWearingGlasses(Face face) {
  final leftEye = face.landmarks[FaceLandmarkType.leftEye];
  final rightEye = face.landmarks[FaceLandmarkType.rightEye];
  final noseBase = face.landmarks[FaceLandmarkType.noseBase];

  if (leftEye == null || rightEye == null || noseBase == null) {
    return false;
  }

  // Calculate distances between eyes and nose
  final leftEyeToNose = _calculateDistance(leftEye.position, noseBase.position);
  final rightEyeToNose = _calculateDistance(rightEye.position, noseBase.position);
  
  final faceWidth = face.boundingBox.width;
  
  // If eyes are unusually far from nose, likely wearing glasses
  return (leftEyeToNose > faceWidth * 0.35 || rightEyeToNose > faceWidth * 0.35);
}

Future<void> _checkFacePosition() async {
if (_controller == null || 
    !_controller!.value.isInitialized || 
    _isProcessingFrame || 
    _isProcessing || 
    _capturedImage != null ||
    _isTakingPicture ||
    _hasCaptured) {
  return;
}

try {
  _isProcessingFrame = true;
  
  final frame = await _controller!.takePicture();
  final inputImage = InputImage.fromFilePath(frame.path);
  final faces = await _faceDetector!.processImage(inputImage);
  await File(frame.path).delete();

  setState(() {
    if (faces.isEmpty) {
      // No face detected - white color
      _isFaceDetected = false;
      _isFaceInFrame = false;
      _isFaceMoving = false;
      _isFaceCentered = false;
      _ovalColor = Colors.white;
      _faceStatusMessage = "No face detected. Please position your face in the oval";
      // Cancel countdown if no face detected
      if (_isCountingDown) {
        _cancelCountdown();
      }
      print("No face detected - White");
    } else {
      final face = faces.first;
      
      final isFaceCovered = _isFaceCovered(face);
      final isWearingGlasses = _isWearingGlasses(face);
      final isFaceAligned = checkFaceAlignment(face);
      final isFaceInOval = _isFaceInOval(face.boundingBox);
      
      // Update face detection states
      _isFaceDetected = true;
      _isFaceInFrame = isFaceInOval && !isFaceCovered && !isWearingGlasses;
      
      // Check if face is moving
      _checkFaceStability(face.boundingBox);
      _isFaceMoving = !_isFaceStable;
      
      // Check if face is centered and aligned
      _isFaceCentered = isFaceAligned && isFaceInOval && !isFaceCovered && !isWearingGlasses && _isFaceStable;
      
      // Debug prints
      print("Face detected: $_isFaceDetected");
      print("Face in frame: $_isFaceInFrame");
      print("Face moving: $_isFaceMoving");
      print("Face centered: $_isFaceCentered");
      print("Face stable: $_isFaceStable");
      print("Face covered: $isFaceCovered");
      print("Wearing glasses: $isWearingGlasses");
      
      // Determine oval color based on conditions
      if (!_isFaceInFrame) {
        // Face detected but not in frame or too far - red
        _ovalColor = Colors.red;
        _faceStatusMessage = "Position your face in the oval";
        // Cancel countdown if face not in frame
        if (_isCountingDown) {
          _cancelCountdown();
        }
        print("Face not in frame - Red");
      } else if (isFaceCovered) {
        // Face is covered - red with specific message
        _ovalColor = Colors.red;
        _faceStatusMessage = "Please remove anything covering your face";
        if (_isCountingDown) {
          _cancelCountdown();
        }
        print("Face covered - Red");
      } else if (isWearingGlasses) {
        // User is wearing glasses - red with specific message
        _ovalColor = Colors.red;
        _faceStatusMessage = "Please remove your glasses for better detection";
        if (_isCountingDown) {
          _cancelCountdown();
        }
        print("Wearing glasses - Red");
      } else if (_isFaceMoving) {
        // Face is in frame but moving - orange
        _ovalColor = Colors.orange;
        _faceStatusMessage = "Hold still for better detection";
        // Cancel countdown if face is moving
        if (_isCountingDown) {
          _cancelCountdown();
        }
        print("Face moving - Orange");
      } else if (_isFaceCentered) {
        // Face is correctly positioned, stable, and centered - green
        _ovalColor = Colors.green;
        _faceStatusMessage = "Perfect! Photo will be taken automatically";
        print("Face centered and stable - Green");
        
        // Start countdown if not already counting and not captured yet
        if (!_isCountingDown && !_hasCaptured) {
          _startCountdown();
        }
      } else {
        // Default to red if other conditions aren't met
        _ovalColor = Colors.red;
        _faceStatusMessage = "Adjust your position for better detection";
        // Cancel countdown if face not properly positioned
        if (_isCountingDown) {
          _cancelCountdown();
        }
        print("Other condition - Red");
      }
    }
  });
} catch (e) {
  print('Face detection error: $e');
  setState(() {
    _isFaceStable = false;
    _ovalColor = Colors.white;
    _faceStatusMessage = "Error detecting face. Please try again";
    // Cancel countdown on error
    if (_isCountingDown) {
      _cancelCountdown();
    }
  });
} finally {
  _isProcessingFrame = false;
}
}

Rect _getAdjustedFaceRect(Rect faceRect) {
if (_controller == null || !_controller!.value.isInitialized) {
  return faceRect;
}

final screenSize = MediaQuery.of(_scaffoldContext).size;
final previewSize = _controller!.value.previewSize!;

// Camera preview might be rotated or scaled to fit the screen
double scaleX, scaleY;
double translateX = 0, translateY = 0;

if (_isUsingFrontCamera) {
  // Front camera is mirrored and might need different scaling
  scaleX = screenSize.width / previewSize.height;
  scaleY = screenSize.height / previewSize.width;
  // For front camera, we need to flip horizontally and adjust positioning
  final flippedLeft = previewSize.height - faceRect.right;
  return Rect.fromLTRB(
    flippedLeft * scaleX,
    faceRect.top * scaleY,
    (flippedLeft + faceRect.width) * scaleX,
    (faceRect.top + faceRect.height) * scaleY,
  );
} else {
  // Back camera - standard scaling
  scaleX = screenSize.width / previewSize.width;
  scaleY = screenSize.height / previewSize.height;
  
  return Rect.fromLTRB(
    faceRect.left * scaleX,
    faceRect.top * scaleY,
    faceRect.right * scaleX,
    faceRect.bottom * scaleY,
  );
}
}

// Update the isFaceInOval method to be more accurate
bool _isFaceInOval(Rect faceRect) {
final screenSize = MediaQuery.of(_scaffoldContext).size;
final ovalCenter = Offset(screenSize.width / 2, screenSize.height * 0.4);
final ovalWidth = screenSize.width * 0.75;
final ovalHeight = screenSize.height * 0.45;

final adjustedFaceRect = _getAdjustedFaceRect(faceRect);

final faceCenter = Offset(
  adjustedFaceRect.left + adjustedFaceRect.width / 2,
  adjustedFaceRect.top + adjustedFaceRect.height / 2,
);

// Calculate how much of the face is inside the oval
final faceArea = adjustedFaceRect.width * adjustedFaceRect.height;

// Check if the face center is within the oval
final normalizedX = pow((faceCenter.dx - ovalCenter.dx) / (ovalWidth / 2), 2);
final normalizedY = pow((faceCenter.dy - ovalCenter.dy) / (ovalHeight / 2), 2);

// Check if a significant portion of the face is inside the oval (at least 60%)
final isCenterInOval = (normalizedX + normalizedY) <= 1.0;

// Calculate how much of the face is inside the oval
final ovalRect = Rect.fromCenter(center: ovalCenter, width: ovalWidth, height: ovalHeight);
final intersectionRect = adjustedFaceRect.intersect(ovalRect);
final intersectionArea = intersectionRect.width * intersectionRect.height;
final faceCoverage = intersectionArea / faceArea;

return isCenterInOval && faceCoverage >= 0.6;
}

bool checkFaceAlignment(Face face) {
final headEulerAngleY = face.headEulerAngleY ?? 0.0;
final headEulerAngleX = face.headEulerAngleX ?? 0.0;

// Increased threshold for rotation (from 15 to 20 degrees)
if (headEulerAngleY.abs() > 20.0 || 
    headEulerAngleX.abs() > 20.0) {
  return false;
}

final screenSize = MediaQuery.of(_scaffoldContext).size;
final ovalCenter = Offset(screenSize.width / 2, screenSize.height * 0.4);

final adjustedFaceRect = _getAdjustedFaceRect(face.boundingBox);
final faceCenter = Offset(
  adjustedFaceRect.left + adjustedFaceRect.width / 2,
  adjustedFaceRect.top + adjustedFaceRect.height / 2,
);

// Increased center threshold (from 0.1 to 0.15)
final xOffset = (faceCenter.dx - ovalCenter.dx).abs() / (screenSize.width * 0.375);
final yOffset = (faceCenter.dy - ovalCenter.dy).abs() / (screenSize.height * 0.225);

return xOffset <= 0.15 && yOffset <= 0.15;
}


void _checkFaceStability(Rect currentPosition) {
final now = DateTime.now();

if (_lastFacePosition == null) {
  _lastFacePosition = currentPosition;
  _lastFaceMovementTime = now;
  _isFaceStable = false;
  return;
}

final dx = (currentPosition.left - _lastFacePosition!.left).abs() / _lastFacePosition!.width;
final dy = (currentPosition.top - _lastFacePosition!.top).abs() / _lastFacePosition!.height;
final movement = sqrt(dx * dx + dy * dy); 

print('Face movement: ${movement.toStringAsFixed(4)}');

if (movement > _stabilityThreshold) {
  _lastFacePosition = currentPosition;
  _lastFaceMovementTime = now;
  _isFaceStable = false;
} else if (_lastFaceMovementTime != null && 
          now.difference(_lastFaceMovementTime!).inMilliseconds > _stabilityDurationMs) {
  _isFaceStable = true;
}

_lastFacePosition = currentPosition;
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
    (camera) => camera.lensDirection == 
        (_isUsingFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
    orElse: () => cameras.first,
  );

  _controller = CameraController(
    selectedCamera,
    ResolutionPreset.medium,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );
  
  await _controller!.initialize();
  await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
  _rotation = _getRotation(selectedCamera.sensorOrientation);
  
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

InputImageRotation _getRotation(int sensorOrientation) {
switch (sensorOrientation) {
  case 90:
    return InputImageRotation.rotation90deg;
  case 180:
    return InputImageRotation.rotation180deg;
  case 270:
    return InputImageRotation.rotation270deg;
  default:
    return InputImageRotation.rotation0deg;
}
}

Matrix4 _getCameraPreviewTransform() {
final screenSize = MediaQuery.of(_scaffoldContext).size;
final cameraAspectRatio = _controller!.value.aspectRatio;
final screenAspectRatio = screenSize.width / screenSize.height;

if (_isUsingFrontCamera) {
  return Matrix4.identity()
    ..scale(-1.0, 1.0, 1.0)
    ..translate(-screenSize.width, 0.0);
} else {
  if (cameraAspectRatio > screenAspectRatio) {
    final scale = screenSize.height / (screenSize.width / cameraAspectRatio);
    return Matrix4.diagonal3Values(1.0, scale, 1.0);
  } else {
    final scale = screenSize.width / (screenSize.height * cameraAspectRatio);
    return Matrix4.diagonal3Values(scale, 1.0, 1.0);
  }
}
}

void _switchCamera() async {
// Cancel any ongoing countdown
_cancelCountdown();

setState(() {
  _isUsingFrontCamera = !_isUsingFrontCamera;
  _showResults = false;
  _capturedImage = null;
  _lastFacePosition = null;
  _lastFaceMovementTime = null;
  _isFaceStable = false;
  _ovalColor = Colors.white; // Reset color when switching camera
  _hasCaptured = false; // Reset capture flag
  _faceStatusMessage = "Position your face in the oval";
});
_initializeControllerFuture = _initializeCamera();
}

Future<void> _autoCapturePicture() async {
// Cancel countdown before capturing
_cancelCountdown();

if (_isTakingPicture || _hasCaptured) return;

try {
  if (_userEmail == null || _userEmail!.isEmpty) {
    throw Exception('Please login first to use this feature');
  }

  setState(() {
    _isTakingPicture = true; 
    _isProcessing = true;
    _showResults = false;
    _capturedImage = null;
    _hasCaptured = true; // Set flag to indicate capture has happened
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
  print("Auto capture error: $e");
  if (mounted) {
    ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
} finally {
  if (mounted) {
    setState(() {
      _isTakingPicture = false; 
      _isProcessing = false;
    });
  }
}
}

Future<void> _analyzeImage(File imageFile) async {
try {
  setState(() {
    _isLoading = true;
    _showResults = false;
  });

  // Analyze lighting and confidence before sending to server
  await _analyzeLightingAndConfidence(imageFile);

  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('https://glamouraika.com/api/upload_image')
  )..fields['email'] = _userEmail!;

  request.files.add(await http.MultipartFile.fromPath(
    'image', 
    imageFile.path,
    contentType: MediaType('image', 'jpeg'),
  ));

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

    setState(() {
      _faceShape = jsonResponse['face_shape'];
      _skinTone = jsonResponse['skin_tone'];
      _showResults = true;
      _isLoading = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlitterPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Results Saved!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your face shape and skin tone results\nhave been saved to your profile",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
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
    setState(() => _isLoading = false);
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
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    body: Stack(
      children: [
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
                  CameraPreview(
                    _controller!,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Transform(
                          transform: _getCameraPreviewTransform(),
                          alignment: Alignment.center,
                          child: Container(),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DashedOvalPainter(
                        ovalColor: _ovalColor,
                        countdownSeconds: _isCountingDown ? _countdownSeconds : null,
                        isCountingDown: _isCountingDown,
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
              Image.file(
                _capturedImage!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
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
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _buildResultsPanel(),
                  ),
                ),
            ],
          ),

        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Text(
            _capturedImage == null ? "Position your face in the oval" : "Your Captured Photo",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        if (_capturedImage == null)
          // Switch camera button moved slightly upward
          Positioned(
            bottom: screenHeight * 0.30,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 36),
              onPressed: _isProcessing ? null : _switchCamera,
            ),
          ),

        if (_capturedImage == null)
          // Status dialogue box position remains unchanged
          Positioned(
            bottom: screenHeight * 0.08,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ovalColor.withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _ovalColor == Colors.white
                        ? const Text(
                            'No face detected (White)',
                            key: ValueKey('status_white'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          )
                        : _ovalColor == Colors.red
                          ? const Text(
                              'Face detected but not aligned (Red)',
                              key: ValueKey('status_red'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            )
                          : _ovalColor == Colors.orange
                            ? const Text(
                                'Face detected but moving (Orange)',
                                key: ValueKey('status_orange'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              )
                            : const Text(
                                'Face aligned and stable (Green)',
                                key: ValueKey('status_green'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              ),
                  ),
                  const SizedBox(height: 8),
                  // Moved "Detailed Status:" more to the left
                  Padding(
                    padding: const EdgeInsets.only(left: 01.0),
                    child: Text(
                      'Detailed Status:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Container to align bullet points while keeping them slightly left
                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Detected: $_isFaceDetected',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '• In Frame: $_isFaceInFrame',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '• Stable: $_isFaceStable',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '• Centered: $_isFaceCentered',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '• Moving: $_isFaceMoving',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _faceStatusMessage, // Use the dynamic status message
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildResultsPanel() {
return Center(
  child: Container(
    width: MediaQuery.of(_scaffoldContext).size.width * 0.7,
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
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          "Skin Tone: ${_skinTone!.toUpperCase()}",
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _showAccuracyReport,
          child: const Text('View Recognition Accuracy'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                _scaffoldContext,
                MaterialPageRoute(
                  builder: (context) => MakeupHubPage(
                    skinTone: _skinTone!,
                    capturedImage: _capturedImage!,
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
            child: const Text(
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
final Color ovalColor;
final int? countdownSeconds;
final bool isCountingDown;

const DashedOvalPainter({
  this.ovalColor = Colors.white,
  this.countdownSeconds,
  this.isCountingDown = false,
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
    ..color = ovalColor
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  final path = Path()..addOval(ovalRect);
  _drawDashedPath(canvas, path, paint, 10.0, 6.0);
  
  // Add countdown text if counting down
  if (isCountingDown && countdownSeconds != null && countdownSeconds! > 0) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: countdownSeconds.toString(),
        style: TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.bold,
          color: ovalColor,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
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