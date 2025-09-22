import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'camera2.dart';
import 'glamvault.dart';
import 'package:toastification/toastification.dart';

// Face Landmark detector
class FaceLandmarkHelper {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    ),
  );

  static Future<List<Face>> detectFaces(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      throw Exception('Face detection failed: $e');
    }
  }

  static void dispose() => _faceDetector.close();
}

// Makeup Overlay Engine with synchronized application
class MakeupOverlayEngine {
  static Future<Uint8List> applyMakeup({
    required File imageFile,
    required Map<String, Color?> selectedShades,
  }) async {
    try {
      final faces = await FaceLandmarkHelper.detectFaces(imageFile);
      if (faces.isEmpty) throw Exception('No faces detected');

      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes)!;
      
      // Create unified makeup overlay
      final overlay = await _createUnifiedMakeupOverlay(
        originalImage.width,
        originalImage.height,
        faces,
        selectedShades,
      );

      // Apply the overlay with soft light blend
      img.compositeImage(
        originalImage,
        img.decodeImage(overlay)!,
        blend: img.BlendMode.softLight,
      );

      return Uint8List.fromList(img.encodePng(originalImage));
    } catch (e) {
      throw Exception('Makeup application failed: $e');
    }
  }

  static Future<Uint8List> _createUnifiedMakeupOverlay(
    int width,
    int height,
    List<Face> faces,
    Map<String, Color?> selectedShades,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    for (final face in faces) {
      final landmarks = face.landmarks;
      
      // Apply all makeup components in sync
      _applySynchronizedMakeup(canvas, landmarks, selectedShades);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _applySynchronizedMakeup(
    Canvas canvas,
    Map<FaceLandmarkType, FaceLandmark?> landmarks, // Changed to accept nullable FaceLandmark
    Map<String, Color?> selectedShades,
  ) {
    // Eyeshadow
    if (selectedShades['Eyeshadow'] != null && 
        landmarks[FaceLandmarkType.leftEye] != null && 
        landmarks[FaceLandmarkType.rightEye] != null) {
      _drawEyeMakeup(
        canvas,
        landmarks[FaceLandmarkType.leftEye]!.position, // Use ! to assert non-null
        isLeftEye: true,
        color: selectedShades['Eyeshadow']!,
      );
      
      _drawEyeMakeup(
        canvas,
        landmarks[FaceLandmarkType.rightEye]!.position, // Use ! to assert non-null
        isLeftEye: false,
        color: selectedShades['Eyeshadow']!,
      );
    }

    // Lipstick
    if (selectedShades['Lipstick'] != null && 
        landmarks[FaceLandmarkType.bottomMouth] != null) {
      _drawLipMakeup(
        canvas,
        landmarks[FaceLandmarkType.bottomMouth]!.position, // Use ! to assert non-null
        color: selectedShades['Lipstick']!,
      );
    }

    // Blush
    if (selectedShades['Blush'] != null &&
        landmarks[FaceLandmarkType.leftCheek] != null &&
        landmarks[FaceLandmarkType.rightCheek] != null) {
      _drawBlush(
        canvas,
        landmarks[FaceLandmarkType.leftCheek]!.position, 
        landmarks[FaceLandmarkType.rightCheek]!.position, 
        color: selectedShades['Blush']!,
      );
    }
  }

  static void _drawEyeMakeup(
    Canvas canvas,
    Point<int> eyePosition,
    {
      required bool isLeftEye,
      required Color color,
    }
  ) {
    final eyeCenter = Offset(eyePosition.x.toDouble(), eyePosition.y.toDouble());
    
    // Base layer
    final basePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12);
    
    final baseRect = Rect.fromCenter(
      center: eyeCenter,
      width: 70,
      height: 35,
    );
    
    final translatedRect = isLeftEye 
        ? baseRect.translate(-12, 0) 
        : baseRect.translate(12, 0);
    
    canvas.drawOval(translatedRect, basePaint);
    
    // Intensity layer
    final intensityPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final intensityRect = Rect.fromCenter(
      center: eyeCenter,
      width: 50,
      height: 25,
    );
    
    final translatedIntensityRect = isLeftEye 
        ? intensityRect.translate(-8, 0) 
        : intensityRect.translate(8, 0);
    
    canvas.drawOval(translatedIntensityRect, intensityPaint);
    
    // Definition layer
    final definitionPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    final definitionRect = Rect.fromCenter(
      center: Offset(eyeCenter.dx, eyeCenter.dy - 5),
      width: 30,
      height: 15,
    );
    
    final translatedDefinitionRect = isLeftEye 
        ? definitionRect.translate(-5, 0) 
        : definitionRect.translate(5, 0);
    
    canvas.drawOval(translatedDefinitionRect, definitionPaint);
  }

  static void _drawLipMakeup(
    Canvas canvas,
    Point<int> bottomMouth,
    {
      required Color color,
    }
  ) {
    final lipCenter = Offset(
      bottomMouth.x.toDouble(), 
      bottomMouth.y.toDouble() - 10
    );
    
    // Base layer
    final basePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 8);
    
    final baseRect = Rect.fromCenter(
      center: lipCenter,
      width: 75,
      height: 50,
    );
    
    canvas.drawOval(baseRect, basePaint);
    
    // Intensity layer
    final intensityPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final intensityRect = Rect.fromCenter(
      center: lipCenter,
      width: 60,
      height: 30,
    );
    
    canvas.drawOval(intensityRect, intensityPaint);
    
    // Definition layer
    final definitionPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    final upperLipRect = Rect.fromCenter(
      center: Offset(lipCenter.dx, lipCenter.dy - 8),
      width: 50,
      height: 30,
    );
    
    canvas.drawOval(upperLipRect, definitionPaint);
  }

  static void _drawBlush(
    Canvas canvas,
    Point<int> leftCheek,
    Point<int> rightCheek,
    {
      required Color color,
    }
  ) {
    final leftBlushPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15);
  
    final rightBlushPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15);

    // First layer
    canvas.drawCircle(
      Offset(
        leftCheek.x.toDouble() - 12,
        leftCheek.y.toDouble() - 10,
      ),
      40,
      leftBlushPaint,
    );
    
    canvas.drawCircle(
      Offset(
        rightCheek.x.toDouble() + 12,
        rightCheek.y.toDouble() - 10,
      ),
      40,
      rightBlushPaint,
    );

    // Second layer
    final leftCenterPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    final rightCenterPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(
      Offset(
        leftCheek.x.toDouble() - 12,
        leftCheek.y.toDouble() - 10,
      ),
      30,
      leftCenterPaint,
    );
    
    canvas.drawCircle(
      Offset(
        rightCheek.x.toDouble() + 12,
        rightCheek.y.toDouble() - 10,
      ),
      30, 
      rightCenterPaint,
    );
  }
}

// API makeup service
class MakeupOverlayApiService {
  Future<Map<String, dynamic>> applyMakeup({
    required File imageFile,
    required Map<String, Color?> selectedShades,
    required String skinTone,
    required String undertone,
    required String makeupLook,
    required String makeupType,
  }) async {
    try {
      final apiResponse = await _callMakeupApi(
        imageFile,
        selectedShades,
        skinTone,
        undertone,
        makeupLook,
        makeupType,
      );
      
      if (apiResponse != null) return apiResponse;
      return await _applyLocalMakeup(
        imageFile: imageFile,
        selectedShades: selectedShades,
      );
    } catch (e) {
      debugPrint('Makeup application failed: $e');
      return await _mockApplyMakeup(
        imageFile: imageFile,
        selectedShades: selectedShades,
      );
    }
  }

  Future<Map<String, dynamic>?> _callMakeupApi(
    File imageFile,
    Map<String, Color?> selectedShades,
    String skinTone,
    String undertone,
    String makeupLook,
    String makeupType,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Convert selected shades to hex codes
      final Map<String, String> shadeHexCodes = {};
      selectedShades.forEach((product, color) {
        if (color != null) {
          shadeHexCodes[product] = '#${color.value.toRadixString(16).substring(2)}';
        }
      });

      final response = await http.post(
        Uri.parse('https://glamouraika.com/api/apply-makeup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Encode(bytes),
          'user_input': {
            'skin_tone': skinTone,
            'undertone': undertone,
            'makeup_look': makeupLook,  
            'makeup_type': makeupType,
            'selected_shades': shadeHexCodes,
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<Map<String, dynamic>> _applyLocalMakeup({
    required File imageFile,
    required Map<String, Color?> selectedShades,
  }) async {
    try {
      final result = await MakeupOverlayEngine.applyMakeup(
        imageFile: imageFile,
        selectedShades: selectedShades,
      );

      return {
        'status': 'success',
        'message': 'Makeup applied locally',
        'result_image': base64Encode(result),
      };
    } catch (e) {
      throw Exception('Local makeup failed: $e');
    }
  }

  Future<Map<String, dynamic>> _mockApplyMakeup({
    required File imageFile,
    required Map<String, Color?> selectedShades,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return {
      'status': 'success',
      'message': 'Mock makeup applied',
      'result_image': base64Encode(bytes),
    };
  }
}

// Hex Color Helper
class HexColor extends Color {
  HexColor(String hexColor) : super(_parseHex(hexColor));

  static int _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}

// Customization Page
class CustomizationPage extends StatefulWidget {
  final File capturedImage;
  final String? selectedMakeupType;
  final String? selectedMakeupLook;
  final String userId;
  final String undertone;
  final String? skinTone;
  final Map<String, dynamic>? recommendationData;

  const CustomizationPage({
    super.key,
    required this.capturedImage,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
    required this.userId,
    required this.undertone,
    this.skinTone,
    this.recommendationData,
  });

  @override
  _CustomizationPageState createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> with SingleTickerProviderStateMixin {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;
  bool isLoading = false;
  bool isSaved = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = true;
  Map<String, bool> expandedProducts = {};
  late MakeupOverlayApiService _makeupApiService;
  bool _isApplyingMakeup = false;
  Uint8List? _processedImage;
  Uint8List? _currentMakeupImage;
  bool _hasShownCustomizationDialog = false;
  bool _isFirstTimeSelection = true;
  bool _isResetting = false;
  bool _userChoseToCustomize = false;

  Map<String, Color?> selectedShades = {
    'Foundation': null,
    'Concealer': null,
    'Contour': null,
    'Eyeshadow': null,
    'Blush': null,
    'Lipstick': null,
    'Highlighter': null,
    'Eyebrow': null,
  };

  Map<String, List<Color>> makeupShades = {};
  Map<String, List<String>> shadeHexCodes = {};
  final Map<String, bool> _hasShownProductDialog = {};

  final Map<String, String> productIcons = {
    'Foundation': 'assets/foundation.png',
    'Concealer': 'assets/concelear.png',
    'Contour': 'assets/contour.png',
    'Eyeshadow': 'assets/eyeshadow.png',
    'Blush': 'assets/blush.png',
    'Lipstick': 'assets/lipstick.png',
    'Highlighter': 'assets/highlighter.png',
    'Eyebrow': 'assets/eyebrow.png',
  };

  final List<String> orderedProductNames = [
    'Foundation',
    'Concelear',
    'Contour',
    'Eyeshadow',
    'Blush',
    'Lipstick',
    'Highlighter',
    'Eyebrow',
  ];

  final String? _apiToken = null;

  @override
  void initState() {
    super.initState();
    _makeupApiService = MakeupOverlayApiService();
    _processRecommendationData();
    _fetchRecommendations();
    
    for (var product in orderedProductNames) {
      expandedProducts[product] = false;
      _hasShownProductDialog[product] = false;
    }

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _heartAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.08),
          weight: 50,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.1, end: 1.0),
          weight: 50,
        ),
      ],
    ).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _applyVirtualMakeup() async {
    final previousImage = _processedImage;
    
    setState(() => _isApplyingMakeup = true);

    try {
      final response = await _makeupApiService.applyMakeup(
        imageFile: widget.capturedImage,
        selectedShades: selectedShades,
        skinTone: widget.skinTone ?? 'medium',
        undertone: widget.undertone,
        makeupLook: widget.selectedMakeupLook ?? 'natural',
        makeupType: widget.selectedMakeupType ?? 'everyday',
      );

      setState(() {
        _processedImage = base64Decode(response['result_image']);
        _currentMakeupImage = _processedImage;
        
        if (response['status'] == 'success' && response['message']?.contains('Mock') == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      });
    } catch (e) {
      setState(() {
        _processedImage = previousImage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying makeup: $e')),
      );
    } finally {
      setState(() => _isApplyingMakeup = false);
    }
  }

  Future<void> _applyVirtualMakeupAutomatically(Map<String, dynamic> recommendations) async {
    setState(() => _isApplyingMakeup = true);

    try {
      // Apply all recommended shades at once
      final Map<String, Color?> autoSelectedShades = {};
      
      recommendations.forEach((category, shadeMap) {
        if (shadeMap is Map && shadeMap.containsKey('Primary')) {
          final hexCode = shadeMap['Primary'] as String;
          autoSelectedShades[category] = _parseHexColor(hexCode);
        }
      });

      final response = await _makeupApiService.applyMakeup(
        imageFile: widget.capturedImage,
        selectedShades: autoSelectedShades,
        skinTone: widget.skinTone ?? 'medium',
        undertone: widget.undertone,
        makeupLook: widget.selectedMakeupLook ?? 'natural',
        makeupType: widget.selectedMakeupType ?? 'everyday',
      );

      setState(() {
        _processedImage = base64Decode(response['result_image']);
        
        if (response['status'] == 'success' && response['message']?.contains('Mock') == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying makeup automatically: $e')),
      );
    } finally {
      setState(() => _isApplyingMakeup = false);
    }
  }

  Future<void> _resetVirtualMakeup() async {
    setState(() {
      _isResetting = true;
    });

    try {
      // Clear manual selections
      selectedShades.updateAll((key, value) => null);
      
      // Re-apply AI recommendations
      final Map<String, Color?> aiShades = {};
      shadeHexCodes.forEach((product, hexCodes) {
        if (hexCodes.isNotEmpty) {
          aiShades[product] = _parseHexColor(hexCodes[0]);
        }
      });

      final response = await _makeupApiService.applyMakeup(
        imageFile: widget.capturedImage,
        selectedShades: aiShades,
        skinTone: widget.skinTone ?? 'medium',
        undertone: widget.undertone,
        makeupLook: widget.selectedMakeupLook ?? 'natural',
        makeupType: widget.selectedMakeupType ?? 'everyday',
      );

      setState(() {
        _processedImage = base64Decode(response['result_image']);
        _currentMakeupImage = _processedImage;
        _userChoseToCustomize = false;
      });
    } catch (e) {
      setState(() {
        _processedImage = null;
        _currentMakeupImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting to AI recommendations: $e')),
      );
    } finally {
      setState(() => _isResetting = false);
    }
  }

  void _processRecommendationData() {
    if (widget.recommendationData != null) {
      final recommendations = widget.recommendationData!['recommendations'] as Map<String, dynamic>?;
      if (recommendations != null) {
        setState(() {
          makeupShades.clear();
          shadeHexCodes.clear();
          recommendations.forEach((category, shadeMap) {
            if (shadeMap is Map) {
              shadeHexCodes[category] = [];
              makeupShades[category] = [];
              
              if (shadeMap.containsKey('Primary')) {
                final hexCode = shadeMap['Primary'] as String;
                shadeHexCodes[category]!.add(hexCode);
                makeupShades[category]!.add(_parseHexColor(hexCode));
              }
              
              final shadeTypes = ['Light', 'Medium', 'Dark'];
              for (var shadeType in shadeTypes) {
                if (shadeMap.containsKey(shadeType)) {
                  final hexCode = shadeMap[shadeType] as String;
                  if (!shadeHexCodes[category]!.contains(hexCode)) {
                    shadeHexCodes[category]!.add(hexCode);
                    makeupShades[category]!.add(_parseHexColor(hexCode));
                  }
                }
              }
            }
          });
        });
      }
    }
  }

  Color _parseHexColor(String hexColor) {
    try {
      if (!RegExp(r'^#[0-9A-Fa-f]{6,8}$').hasMatch(hexColor)) {
        return Colors.transparent;
      }
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.transparent;
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('https://glamouraika.com/api/recommendation');
      final headers = {
        'Content-Type': 'application/json',
        if (_apiToken != null) 'Authorization': 'Bearer $_apiToken',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'user_id': widget.userId,
          'undertone': widget.undertone,
          'makeup_type': widget.selectedMakeupType,
          'makeup_look': widget.selectedMakeupLook,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final recommendations = data['recommendations'] as Map<String, dynamic>?;

        if (recommendations == null) {
          throw Exception('Invalid API response: missing recommendations');
        }

        setState(() {
          makeupShades.clear();
          shadeHexCodes.clear();
          recommendations.forEach((category, shadeMap) {
            if (shadeMap is Map) {
              if (shadeMap.containsKey('Primary')) {
                final hexCode = shadeMap['Primary'] as String;
                shadeHexCodes[category] = [hexCode];
                makeupShades[category] = [_parseHexColor(hexCode)];
              }
              
              final shadeTypes = ['Light', 'Medium', 'Dark'];
              for (var shadeType in shadeTypes) {
                if (shadeMap.containsKey(shadeType)) {
                  final hexCode = shadeMap[shadeType] as String;
                  shadeHexCodes[category]?.add(hexCode);
                  makeupShades[category]?.add(_parseHexColor(hexCode));
                }
              }
            }
          });
        });
      
        await _applyVirtualMakeupAutomatically(recommendations);
      
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] == 'User profile incomplete') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete your profile first')),
          );
        } else if (errorData['message'] == 'Missing required fields') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing required information')),
          );
        }
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      } else if (response.statusCode == 503) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Makeup recommendation service is currently unavailable')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: ${response.statusCode}')),
        );
      }
    }  catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recommendations: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> compressAndEncodeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (imageFile.path.toLowerCase().endsWith('.jpg') || 
          imageFile.path.toLowerCase().endsWith('.jpeg')) {
        return base64Encode(bytes);
      }
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');
      final compressed = img.encodeJpg(image, quality: 85);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Image processing error: $e');
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    }
  }

  Future<void> _saveLook() async {
  if (widget.selectedMakeupLook == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No makeup look selected')),
    );
    return;
  }

  // Check if user chose to customize but didn't select any shades
  if (_userChoseToCustomize && !_hasSelectedShades()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one shade to customize your look or click Reset to use AI recommendations')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    Map<String, List<String>> labeledShades = {};
    
    // Check if user selected any shades manually
    bool hasManualSelections = selectedShades.values.any((color) => color != null);
    
    if (hasManualSelections) {
      // Use manually selected shades
      selectedShades.forEach((productType, color) {
        if (color != null) {
          String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
          labeledShades[productType] = [hexColor];
        }
      });
    } else {
      // AUTOMATICALLY USE AI-RECOMMENDED SHADES (big circle ones)
      shadeHexCodes.forEach((productType, hexCodes) {
        if (hexCodes.isNotEmpty) {
          // Use the primary (recommended) shade which is the first one (big circle)
          labeledShades[productType] = [hexCodes[0]];
          
          // Also update selectedShades to reflect this for visual consistency
          if (makeupShades.containsKey(productType) && makeupShades[productType]!.isNotEmpty) {
            selectedShades[productType] = makeupShades[productType]![0];
          }
        }
      });
    }

    final imageBytes = await (_processedImage != null 
        ? Future.value(_processedImage!) 
        : widget.capturedImage.readAsBytes());
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse('https://glamouraika.com/api/saved_looks');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'makeup_look': widget.selectedMakeupLook,
        'shades': labeledShades,
        'image_data': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        isSaved = true;
      });

      await _cacheSavedLook(
        responseData['saved_look_id'],
        widget.selectedMakeupLook!,
        base64Image,
        labeledShades,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Look saved ${hasManualSelections ? 'with custom shades' : 'with AI recommendations'}')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GlamVaultScreen(userId: int.parse(widget.userId)),
        ),
      );
    } else {
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save look: ${errorData['error'] ?? 'Unknown error'}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving look: $e')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  // Helper method to check if any shades are selected
  bool _hasSelectedShades() {
    return selectedShades.values.any((color) => color != null);
  }

  Future<void> _cacheSavedLook(
    dynamic lookId, 
    String lookName, 
    String imageData,
    Map<String, dynamic> shades
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('look_image_$lookId', imageData);
    
    await prefs.setString('cached_look_$lookId', jsonEncode({
      'saved_look_id': lookId,
      'makeup_look_name': lookName,
      'image_data': imageData,
      'shades': shades,
    }));
  }

  Widget makeupOverlay(Color shade, double left, double top, double width, double height, double opacity) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: shade.withOpacity(opacity),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildProductIcon(String productName) {
  final iconPath = productIcons[productName];
  return iconPath != null
      ? Image.asset(
          iconPath,
          width: 45,
          height: 45,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.help_outline, size: 45, color: Colors.pink[300]);
          },
        )
      : Icon(Icons.help_outline, size: 45, color: Colors.pink[300]);
}

Widget _buildShadeItem(Color color, int index, String productName) {
  final isSelected = selectedShades[productName] == color;
  final isPrimary = index == 0;
  final isMiddleShade = index == 2; // Middle shade at index 2
  final size = isPrimary ? 70.0 : 50.0;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isPrimary)
        Transform.translate(
          offset: const Offset(0, 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Recommended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      GestureDetector(
        onTap: () async {
          // Only apply makeup overlay for small circle shades (non-primary)
          if (!isPrimary) {
            // Store current selection state
            final previousSelection = selectedShades[productName];
            
            setState(() {
              // Toggle selection - if already selected, unselect it
              if (isSelected) {
                selectedShades[productName] = null;
              } else {
                selectedShades[productName] = color;
              }
            });
            
            // Apply or remove makeup based on selection changes
            if (previousSelection != selectedShades[productName]) {
              if (selectedShades[productName] != null) {
                // A shade was selected - apply makeup
                await _applyVirtualMakeup();
              } else {
                // A shade was deselected - check if we should remove makeup
                await _handleShadeDeselection(productName);
              }
            }
          } else {
            // For primary (big circle) shades, only toggle expansion
            setState(() {
              expandedProducts[productName] = !expandedProducts[productName]!;
            });
            
            // Show customization dialog when primary is first clicked
            if (_isFirstTimeSelection && !_hasShownProductDialog[productName]!) {
              _hasShownProductDialog[productName] = true;
              _isFirstTimeSelection = false;
              await showCustomizationDialog();
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const ui.Color.fromARGB(255, 239, 107, 157) : 
                isPrimary ? Colors.green : 
                isMiddleShade ? Colors.green : Colors.grey, // Green border for middle shade
          width: isPrimary ? 3 : 
                 isMiddleShade ? 3 : 2, // Thicker border for middle shade
        ),
        boxShadow: [
          BoxShadow(
            color: const ui.Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isSelected || isMiddleShade) 
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
    ),
    // Add downward arrow indicator for the primary shade
    if (isPrimary && !expandedProducts[productName]!)
      Container(
        margin: const EdgeInsets.only(top: 4),
        child: Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
          size: 24,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    // Add upward arrow indicator when expanded
    if (isPrimary && expandedProducts[productName]!)
      Container(
        margin: const EdgeInsets.only(top: 4),
        child: Icon(
          Icons.arrow_drop_up,
          color: Colors.white,
          size: 24,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
  ],
),
      ),
    ],
  );
}

Future<void> _handleShadeDeselection(String productName) async {
  // Check if any makeup products are still selected
  final hasSelectedMakeup = selectedShades.values.any((color) => color != null);
  
  if (hasSelectedMakeup) {
    // If other makeup products are still selected, re-apply makeup
    await _applyVirtualMakeup();
  } else {
    // If no makeup products are selected, reset to original image
    resetVirtualMakeup();
  }
}

// Modify the reset function to clear properly
void resetVirtualMakeup() {
  setState(() {
    _processedImage = null;
    _currentMakeupImage = null;
  });
}

  Color getContrastColor(Color color) {
    double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

Future<void> showCustomizationDialog() async {
  if (_hasShownCustomizationDialog) return;
  
  _hasShownCustomizationDialog = true;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.pink.shade200.withOpacity(0.9),
                  Colors.purple.shade200.withOpacity(0.8),
                  Colors.pink.shade400.withOpacity(0.7),
                ],
                stops: const [0.1, 0.5, 0.9],
                tileMode: TileMode.mirror,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcOver,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.95),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient text
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.pink.shade400,
                          Colors.purple.shade400,
                          Colors.pink.shade600,
                        ],
                        stops: const [0.2, 0.5, 0.8],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Customize Your Look',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content with elegant styling
                  const Text(
                    'Would you like to customize your makeup shades further?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons with modern styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // No button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Keep the AI-applied makeup but clear any manual selections
                          setState(() {
                            // Clear manual selections but keep the AI-recommended makeup applied
                            selectedShades.updateAll((key, value) => null);
                            // The _processedImage already contains the AI-applied makeup
                            _userChoseToCustomize = false; // User chose not to customize
                          });
                          _showSatisfiedToast();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.pink.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.pink.shade300, width: 2),
                          ),
                          elevation: 4,
                          shadowColor: Colors.pink.withOpacity(0.3),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      // Yes button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            showShades = true;
                            _processedImage = null;
                            _currentMakeupImage = null;
                            _userChoseToCustomize = true; // User chose to customize
                          });
                          // Show toastification for customization
                          _showCustomizationToast();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Colors.pink.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Add this new method to show customization toast
void _showCustomizationToast() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: const Text('Customization Mode'),
      description: const Text('You can now customize your makeup look!'),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      icon: const Icon(Icons.face, color: Colors.white),
      primaryColor: Colors.pink.shade200,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  });
}

// Add this new method to show toastification with check icon
void _showSatisfiedToast() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: const Text('Perfect!'),
      description: const Text('AI recommendations applied. You can now save your look'),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  });
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Background image - use current makeup image if available
        Positioned.fill(
          child: _currentMakeupImage != null
              ? Image.memory(_currentMakeupImage!, fit: BoxFit.cover)
              : (_processedImage != null
                  ? Image.memory(_processedImage!, fit: BoxFit.cover)
                  : Image.file(widget.capturedImage, fit: BoxFit.cover)),
        ),
          
          if (_isApplyingMakeup)
  Center(
    child: LoadingAnimationWidget.flickr(
      leftDotColor: Colors.pinkAccent,
      rightDotColor: Colors.pinkAccent,
      size: MediaQuery.of(context).size.width * 0.1,
    ),
  ),
Positioned(
  top: MediaQuery.of(context).padding.top + 40,
  left: 0,
  right: 0,
  child: Center(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade200.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        widget.selectedMakeupLook ?? 'No look selected',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  ),
),

Positioned(
  left: 10,
  top: MediaQuery.of(context).padding.top + 40,
  child: Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.7),
    ),
    child: IconButton(
      icon: Icon(
        showMakeupProducts ? Icons.visibility : Icons.visibility_off,
        size: 30,
        color: Colors.pinkAccent,
      ),
      onPressed: () {
        setState(() {
          showMakeupProducts = !showMakeupProducts;
          if (!showMakeupProducts) {
            showShades = false;
          }
        });
      },
    ),
  ),
),

if (showMakeupProducts)
    Positioned(
      left: 0,
      top: MediaQuery.of(context).padding.top + 100,
      bottom: 0,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                'Products',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: orderedProductNames.where((product) => makeupShades.containsKey(product)).map((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            selectedProduct = product;
                            showShades = true;
                          });
                          
                          // Show customization dialog when product is first selected
                          if (_isFirstTimeSelection && !_hasShownProductDialog[product]!) {
                            _hasShownProductDialog[product] = true;
                            _isFirstTimeSelection = false;
                            await showCustomizationDialog();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.pink.shade100, Colors.pink.shade300],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: selectedProduct == product 
                                    ? Colors.red 
                                    : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: _buildProductIcon(product),
                              ),
                            ),
                            if (selectedShades[product] != null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),


          if (showShades && selectedProduct != null && makeupShades.containsKey(selectedProduct))
  Positioned(
    right: 0,
    top: 140,
    bottom: 0,
    child: Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                selectedProduct!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            
            // Always show the primary shade
            if (makeupShades[selectedProduct]!.isNotEmpty)
              _buildShadeItem(makeupShades[selectedProduct]![0], 0, selectedProduct!),
            
            // Automatically show other shades when primary is clicked
            if (expandedProducts[selectedProduct]! && makeupShades[selectedProduct]!.length > 1)
              ...makeupShades[selectedProduct]!
                  .asMap()
                  .entries
                  .where((entry) => entry.key > 0)
                  .map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildShadeItem(entry.value, entry.key, selectedProduct!),
                  )),
          ],
        ),
      ),
    ),
  ),
          // Action buttons at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CameraPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text("Retake"),
                  ),
                  ElevatedButton(
                    onPressed: _isResetting ? null : _resetVirtualMakeup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isResetting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Reset"),
                  ),
                  ElevatedButton(
                    onPressed: _saveLook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Save"),
                  ),
                ],
              ),
            ),
          ),

          // Feedback button
          if (_showHeart)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).padding.top + 40,
              child: GestureDetector(
                onTap: () async {
                  setState(() => _showHeart = false);
                  await showDialog(
                    context: context,
                    builder: (context) => FeedbackDialog(
                      recommendationId: widget.recommendationData?['recommendation_id']?.toString() ?? '0',
                      userId: widget.userId,
                    ),
                  );
                  setState(() => _showHeart = true);
                },
                child: ScaleTransition(
                  scale: _heartAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.shade300,
                          Colors.purple.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 25,
                        ),
                        Positioned(
                          top: 3,
                          right: 3,
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          left: 3,
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class FeedbackDialog extends StatefulWidget {
  final String recommendationId;
  final String userId;

  const FeedbackDialog({
    super.key,
    required this.recommendationId,
    required this.userId,
  });

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> with TickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _glitterController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _glitterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glitterController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Widget _buildGlitterEffect() {
    return AnimatedBuilder(
      animation: _glitterController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: 20 + 20 * sin(_glitterController.value * 2 * pi),
              top: 15 + 10 * cos(_glitterController.value * 3 * pi),
              child: Transform.rotate(
                angle: _glitterController.value * pi,
                child: const Icon(Icons.star, 
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            Positioned(
              right: 25 + 15 * cos(_glitterController.value * 2.5 * pi),
              bottom: 20 + 5 * sin(_glitterController.value * 4 * pi),
              child: Transform.rotate(
                angle: _glitterController.value * 2 * pi,
                child: const Icon(Icons.star, 
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('https://glamouraika.com/api/submit_feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'recommendation_id': widget.recommendationId,
          'rating': _rating,
          'feedback_text': _feedbackController.text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.pink.shade100,
                          Colors.purpleAccent.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: Tween(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: ModalRoute.of(context)!.animation!,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.shade300,
                                  Colors.purple.shade300,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Thank You!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  Colors.pink.shade700,
                                  Colors.purple.shade700,
                                ],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your feedback was submitted successfully",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.pink.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _glitterController,
                          curve: Curves.linear,
                        ),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: RotationTransition(
                      turns: Tween(begin: 1.0, end: 0.0).animate(
                        CurvedAnimation(
                          parent: _glitterController,
                          curve: Curves.linear,
                        ),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 30,
                    child: FadeTransition(
                      opacity: Tween(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _glitterController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Icon(
                        Icons.star_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? 'Failed to submit feedback')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.46,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade100,
                Colors.purpleAccent.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildGlitterEffect(),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.pink, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.favorite,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'How satisfied are you with the makeup shade recommendations provided by Glamour?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [Colors.pink.shade700, Colors.purple.shade700],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                              _glitterController.forward(from: 0);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            transform: Matrix4.identity()
                              ..scale(_rating == index + 1 ? 1.2 : 1.0),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _rating > index
                                    ? [Colors.amber, Colors.amber.shade700]
                                    : [Colors.grey.shade400, Colors.grey],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.star,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Your thoughts...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.7),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: Colors.pink.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.pinkAccent,
                            elevation: 4,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [Colors.white, Colors.white.withOpacity(0.7)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}