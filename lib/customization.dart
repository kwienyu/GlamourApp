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
import 'camera2.dart';
import 'glamvault.dart';

//  Face Landmark detector
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

//  Makeup Overlay
class MakeupOverlayEngine {
  static Future<Uint8List> applyMakeup({
    required File imageFile,
    required Color lipstickColor,
    required Color eyeshadowColor,
    required Color blushColor,
  }) async {
    try {
      final faces = await FaceLandmarkHelper.detectFaces(imageFile);
      if (faces.isEmpty) throw Exception('No faces detected');

      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes)!;
      
      final overlay = await _createMakeupOverlay(
        originalImage.width,
        originalImage.height,
        faces,
        lipstickColor,
        eyeshadowColor,
        blushColor,
      );

      img.compositeImage(
        originalImage,
        img.decodeImage(overlay)!,
        blend: img.BlendMode.overlay,
      );

      return Uint8List.fromList(img.encodePng(originalImage));
    } catch (e) {
      throw Exception('Makeup application failed: $e');
    }
  }

  static Future<Uint8List> _createMakeupOverlay(
    int width,
    int height,
    List<Face> faces,
    Color lipstickColor,
    Color eyeshadowColor,
    Color blushColor,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final paint = Paint()..blendMode = BlendMode.srcOver;

    for (final face in faces) {
      final landmarks = face.landmarks;
      
      // Draw eyeshadow
      if (landmarks[FaceLandmarkType.leftEye] != null && 
          landmarks[FaceLandmarkType.rightEye] != null) {
        paint.color = eyeshadowColor.withOpacity(0.3);
        
        // Left eye
        _drawEyeMakeup(
          canvas,
          landmarks[FaceLandmarkType.leftEye]!.position,
          isLeftEye: true,
          paint: paint,
        );
        
        // Right eye
        _drawEyeMakeup(
          canvas,
          landmarks[FaceLandmarkType.rightEye]!.position,
          isLeftEye: false,
          paint: paint,
        );
      }

      // Draw lips (using bottom mouth landmark only)
      if (landmarks[FaceLandmarkType.bottomMouth] != null) {
        paint.color = lipstickColor.withOpacity(0.5);
        _drawLipMakeup(
          canvas,
          landmarks[FaceLandmarkType.bottomMouth]!.position,
          paint: paint,
        );
      }

      // Draw blush (using available cheek landmarks)
      if (landmarks[FaceLandmarkType.leftCheek] != null &&
          landmarks[FaceLandmarkType.rightCheek] != null) {
        paint.color = blushColor.withOpacity(0.2);
        _drawBlush(
          canvas,
          landmarks[FaceLandmarkType.leftCheek]!.position,
          landmarks[FaceLandmarkType.rightCheek]!.position,
          paint: paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawEyeMakeup(
    Canvas canvas,
    Point<int> eyePosition,
    {
      required bool isLeftEye,
      required Paint paint,
    }
  ) {
    // Create an oval around the eye position
    final eyeRect = Rect.fromCenter(
      center: Offset(eyePosition.x.toDouble(), eyePosition.y.toDouble()),
      width: 60,  
      height: 30, 
    );
    
    // Offset slightly differently for left vs right eye
    if (isLeftEye) {
      canvas.drawOval(
        eyeRect.translate(-10, 0),
        paint,
      );
    } else {
      canvas.drawOval(
        eyeRect.translate(10, 0),
        paint,
      );
    }
    
    // Add some blending
    final blendPaint = Paint()
      ..color = paint.color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(eyeRect, blendPaint);
  }

  static void _drawLipMakeup(
  Canvas canvas,
  Point<int> bottomMouth,
  {
    required Paint paint,
  }
) {
  // Create a bigger oval for lips and move it upward
  final lipRect = Rect.fromCenter(
    center: Offset(bottomMouth.x.toDouble(), bottomMouth.y.toDouble() - 8), // Moved upward by 8 pixels
    width: 70,  // Increased from 60 to 70
    height: 45, // Increased from 40 to 45
  );
  
  canvas.drawOval(lipRect, paint);
  
  // Add some blending
  final blendPaint = Paint()
    ..color = paint.color.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawOval(lipRect, blendPaint);
}

  static void _drawBlush(
    Canvas canvas,
    Point<int> leftCheek,
    Point<int> rightCheek,
    {
      required Paint paint,
    }
  ) {
    // Draw blush as soft circles on cheeks
    final leftBlushPaint = Paint()
      ..color = paint.color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    final rightBlushPaint = Paint()
      ..color = paint.color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    // Position blush slightly above and to the side of cheek landmarks
    canvas.drawCircle(
      Offset(
        leftCheek.x.toDouble() - 20,
        leftCheek.y.toDouble() - 15,
      ),
      40,
      leftBlushPaint,
    );
    
    canvas.drawCircle(
      Offset(
        rightCheek.x.toDouble() + 20,
        rightCheek.y.toDouble() - 15,
      ),
      40,
      rightBlushPaint,
    );
  }
}
// API makeup
class MakeupOverlayApiService {
  Future<Map<String, dynamic>> applyMakeup({
    required File imageFile,
    String? eyeshadowColor,
    String? lipstickColor,
    String? blushColor,
    required String skinTone,
    required String undertone,
    required String makeupLook,
    required String makeupType,
  }) async {
    try {
      final apiResponse = await _callMakeupApi(
        imageFile,
        eyeshadowColor,
        lipstickColor,
        blushColor,
        skinTone,
        undertone,
        makeupLook,
        makeupType,
      );
      
      if (apiResponse != null) return apiResponse;
      return await _applyLocalMakeup(
        imageFile: imageFile,
        eyeshadowColor: eyeshadowColor,
        lipstickColor: lipstickColor,
        blushColor: blushColor,
      );
    } catch (e) {
      debugPrint('Makeup application failed: $e');
      return await _mockApplyMakeup(
        imageFile: imageFile,
        eyeshadowColor: eyeshadowColor,
        lipstickColor: lipstickColor,
        blushColor: blushColor,
      );
    }
  }

  Future<Map<String, dynamic>?> _callMakeupApi(
    File imageFile,
    String? eyeshadowColor,
    String? lipstickColor,
    String? blushColor,
    String skinTone,
    String undertone,
    String makeupLook,
    String makeupType,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
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
            if (eyeshadowColor != null) 'eyeshadow_color': eyeshadowColor,
            if (lipstickColor != null) 'lipstick_color': lipstickColor,
            if (blushColor != null) 'blush_color': blushColor,
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
    String? eyeshadowColor,
    String? lipstickColor,
    String? blushColor,
  }) async {
    try {
      final lipColor = lipstickColor != null ? HexColor(lipstickColor) : Colors.transparent;
      final eyeColor = eyeshadowColor != null ? HexColor(eyeshadowColor) : Colors.transparent;
      final blushColorObj = blushColor != null ? HexColor(blushColor) : Colors.transparent;

      final result = await MakeupOverlayEngine.applyMakeup(
        imageFile: imageFile,
        lipstickColor: lipColor,
        eyeshadowColor: eyeColor,
        blushColor: blushColorObj,
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
    String? eyeshadowColor,
    String? lipstickColor,
    String? blushColor,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return {
      'status': 'success',
      'message': 'Mock makeup applied',
      'result_image': base64Encode(bytes),
    };
  }
}

// ==================== HEX COLOR HELPER ====================
class HexColor extends Color {
  HexColor(String hexColor) : super(_parseHex(hexColor));

  static int _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}
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
  final hasMakeup = selectedShades.entries.any((entry) => 
      entry.value != null && 
      ['Eyeshadow', 'Lipstick', 'Blush'].contains(entry.key));
  
  if (!hasMakeup) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one makeup product (Eyeshadow, Lipstick, or Blush)')),
    );
    return;
  }

  setState(() => _isApplyingMakeup = true);

  try {
    final response = await _makeupApiService.applyMakeup(
      imageFile: widget.capturedImage,
      eyeshadowColor: selectedShades['Eyeshadow'] != null 
          ? '#${selectedShades['Eyeshadow']!.value.toRadixString(16).substring(2)}'
          : null,
      lipstickColor: selectedShades['Lipstick'] != null
          ? '#${selectedShades['Lipstick']!.value.toRadixString(16).substring(2)}'
          : null,
      blushColor: selectedShades['Blush'] != null
          ? '#${selectedShades['Blush']!.value.toRadixString(16).substring(2)}'
          : null,
      skinTone: widget.skinTone ?? 'medium',
      undertone: widget.undertone,
      makeupLook: widget.selectedMakeupLook ?? 'natural',
      makeupType: widget.selectedMakeupType ?? 'everyday',
    );

    setState(() {
      _processedImage = base64Decode(response['result_image']);
      
      // Show message if mock implementation was used
      if (response['status'] == 'success' && response['message']?.contains('Mock') == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error applying makeup: $e')),
    );
  } finally {
    setState(() => _isApplyingMakeup = false);
  }
}

  void _resetVirtualMakeup() {
    setState(() {
      _processedImage = null;
    });
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
            // Store all shades including Primary
            shadeHexCodes[category] = [];
            makeupShades[category] = [];
            
            // Process Primary shade first if exists
            if (shadeMap.containsKey('Primary')) {
              final hexCode = shadeMap['Primary'] as String;
              shadeHexCodes[category]!.add(hexCode);
              makeupShades[category]!.add(_parseHexColor(hexCode));
            }
            
            // Process other shades (Light, Medium, Dark)
            final shadeTypes = ['Light', 'Medium', 'Dark'];
            for (var shadeType in shadeTypes) {
              if (shadeMap.containsKey(shadeType)) {
                final hexCode = shadeMap[shadeType] as String;
                // Only add if not already added as Primary
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
            // First add the Primary shade if it exists
            if (shadeMap.containsKey('Primary')) {
              final hexCode = shadeMap['Primary'] as String;
              shadeHexCodes[category] = [hexCode];
              makeupShades[category] = [_parseHexColor(hexCode)];
            }
            
            // Then add other shades (Light, Medium, Dark)
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
    }  else if (response.statusCode == 400) {
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

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, List<String>> labeledShades = {};
      selectedShades.forEach((productType, color) {
        if (color != null) {
          String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
          labeledShades[productType] = [hexColor];
        }
      });

      if (labeledShades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No shades selected to save')),
        );
        return;
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

 Widget _buildShadeItem(Color color, int index) {
  final isSelected = selectedShades[selectedProduct!] == color;
  final isPrimary = index == 0;
  final size = isPrimary ? 70.0 : 50.0; // Primary is bigger
  final hexCode = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  final fontSize = isPrimary ? 10.0 : 8.0; // Font size adjustment

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
        onTap: () {
          setState(() {
            selectedShades[selectedProduct!] = isSelected ? null : color;
            if (isPrimary) {
              expandedProducts[selectedProduct!] = !expandedProducts[selectedProduct!]!;
            }
          });
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
                  color: isSelected ? Colors.green: 
                        isPrimary ? Colors.green: Colors.grey,
                  width: isPrimary ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  if (isSelected) 
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      hexCode, // Now includes the # symbol
                      style: TextStyle(
                        fontSize: fontSize,
                        color: _getContrastColor(color),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Helper function to get contrasting text color
Color _getContrastColor(Color color) {
  // Calculate the perceptive luminance
  double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  return luminance > 0.5 ? Colors.black : Colors.white;
}
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: _processedImage != null
                ? Image.memory(_processedImage!, fit: BoxFit.cover)
                : Image.file(widget.capturedImage, fit: BoxFit.cover),
          ),
Positioned(
  top: MediaQuery.of(context).padding.top + 40, // Changed from +20 to +40
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

// 2. Move the toggle makeup products visibility button down:
Positioned(
  left: 10,
  top: MediaQuery.of(context).padding.top + 40, // Changed from +20 to +40
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

// 3. Move the makeup products panel down:
if (showMakeupProducts)
  Positioned(
    left: 0,
    top: MediaQuery.of(context).padding.top + 100, // Changed from +80 to +100
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
                color: Color.fromARGB(255, 250, 249, 249),
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
                      onTap: () {
                        setState(() {
                          selectedProduct = product;
                          showShades = true;
                        });
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                )
                              ],
                              border: Border.all(
                                color: selectedProduct == product 
                                  ? Colors.red 
                                  : selectedShades[product] != null
                                    ? Colors.green
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

// 4. Move the shades panel down:
  if (showShades && selectedProduct != null && makeupShades.containsKey(selectedProduct))
  Positioned(
    right: 0,
    top: 140,
    bottom: 0,
    child: Container(
      width: 110, // Slightly wider to accommodate larger primary shade
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
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
            if (selectedShades[selectedProduct] != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedShades[selectedProduct!] = null;
                  });
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8), // Increased spacing
            
            // Always show the primary shade
            if (makeupShades[selectedProduct]!.isNotEmpty)
              _buildShadeItem(makeupShades[selectedProduct]![0], 0),
            
            // Automatically show other shades when primary is clicked
            if (expandedProducts[selectedProduct]! && makeupShades[selectedProduct]!.length > 1)
              ...makeupShades[selectedProduct]!
                  .asMap()
                  .entries
                  .where((entry) => entry.key > 0) // Skip primary shade
                  .map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 12.0), // Increased spacing
                    child: _buildShadeItem(entry.value, entry.key),
                  ))
                  ,
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
                    onPressed: _isApplyingMakeup ? null : _applyVirtualMakeup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isApplyingMakeup
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Apply"),
                  ),
                  ElevatedButton(
                    onPressed: _processedImage != null ? _resetVirtualMakeup : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text("Reset"),
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