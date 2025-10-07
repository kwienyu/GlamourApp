import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';  
import 'package:image/image.dart' as img;
import 'makeuphub.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
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
  static const double _stabilityThreshold = 0.05; 
  static const int _stabilityDurationMs = 500; 
  bool _isProcessingFrame = false;
  bool _isTakingPicture = false;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  // Color indicator state
  Color _ovalColor = Colors.white; 
  bool _isFaceDetected = false;
  bool _isFaceInFrame = false;
  bool _isFaceMoving = false;
  bool _isFaceCentered = false;

  // Accuracy reporting
  double _lightLevel = 0.0;
  double _faceDetectionConfidence = 0.0;
  final List<Map<String, dynamic>> _accuracyReports = [];

  // Countdown timer properties
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  bool _isCountingDown = false;
  bool _hasCaptured = false;

  // Navigation footer state
  bool _isFooterVisible = false;
  bool _isFooterAutoHidden = false;
  double _dragOffset = 0.0;
  final double _swipeThreshold = 50.0;

  // Warning message state
  bool _showWarningMessage = true;
  Timer? _warningTimer;

  // Performance optimization properties
  DateTime? _lastFrameProcessTime;
  static const int _minFrameIntervalMs = 300;
  bool _shouldSkipFrame = false;
  Completer<void>? _currentFrameCompleter;

  // Notification system for user feedback
  String? _currentNotification;
  Timer? _notificationTimer;
  bool _showNotification = false;
  int _repeatedCountdownCancellations = 0;
  DateTime? _lastCountdownCancelTime;
  double _lowLightThreshold = 0.2;
  double _poorLightThreshold = 0.3;

  // Countdown reset tracking
  int _countdownResetCount = 0;
  DateTime? _lastCountdownResetTime;
  bool _showCountdownResetMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeControllerFuture = _initializeCamera();
    _loadUserEmail();
    _startFaceDetectionTimer();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isFooterVisible) {
        setState(() {
          _isFooterAutoHidden = true;
        });
      }
    });

    _warningTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showWarningMessage) {
        setState(() {
          _showWarningMessage = false;
        });
      }
    });
  }

  // Show notification method with simple elegant design
  void _showUserNotification(String message, {Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;
    
    setState(() {
      _currentNotification = message;
      _showNotification = true;
    });

    _notificationTimer?.cancel();
    _notificationTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _showNotification = false;
          _currentNotification = null;
        });
      }
    });
  }

  // Analyze why countdown keeps resetting
  void _analyzeCountdownIssues() {
    final now = DateTime.now();
    
    // Check for repeated countdown cancellations
    if (_lastCountdownCancelTime != null && 
        now.difference(_lastCountdownCancelTime!).inSeconds < 5) {
      _repeatedCountdownCancellations++;
    } else {
      _repeatedCountdownCancellations = 1;
    }
    
    _lastCountdownCancelTime = now;

    // Track countdown resets for showing specific messages
    if (_lastCountdownResetTime != null && 
        now.difference(_lastCountdownResetTime!).inSeconds < 10) {
      _countdownResetCount++;
    } else {
      _countdownResetCount = 1;
    }
    _lastCountdownResetTime = now;

    // Show countdown reset message if it happens multiple times
    if (_countdownResetCount >= 2 && !_showCountdownResetMessage) {
      _showCountdownResetMessage = true;
      _showUserNotification(
        'Countdown keeps resetting\nEnsure good lighting and hold still',
        duration: Duration(seconds: 5)
      );
      
      // Reset after showing the message
      Future.delayed(Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _showCountdownResetMessage = false;
          });
        }
      });
    }

    // Show notifications based on the issue
    if (_repeatedCountdownCancellations >= 2) {
      if (!_isFaceDetected) {
        _showUserNotification(
          'No face detected\nPosition face in oval',
          duration: Duration(seconds: 4)
        );
      } 
      else if (!_isFaceInFrame) {
        _showUserNotification(
          'Face not properly framed\nMove face inside oval',
          duration: Duration(seconds: 4)
        );
      }
      else if (_isFaceMoving) {
        _showUserNotification(
          'Please hold still\nFace movement detected',
          duration: Duration(seconds: 4)
        );
      }
      else if (!_isFaceCentered) {
        _showUserNotification(
          'Center your face\nAlign in the oval',
          duration: Duration(seconds: 4)
        );
      }
      else if (_lightLevel < _lowLightThreshold) {
        _showUserNotification(
          'Low light detected\nMove to brighter area',
          duration: Duration(seconds: 4)
        );
      }
      else if (_lightLevel < _poorLightThreshold) {
        _showUserNotification(
          'Poor lighting\nImprove light conditions',
          duration: Duration(seconds: 4)
        );
      }
      else {
        _showUserNotification(
          'Face detection issue\nCheck position & lighting',
          duration: Duration(seconds: 4)
        );
      }
    }
  }

  // Check lighting conditions and notify user
  void _checkLightingConditions() {
    if (_lightLevel < _lowLightThreshold) {
      _showUserNotification(
        'Very dark environment\nTurn on more lights',
        duration: Duration(seconds: 4)
      );
    } else if (_lightLevel < _poorLightThreshold) {
      _showUserNotification(
        'Dim lighting detected\nBetter light improves accuracy',
        duration: Duration(seconds: 4)
      );
    } else if (_lightLevel > 0.8) {
      _showUserNotification(
        'Too bright\nAvoid direct light on face',
        duration: Duration(seconds: 4)
      );
    }
  }
  void _handleApiError(dynamic e) {
    String errorMessage = 'An unexpected error occurred\nPlease try again';
    
    if (e is TimeoutException) {
      errorMessage = 'Connection timeout\nCheck internet connection';
    } else if (e is SocketException) {
      errorMessage = 'No internet connection\nCheck network settings';
    } else if (e is http.ClientException) {
      errorMessage = 'Network error\nCheck connection';
    } else if (e.toString().contains('Failed host lookup')) {
      errorMessage = 'Cannot connect to server\nCheck internet connection';
    } else if (e.toString().contains('face_shape') || e.toString().contains('skin_tone')) {
      errorMessage = 'No face shape detected\nTry again with better lighting';
    } else {
      errorMessage = e.toString();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _initializeFaceDetector() {
  final options = FaceDetectorOptions(
    performanceMode: FaceDetectorMode.fast,
    enableContours: false,
    enableClassification: false,
    enableLandmarks: true,
    enableTracking: true,
    minFaceSize: 0.3,
  );
  _faceDetector = FaceDetector(options: options);
}

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _faceCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _warningTimer?.cancel();
    _notificationTimer?.cancel();
    _controller?.dispose();
    _faceDetector?.close();
    _isTakingPicture = false;
    _currentFrameCompleter?.complete();
    super.dispose();
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_isFooterAutoHidden && details.delta.dy < 0) {
      setState(() {
        _dragOffset += details.delta.dy.abs();
      });
      
      if (_dragOffset >= _swipeThreshold) {
        setState(() {
          _isFooterVisible = true;
          _isFooterAutoHidden = false;
          _dragOffset = 0.0;
        });
      }
    } else if (_isFooterVisible && details.delta.dy > 0) {
      setState(() {
        _dragOffset += details.delta.dy;
      });
      
      if (_dragOffset >= _swipeThreshold) {
        setState(() {
          _isFooterVisible = false;
          _isFooterAutoHidden = true;
          _dragOffset = 0.0;
        });
      }
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > 0) {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _handleTapToDismissWarning() {
    if (_showWarningMessage) {
      setState(() {
        _showWarningMessage = false;
      });
      _warningTimer?.cancel();
    }
  }

  void toggleNavigationFooter() {
    setState(() {
      _isFooterVisible = !_isFooterVisible;
      _isFooterAutoHidden = !_isFooterVisible;
    });
  }

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
    
    // Analyze why countdown was cancelled
    _analyzeCountdownIssues();
  }

  Future<void> _analyzeLightingAndConfidence(File imageFile) async {
    try {
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) {
        _faceDetectionConfidence = 0.0;
        return;
      }
      
      // Analyze lighting quality more accurately
      double totalLuminance = 0;
      int pixelCount = 0;
      List<double> regionLuminances = [];
      
      // Divide image into 9 regions for more detailed analysis
      final regionWidth = image.width ~/ 3;
      final regionHeight = image.height ~/ 3;
      
      for (int regionX = 0; regionX < 3; regionX++) {
        for (int regionY = 0; regionY < 3; regionY++) {
          double regionLuminance = 0;
          int regionPixelCount = 0;
          
          for (int x = regionX * regionWidth; x < (regionX + 1) * regionWidth && x < image.width; x += 10) {
            for (int y = regionY * regionHeight; y < (regionY + 1) * regionHeight && y < image.height; y += 10) {
              final pixel = image.getPixel(x, y);
              final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
              regionLuminance += luminance;
              totalLuminance += luminance;
              regionPixelCount++;
              pixelCount++;
            }
          }
          
          if (regionPixelCount > 0) {
            regionLuminances.add(regionLuminance / regionPixelCount);
          }
        }
      }
      
      _lightLevel = totalLuminance / pixelCount;
      
      // Check lighting conditions and notify user
      _checkLightingConditions();
      
      // Calculate lighting quality score (0-100%)
      double lightingScore = 0.0;
      
      // Ideal lighting range: 0.3 to 0.7 (not too dark, not overexposed)
      if (_lightLevel >= 0.3 && _lightLevel <= 0.7) {
        lightingScore = 40.0; // Base score for good lighting
        
        // Bonus for even lighting (low standard deviation between regions)
        if (regionLuminances.length > 1) {
          final meanLuminance = regionLuminances.reduce((a, b) => a + b) / regionLuminances.length;
          final variance = regionLuminances.map((l) => pow(l - meanLuminance, 2)).reduce((a, b) => a + b) / regionLuminances.length;
          final stdDev = sqrt(variance);
          
          // Lower standard deviation = more even lighting = higher score
          if (stdDev < 0.1) {
            lightingScore += 20.0; // Excellent even lighting
          } else if (stdDev < 0.2) {
            lightingScore += 10.0; // Good even lighting
          }
        }
      } else if (_lightLevel >= 0.2 && _lightLevel < 0.3) {
        lightingScore = 20.0; // Slightly dark
      } else if (_lightLevel > 0.7 && _lightLevel <= 0.8) {
        lightingScore = 25.0; // Slightly bright
      } else {
        lightingScore = 5.0; // Poor lighting
      }
      
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector!.processImage(inputImage);
      
      double faceQualityScore = 0.0;
      
      if (faces.isNotEmpty) {
        final face = faces.first;
        
        // Face quality analysis with weighted scores
        double totalFaceScore = 0.0;
        int faceFactors = 0;
        
        // Factor 1: Face size and proportion (30% weight)
        final boundingBox = face.boundingBox;
        final faceArea = boundingBox.width * boundingBox.height;
        final imageArea = image.width * image.height;
        final faceAreaRatio = faceArea / imageArea;
        
        // Ideal face area: 15-30% of image
        double sizeScore = 0.0;
        if (faceAreaRatio >= 0.15 && faceAreaRatio <= 0.30) {
          sizeScore = 30.0; // Perfect size
        } else if (faceAreaRatio >= 0.10 && faceAreaRatio < 0.15) {
          sizeScore = 20.0; // Acceptable but small
        } else if (faceAreaRatio > 0.30 && faceAreaRatio <= 0.40) {
          sizeScore = 15.0; // Acceptable but large
        } else {
          sizeScore = 5.0; // Poor size
        }
        totalFaceScore += sizeScore;
        faceFactors++;
        
        // Factor 2: Face landmarks completeness (25% weight)
        final landmarks = face.landmarks;
        final requiredLandmarks = [
          FaceLandmarkType.leftEye,
          FaceLandmarkType.rightEye,
          FaceLandmarkType.noseBase,
          FaceLandmarkType.leftMouth,
          FaceLandmarkType.rightMouth,
        ];
        
        int detectedLandmarks = 0;
        for (final landmarkType in requiredLandmarks) {
          if (landmarks[landmarkType] != null) {
            detectedLandmarks++;
          }
        }
        
        final landmarkScore = (detectedLandmarks / requiredLandmarks.length) * 25.0;
        totalFaceScore += landmarkScore;
        faceFactors++;
        
        // Factor 3: Face alignment and rotation (25% weight)
        final headEulerAngleY = face.headEulerAngleY ?? 0.0;
        final headEulerAngleX = face.headEulerAngleX ?? 0.0;
        final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;
        
        double alignmentScore = 25.0; // Start with perfect score
        
        // Deduct points for rotation
        final totalRotation = headEulerAngleY.abs() + headEulerAngleX.abs() + headEulerAngleZ.abs();
        if (totalRotation <= 5.0) {
          alignmentScore = 25.0; // Perfect alignment
        } else if (totalRotation <= 15.0) {
          alignmentScore = 20.0; // Good alignment
        } else if (totalRotation <= 25.0) {
          alignmentScore = 12.0; // Acceptable alignment
        } else {
          alignmentScore = 5.0; // Poor alignment
        }
        totalFaceScore += alignmentScore;
        faceFactors++;
        
        // Factor 4: Face position in frame (20% weight)
        final faceCenterX = boundingBox.left + boundingBox.width / 2;
        final faceCenterY = boundingBox.top + boundingBox.height / 2;
        final imageCenterX = image.width / 2;
        final imageCenterY = image.height / 2;
        
        final horizontalOffset = (faceCenterX - imageCenterX).abs() / imageCenterX;
        final verticalOffset = (faceCenterY - imageCenterY).abs() / imageCenterY;
        
        double positionScore = 20.0;
        if (horizontalOffset <= 0.1 && verticalOffset <= 0.1) {
          positionScore = 20.0; // Perfectly centered
        } else if (horizontalOffset <= 0.2 && verticalOffset <= 0.2) {
          positionScore = 15.0; // Well centered
        } else if (horizontalOffset <= 0.3 && verticalOffset <= 0.3) {
          positionScore = 10.0; // Acceptable position
        } else {
          positionScore = 5.0; // Poor position
        }
        totalFaceScore += positionScore;
        faceFactors++;
        
        // Calculate final face quality score
        faceQualityScore = totalFaceScore;
        
        // Additional bonus for tracking ID (indicates stable detection)
        if (face.trackingId != null) {
          faceQualityScore += 5.0;
        }
        
      } else {
        faceQualityScore = 0.0;
      }
      
      // Final confidence calculation with weighted components
      double finalConfidence = 0.0;
      
      if (faceQualityScore > 0) {
        // Lighting contributes 40%, Face quality contributes 60%
        finalConfidence = (lightingScore * 0.4) + (faceQualityScore * 0.6);
        
        // Ensure confidence is within bounds and realistic
        finalConfidence = finalConfidence.clamp(0.0, 100.0);
        
        // Apply quality thresholds for realistic scoring
        if (finalConfidence >= 85.0) {
          // Excellent capture - adjust to 90-95% range
          finalConfidence = 90.0 + (finalConfidence - 85.0) * 0.5;
        } else if (finalConfidence >= 70.0) {
          // Good capture - adjust to 75-89% range
          finalConfidence = 75.0 + (finalConfidence - 70.0) * 0.7;
        } else if (finalConfidence >= 50.0) {
          // Acceptable capture - adjust to 50-74% range
          finalConfidence = 50.0 + (finalConfidence - 50.0) * 0.6;
        } else {
          // Poor capture - keep as is or slightly adjust
          finalConfidence = finalConfidence * 0.9;
        }
      } else {
        finalConfidence = 0.0;
      }
      
      // Final bounds check
      _faceDetectionConfidence = finalConfidence.clamp(0.0, 95.0); // Never show 100% - always room for improvement
      
      // Debug logging
      print('DEBUG CONFIDENCE ANALYSIS:');
      print('  Lighting Level: ${(_lightLevel * 100).toStringAsFixed(1)}%');
      print('  Lighting Score: ${lightingScore.toStringAsFixed(1)}%');
      print('  Face Quality Score: ${faceQualityScore.toStringAsFixed(1)}%');
      print('  Final Confidence: ${_faceDetectionConfidence.toStringAsFixed(1)}%');
      
      _accuracyReports.add({
        'timestamp': DateTime.now(),
        'light_level': _lightLevel,
        'confidence': _faceDetectionConfidence,
        'face_shape': _faceShape,
        'skin_tone': _skinTone,
        'lighting_score': lightingScore,
        'face_quality_score': faceQualityScore,
      });
      
    } catch (e) {
      print('Lighting analysis error: $e');
      _faceDetectionConfidence = 0.0;
      _lightLevel = 0.0;
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

  void _startFaceDetectionTimer() {
    _faceCheckTimer = Timer.periodic(const Duration(milliseconds: _minFrameIntervalMs), (timer) {
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

 void _checkFacePosition() async {
  if (_controller == null || 
      !_controller!.value.isInitialized || 
      _isProcessingFrame || 
      _isProcessing || 
      _capturedImage != null ||
      _isTakingPicture ||
      _hasCaptured ||
      _shouldSkipFrame) {
    return;
  }

  final now = DateTime.now();
  if (_lastFrameProcessTime != null && 
      now.difference(_lastFrameProcessTime!).inMilliseconds < _minFrameIntervalMs) {
    return;
  }

  try {
    _isProcessingFrame = true;
    _lastFrameProcessTime = now;
    
    final frame = await _controller!.takePicture();
    final inputImage = InputImage.fromFilePath(frame.path);
    final faces = await _faceDetector!.processImage(inputImage);
    
    unawaited(File(frame.path).delete());

    if (!mounted) return;

    setState(() {
      if (faces.isEmpty) {
        print("DEBUG: No face detected - WHITE");
        _isFaceDetected = false;
        _isFaceInFrame = false;
        _isFaceMoving = false;
        _isFaceCentered = false;
        _ovalColor = Colors.white;
        if (_isCountingDown) {
          _cancelCountdown();
        }
      } else {
        final face = faces.first;
        final faceRect = face.boundingBox;
        
        final isFaceCovered = _isFaceCovered(face);
        final isFaceInOval = _isFaceInOval(faceRect);
        final isCentered = isFaceCenteredInOval(faceRect);
        final isAligned = checkFaceAlignment(face);
        
        _isFaceDetected = true;
        _isFaceInFrame = isFaceInOval && !isFaceCovered;
        
        _checkFaceStability(faceRect);
        _isFaceMoving = !_isFaceStable;
        
        _isFaceCentered = isCentered && isAligned && !isFaceCovered && _isFaceStable;
        
        print("DEBUG: FaceInOval: $isFaceInOval, Centered: $isCentered, Aligned: $isAligned, Stable: $_isFaceStable, Moving: $_isFaceMoving");
        
        // ✅ UPDATED: Clear color logic
        if (!_isFaceInFrame) {
          print("DEBUG: Setting RED - Face detected but not in oval frame");
          _ovalColor = Colors.red;
          if (_isCountingDown) {
            _cancelCountdown();
          }
        } 
        else if (_isFaceMoving) {
          print("DEBUG: Setting ORANGE - Face moving");
          _ovalColor = Colors.orange;
          if (_isCountingDown) {
            _cancelCountdown();
          }
        }
        else if (!_isFaceCentered) {
          print("DEBUG: Setting RED - Face in frame but not centered/aligned");
          _ovalColor = Colors.red;
          if (_isCountingDown) {
            _cancelCountdown();
          }
        }
        else if (_isFaceCentered) {
          print("DEBUG: Setting GREEN - Perfect position");
          _ovalColor = Colors.green;
          if (!_isCountingDown && !_hasCaptured) {
            _startCountdown();
          }
        }
        else {
          print("DEBUG: Setting WHITE - Fallback");
          _ovalColor = Colors.white;
          if (_isCountingDown) {
            _cancelCountdown();
          }
        }
      }
    });
  } catch (e) {
    print('Face detection error: $e');
    if (mounted) {
      setState(() {
        _isFaceStable = false;
        _ovalColor = Colors.white;
        if (_isCountingDown) {
          _cancelCountdown();
        }
      });
    }
  } finally {
    _isProcessingFrame = false;
  }
}

  bool isFaceGoodEnough(Face face, Rect faceRect) {
    if (_isFaceCovered(face)) {
      return false;
    }

    final isRoughlyInOval = _isFaceInOval(faceRect);
    final isRoughlyCentered = isFaceCenteredInOval(faceRect);
    final isRoughlyAligned = checkFaceAlignment(face);
    final isSomewhatStable = _checkQuickStability(faceRect);

    return isRoughlyInOval && isRoughlyAligned;
  }

  bool _checkQuickStability(Rect currentPosition) {
    if (_lastFacePosition == null) {
      _lastFacePosition = currentPosition;
      _lastFaceMovementTime = DateTime.now();
      return false;
    }

    final dx = (currentPosition.left - _lastFacePosition!.left).abs() / _lastFacePosition!.width;
    final dy = (currentPosition.top - _lastFacePosition!.top).abs() / _lastFacePosition!.height;
    final movement = sqrt(dx * dx + dy * dy); 

    return movement <= 0.08;
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
    final dw = (currentPosition.width - _lastFacePosition!.width).abs() / _lastFacePosition!.width;
    final dh = (currentPosition.height - _lastFacePosition!.height).abs() / _lastFacePosition!.height;
    
    final movement = sqrt(dx * dx + dy * dy + dw * dw + dh * dh);

    if (movement > _stabilityThreshold * 0.7) {
      _lastFacePosition = currentPosition;
      _lastFaceMovementTime = now;
      _isFaceStable = false;
      print("DEBUG: Movement detected: $movement");
    } else if (_lastFaceMovementTime != null && 
              now.difference(_lastFaceMovementTime!).inMilliseconds > _stabilityDurationMs) {
      _isFaceStable = true;
      print("DEBUG: Face is now stable");
    }

    _lastFacePosition = currentPosition;
  }

  Rect _getAdjustedFaceRect(Rect faceRect) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return faceRect;
    }

    final screenSize = MediaQuery.of(_scaffoldContext).size;
    final previewSize = _controller!.value.previewSize!;

    if (_isUsingFrontCamera) {
      final scaleX = screenSize.width / previewSize.height;
      final scaleY = screenSize.height / previewSize.width;
      
      final mirroredLeft = previewSize.height - faceRect.right;
      
      return Rect.fromLTRB(
        mirroredLeft * scaleX,
        faceRect.top * scaleY,
        (mirroredLeft + faceRect.width) * scaleX,
        (faceRect.top + faceRect.height) * scaleY,
      );
    } else {
      final scaleX = screenSize.width / previewSize.height;
      final scaleY = screenSize.height / previewSize.width;
      
      final rotatedTop = faceRect.left;
      final rotatedLeft = previewSize.height - faceRect.bottom;
      final rotatedWidth = faceRect.height;
      final rotatedHeight = faceRect.width;
      
      return Rect.fromLTRB(
        rotatedLeft * scaleX,
        rotatedTop * scaleY,
        (rotatedLeft + rotatedWidth) * scaleX,
        (rotatedTop + rotatedHeight) * scaleY,
      );
    }
  }

  bool _isFaceInOval(Rect faceRect) {
    final screenSize = MediaQuery.of(_scaffoldContext).size;
    final ovalCenter = Offset(screenSize.width / 2, screenSize.height * 0.4);
    final ovalWidth = screenSize.width * 0.75;
    final ovalHeight = screenSize.height * 0.45;

    final adjustedFaceRect = _getAdjustedFaceRect(faceRect);

    final faceSizeRatio = adjustedFaceRect.width / ovalWidth;
    if (faceSizeRatio < 0.4 || faceSizeRatio > 0.9) {
      return false;
    }

    final faceCenter = Offset(
      adjustedFaceRect.left + adjustedFaceRect.width / 2,
      adjustedFaceRect.top + adjustedFaceRect.height / 2,
    );

    final normalizedX = pow((faceCenter.dx - ovalCenter.dx) / (ovalWidth / 2), 2);
    final normalizedY = pow((faceCenter.dy - ovalCenter.dy) / (ovalHeight / 2), 2);

    return (normalizedX + normalizedY) <= 1.3; 
  }

  bool isFaceCenteredInOval(Rect faceRect) {
    final screenSize = MediaQuery.of(_scaffoldContext).size;
    final ovalCenter = Offset(screenSize.width / 2, screenSize.height * 0.4);
    final ovalWidth = screenSize.width * 0.75;
    final ovalHeight = screenSize.height * 0.45;

    final adjustedFaceRect = _getAdjustedFaceRect(faceRect);
    final faceCenter = Offset(
      adjustedFaceRect.left + adjustedFaceRect.width / 2,
      adjustedFaceRect.top + adjustedFaceRect.height / 2,
    );

    final dx = (faceCenter.dx - ovalCenter.dx).abs();
    final dy = (faceCenter.dy - ovalCenter.dy).abs();
    final xTolerance = ovalWidth * 0.2;
    final yTolerance = ovalHeight * 0.2;
    final isCentered = dx <= xTolerance && dy <= yTolerance;
    
    return isCentered;
  }

  bool _isFaceCovered(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];

    if (leftEye == null || rightEye == null || noseBase == null) {
      return true;
    }
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < 0.2 || face.rightEyeOpenProbability! < 0.2) {
        return true;
      }
    }

    return false;
  }

  bool checkFaceAlignment(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleX = face.headEulerAngleX ?? 0.0;

    if (headEulerAngleY.abs() > 20.0 || headEulerAngleX.abs() > 20.0) {
      return false;
    }

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];

    return leftEye != null && rightEye != null && noseBase != null;
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

      final ResolutionPreset preset = _getBestResolutionPreset(selectedCamera);
      
      _controller = CameraController(
        selectedCamera,
        preset,
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

  ResolutionPreset _getBestResolutionPreset(CameraDescription camera) {
    return ResolutionPreset.high;
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
      if (cameraAspectRatio > screenAspectRatio) {
        final scale = screenSize.height / (screenSize.width / cameraAspectRatio);
        return Matrix4.diagonal3Values(-1.0, scale, 1.0); 
      } else {
        final scale = screenSize.width / (screenSize.height * cameraAspectRatio);
        return Matrix4.diagonal3Values(-scale, 1.0, 1.0); 
      }
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
    _cancelCountdown();

    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
      _showResults = false;
      _capturedImage = null;
      _lastFacePosition = null;
      _lastFaceMovementTime = null;
      _isFaceStable = false;
      _ovalColor = Colors.white; 
      _hasCaptured = false; 
    });
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _autoCapturePicture() async {
    _cancelCountdown();

    if (_isTakingPicture || _hasCaptured || _isProcessingFrame) return;

    try {
      if (_userEmail == null || _userEmail!.isEmpty) {
        throw Exception('Please login first to use this feature');
      }

      setState(() {
        _isTakingPicture = true; 
        _isProcessing = true;
        _showResults = false;
        _capturedImage = null;
        _hasCaptured = true; 
      });
      
      await _initializeControllerFuture;
      if (_controller == null || !_controller!.value.isInitialized) return;

      _shouldSkipFrame = true;
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      final processedImage = await _processImageForAI(imageFile);
      
      // Save the captured image path to SharedPreferences
      await _saveCapturedImagePath(processedImage.path);
      
      setState(() {
        _capturedImage = processedImage;
      });
      
      await _analyzeImage(processedImage);
      
    } catch (e) {
      print("Auto capture error: $e");
      _handleApiError(e); // Use improved error handling
    } finally {
      _shouldSkipFrame = false;
      if (mounted) {
        setState(() {
          _isTakingPicture = false; 
          _isProcessing = false;
          _hasCaptured = false; // Reset capture state on error
        });
      }
    }
  }

  // New method to save captured image path to SharedPreferences
  Future<void> _saveCapturedImagePath(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_captured_image_path', imagePath);
      print('DEBUG: Saved captured image path to SharedPreferences: $imagePath');
    } catch (e) {
      print('Error saving captured image path: $e');
    }
  }

  Future<File> _processImageForAI(File originalImage) async {
    try {
      final originalBytes = await originalImage.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);
      
      if (image == null) {
        return originalImage;
      }
      
      if (_isUsingFrontCamera) {
        image = img.flipHorizontal(image);
      }
      
        const targetWidth = 1152;
        const targetHeight = 2048;
      
      final resizedImage = img.copyResize(
        image, 
        width: targetWidth, 
        height: targetHeight,
        interpolation: img.Interpolation.linear
      );
      
      final processedBytes = img.encodeJpg(resizedImage, quality: 90);
      
      final processedFile = File(originalImage.path.replaceFirst('.jpg', '_processed.jpg'));
      await processedFile.writeAsBytes(processedBytes);
      
      await originalImage.delete();
      
      return processedFile;
    } catch (e) {
      print('Error processing image for AI: $e');
      return originalImage;
    }
  }

 Future<void> _analyzeImage(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
        _showResults = false;
      });

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

        // Improved handling for no face shape/skin tone detection
        if (jsonResponse['face_shape'] == null || jsonResponse['skin_tone'] == null) {
          setState(() {
            _isLoading = false;
            _showResults = true;
            _faceShape = "Not detected";
            _skinTone = "Not detected";
          });
          
          _showUserNotification(
            'No face shape detected\nTry again with better lighting',
            duration: Duration(seconds: 5)
          );
          return;
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
                        color: Colors.pink.withValues(alpha: 0.2),
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
                    ]
                ),
              ));
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
      _handleApiError(e); // Use improved error handling
    }
  }

  Widget _getStatusText(double screenWidth) {
    if (_ovalColor == Colors.white) {
      return Text(
        'No Face Detected',
        key: const ValueKey('status_white'),
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
    } else if (_ovalColor == Colors.red) {
      return Text(
        'Center Your Face',
        key: const ValueKey('status_red'),
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
    } else if (_ovalColor == Colors.orange) {
      return Text(
        'Hold Still',
        key: const ValueKey('status_orange'),
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
    } else {
      return Text(
        'Perfect! Get ready to capture your face',
        key: const ValueKey('status_green'),
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
    }
  }

  String _getStatusMessage() {
    if (_ovalColor == Colors.white) {
      return 'Position your face in the oval';
    } else if (_ovalColor == Colors.red) {
      return 'Center and align your face properly in the oval';
    } else if (_ovalColor == Colors.orange) {
      return 'Stay still for automatic capture';
    } else {
      return 'Perfect position! Photo will be taken automatically';
    }
  }

  // Helper methods for elegant notification formatting
  String _getNotificationTitle(String fullMessage) {
    if (fullMessage.contains('\n')) {
      return fullMessage.split('\n')[0];
    }
    return 'Face Detection';
  }

  String _getNotificationMessage(String fullMessage) {
    if (fullMessage.contains('\n')) {
      return fullMessage.split('\n')[1];
    }
    return fullMessage;
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldContext = context;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: _handleVerticalDragEnd,
          onTap: _handleTapToDismissWarning,
          child: Stack(
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
                        Transform(
                          alignment: Alignment.center,
                          transform: _isUsingFrontCamera
                              ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0)) 
                              : Matrix4.identity(),
                          child: CameraPreview(_controller!),
                        ),
                        Positioned.fill(
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
                              screenHeight: screenHeight,
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
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                        left: 20,
                        right: 20,
                        child: Material(
                          type: MaterialType.transparency,
                          child: _buildResultsPanel(),
                        ),
                      ),
                  ],
                ),

             // UPDATED: Simple elegant notification banner placed slightly lower
if (_showNotification && _currentNotification != null)
  Positioned(
    top: MediaQuery.of(context).padding.top + screenHeight * 0.15, // Changed from 0.12 to 0.15
    left: 20,
    right: 20,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getNotificationTitle(_currentNotification!),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _getNotificationMessage(_currentNotification!),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.white, size: 16),
            onPressed: () {
              setState(() {
                _showNotification = false;
                _currentNotification = null;
              });
              _notificationTimer?.cancel();
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30),
          ),
        ],
      ),
    ),
  ),

              if (_showWarningMessage && _capturedImage == null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.pink.shade300,
                                    Colors.purple.shade300,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.face_retouching_natural,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            Text(
                              "For Best Results",
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 10),
                            
                            Text(
                              "Please ensure the following:",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildRequirementItem(
                                    Icons.face,
                                    "Position Face in Oval",
                                    "Simply position your face in the oval - it will capture automatically",
                                    screenWidth,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildRequirementItem(
                                     Icons.block,
                                    "No Eyeglasses",
                                    "Remove glasses for accurate detection",
                                    screenWidth,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildRequirementItem(
                                    Icons.face_2,
                                    "Hair Tied Back",
                                    "Keep hair away from your face",
                                    screenWidth,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildRequirementItem(
                                    Icons.lightbulb,
                                    "Well-Lit Environment",
                                    "Good lighting ensures better accuracy",
                                    screenWidth,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(seconds: 2),
                              child: Text(
                                "Tap anywhere or wait 5 seconds to continue",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                              height: 4,
                              width: screenWidth * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Stack(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 100),
                                        curve: Curves.linear,
                                        width: constraints.maxWidth * (_showWarningMessage ? 1.0 : 0.0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink.shade400,
                                              Colors.purple.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_capturedImage == null && !_showWarningMessage)
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 20,
                        left: 16,
                      ),
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.flip_camera_android, 
                                   color: Colors.white, 
                                   size: screenWidth * 0.08),
                        onPressed: _isProcessing ? null : _switchCamera,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.01),
                      child: Text(
                        "Position your face in the oval - it will capture automatically",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              else if (_capturedImage != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Your Captured Photo",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.070,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_capturedImage == null && !_showWarningMessage)
                Positioned(
                  bottom: screenHeight * 0.08,
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _ovalColor.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _getStatusText(screenWidth),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Detailed Status:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          '• Detected: $_isFaceDetected',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          '• In Frame: $_isFaceInFrame',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          '• Stable: $_isFaceStable',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          '• Centered: $_isFaceCentered',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          '• Moving: $_isFaceMoving',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          _getStatusMessage(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: screenWidth * 0.03,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String description, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: screenWidth * 0.06,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
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
              color: Colors.pink.withValues(alpha: 0.3),
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
                  // This will now work because the image path is saved in SharedPreferences
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
            SizedBox(height: MediaQuery.of(_scaffoldContext).padding.bottom),
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
  final double? screenHeight;

  const DashedOvalPainter({
    this.ovalColor = Colors.white,
    this.countdownSeconds,
    this.isCountingDown = false,
    this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width * 0.75;
    final double height = size.height * 0.45;
    
    final double verticalPosition = 0.43;
    final Offset center = Offset(size.width / 2, size.height * verticalPosition);
    
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
                color: Colors.black.withValues(alpha: 0.5),
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
      
      paint.color = Colors.white.withValues(alpha: opacity);
      if (random.nextBool()) {
        paint.color = Colors.pink.shade200.withValues(alpha: opacity);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}