import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'makeuphub.dart';
import 'glamvault.dart';
import 'package:toastification/toastification.dart';

class HexColor extends Color {
  HexColor(String hexColor) : super(_parseHex(hexColor));

  static int _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}

class CustomizationPage extends StatefulWidget {
  final File? capturedImage;
  final String? selectedMakeupType;
  final String? selectedMakeupLook;
  final String userId;
  final String undertone;
  final String? skinTone;
  final Map<String, dynamic>? recommendationData;

  const CustomizationPage({
    super.key,
    this.capturedImage,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
    required this.userId,
    required this.undertone,
    this.skinTone,
    this.recommendationData,
  });

  @override
  CustomizationPageState createState() => CustomizationPageState();
}

class CustomizationPageState extends State<CustomizationPage> with TickerProviderStateMixin {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;
  bool isLoading = false;
  bool isSaved = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = true;
  Map<String, bool> expandedProducts = {};
  bool _isApplyingMakeup = false;
  bool _isRemovingMakeup = false;
  Uint8List? _processedImage;
  Uint8List? _currentMakeupImage;
  bool _hasShownCustomizationDialog = false;
  bool isFirstTimeSelection = true;
  bool _isResetting = false;
  bool _userChoseToCustomize = false;
  bool _hasShownCustomizationDialogForSave = false;
  bool _hasShownCustomizationDialogForProduct = false;

  bool _isNavigationBarVisible = false;
  DateTime? _lastTapTime;
  String? _lastChangedProduct;

  Map<String, Map<String, String>> allRecommendedShades = {};
  
  Map<String, String> currentShades = {
    'Eyeshadow': 'Primary',
    'Blush': 'Primary',
    'Lipstick': 'Primary',
  };

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
    'Concealer': 'assets/concealer.png',
    'Contour': 'assets/contour.png',
    'Eyeshadow': 'assets/eyeshadow.png',
    'Blush': 'assets/blush.png',
    'Lipstick': 'assets/lipstick.png',
    'Highlighter': 'assets/highlighter.png',
    'Eyebrow': 'assets/eyebrow.png',
  };

  final List<String> orderedProductNames = [
    'Foundation',
    'Concealer',
    'Contour',
    'Eyeshadow',
    'Blush',
    'Lipstick',
    'Highlighter',
    'Eyebrow',
  ];

  final String? _apiToken = null;

  late final List<String> _loadingPhrases;
  late final List<String> _removingPhrases;

  String _currentLoadingPhrase = "";
  String _currentRemovingPhrase = "";
  Timer? _loadingPhraseTimer;
  Timer? _removingPhraseTimer;
  int _currentPhraseIndex = 0;
  int _currentRemovingPhraseIndex = 0;
  late AnimationController _phraseAnimationController;
  late AnimationController _removingPhraseAnimationController;
  late Animation<double> _phraseFadeAnimation;
  late Animation<double> _removingPhraseFadeAnimation;
  late Animation<Offset> _phraseSlideAnimation;
  late Animation<Offset> _removingPhraseSlideAnimation;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  bool _isZooming = false;

  @override
void initState() {
  super.initState();

  _loadingPhrases = [
    "Preparing your ${widget.selectedMakeupLook ?? "makeup"} look...",
    "Hold on, gorgeous—your glam's loading💕",
    "Mixing your perfect shades... almost done!🪞",
    "Blush, blend, and beauty—coming right up!💄",
    "Your virtual makeup artist is at work💖",
    "Just a sec—glow mode is activating🔥",
    "Almost there... your glam is worth the wait💅",
    "Sprinkling a bit of sparkle on your look✨",
  ];

  _removingPhrases = [
    "Removing your customized shade...",
    "Clearing the makeup overlay...",
    "Taking off the ${widget.selectedMakeupLook ?? "makeup"}...",
    "Restoring your natural look...",
    "Removing the makeup application...",
    "Cleaning up the virtual makeup...",
    "Reverting to previous state...",
    "Removing customized shade...",
  ];
  
  _processRecommendationData();
  
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
  
  _phraseAnimationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  _removingPhraseAnimationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  _phraseFadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _phraseAnimationController,
    curve: Curves.easeInOut,
  ));

  _removingPhraseFadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _removingPhraseAnimationController,
    curve: Curves.easeInOut,
  ));

  _phraseSlideAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _phraseAnimationController,
    curve: Curves.easeOutCubic,
  ));

  _removingPhraseSlideAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _removingPhraseAnimationController,
    curve: Curves.easeOutCubic,
  ));

  _hideNavigationBar();
  _startLoadingPhraseTimer();

  // Automatically apply makeup when page loads
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _applyMakeupOnInit();
  });
}

Future<void> _applyMakeupOnInit() async {
  _userChoseToCustomize = true;
  
  // Fetch recommendations and apply makeup
  await _fetchRecommendations();
}

  void _startLoadingPhraseTimer() {
    _currentPhraseIndex = 0;
    _currentLoadingPhrase = _loadingPhrases[_currentPhraseIndex];
    _phraseAnimationController.forward();
    
    _loadingPhraseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _phraseAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentPhraseIndex = (_currentPhraseIndex + 1) % _loadingPhrases.length;
              _currentLoadingPhrase = _loadingPhrases[_currentPhraseIndex];
            });
            _phraseAnimationController.forward();
          }
        });
      }
    });
  }

  void _startRemovingPhraseTimer() {
    _currentRemovingPhraseIndex = 0;
    _currentRemovingPhrase = _removingPhrases[_currentRemovingPhraseIndex];
    _removingPhraseAnimationController.forward();
    
    _removingPhraseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _removingPhraseAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentRemovingPhraseIndex = (_currentRemovingPhraseIndex + 1) % _removingPhrases.length;
              _currentRemovingPhrase = _removingPhrases[_currentRemovingPhraseIndex];
            });
            _removingPhraseAnimationController.forward();
          }
        });
      }
    });
  }

  void _stopLoadingPhraseTimer() {
    _loadingPhraseTimer?.cancel();
    _loadingPhraseTimer = null;
  }

  void _stopRemovingPhraseTimer() {
    _removingPhraseTimer?.cancel();
    _removingPhraseTimer = null;
  }

  @override
  void dispose() {
    _heartController.dispose();
    _phraseAnimationController.dispose();
    _removingPhraseAnimationController.dispose();
    _stopLoadingPhraseTimer();
    _stopRemovingPhraseTimer();
    _showNavigationBar();
    super.dispose();
  }

  void _hideNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() {
      _isNavigationBarVisible = false;
    });
  }

  void _showNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() {
      _isNavigationBarVisible = true;
    });
  }

  void _toggleNavigationBar() {
    if (_isNavigationBarVisible) {
      _hideNavigationBar();
    } else {
      _showNavigationBar();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
    setState(() {
      _isZooming = true;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      if (_scale > 1.0) {
        final newOffset = _previousOffset + details.focalPoint - details.localFocalPoint;
        final maxOffsetX = (MediaQuery.of(context).size.width * (_scale - 1.0)) / 2;
        final maxOffsetY = (MediaQuery.of(context).size.height * (_scale - 1.0)) / 2;
        
        _offset = Offset(
          newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
          newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
        );
      } else {
        _offset = Offset.zero;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
    setState(() {
      _isZooming = false;
    });
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _previousScale = 1.0;
      _previousOffset = Offset.zero;
    });
  }

  void _handleTap() {
    if (_isZooming) return;
    
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < Duration(milliseconds: 300)) {
      _toggleNavigationBar();
    } else {
      if (_isNavigationBarVisible) {
        Future.delayed(Duration(seconds: 3), () {
          if (mounted && _isNavigationBarVisible) {
            _hideNavigationBar();
          }
        });
      }
    }
    _lastTapTime = now;
  }

  void _handleSwipeUp() {
    if (!_isNavigationBarVisible) {
      _showNavigationBar();
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isNavigationBarVisible) {
          _hideNavigationBar();
        }
      });
    }
  }

  String _getCurrentOverlayCode() {
    final List<String> activeOverlays = [];
    
    if (selectedShades['Eyeshadow'] != null) activeOverlays.add('E');
    if (selectedShades['Blush'] != null) activeOverlays.add('B');
    if (selectedShades['Lipstick'] != null) activeOverlays.add('L');
    
    return activeOverlays.isNotEmpty ? activeOverlays.join('+') : 'none';
  }

  Map<String, String> _getCurrentShadesMap() {
    final Map<String, String> shadesMap = {};
    
    if (selectedShades['Eyeshadow'] != null) {
      shadesMap['E'] = _getShadeType('Eyeshadow', selectedShades['Eyeshadow']!);
    }
    if (selectedShades['Blush'] != null) {
      shadesMap['B'] = _getShadeType('Blush', selectedShades['Blush']!);
    }
    if (selectedShades['Lipstick'] != null) {
      shadesMap['L'] = _getShadeType('Lipstick', selectedShades['Lipstick']!);
    }
    
    return shadesMap;
  }

  String _getShadeType(String productName, Color color) {
    final shades = makeupShades[productName];
    if (shades == null || shades.isEmpty) return 'Primary';
    
    final index = shades.indexOf(color);
    if (index == -1) return 'Primary';
    
    switch (index) {
      case 0: return 'Primary';
      case 1: return 'Light';
      case 2: return 'Medium';
      case 3: return 'Dark';
      default: return 'Primary';
    }
  }

  Map<String, String>? _getChangedOverlayInfo() {
    if (_lastChangedProduct != null && selectedShades[_lastChangedProduct!] != null) {
      final overlayType = _getOverlayType(_lastChangedProduct!);
      final shadeValue = _getShadeType(_lastChangedProduct!, selectedShades[_lastChangedProduct!]!);
      
      return {
        'overlayType': overlayType,
        'shadeValue': shadeValue,
      };
    }
    
    return null;
  }

  String _getOverlayType(String productName) {
    switch (productName) {
      case 'Eyeshadow': return 'E';
      case 'Blush': return 'B';
      case 'Lipstick': return 'L';
      default: return '';
    }
  }

  void _updateCurrentShades(Map<String, dynamic> updatedShades) {
    updatedShades.forEach((overlayCode, shadeType) {
      final productName = _getProductName(overlayCode);
      if (productName != null && makeupShades.containsKey(productName)) {
        final color = _getColorForShadeType(productName, shadeType.toString());
        if (color != null) {
          selectedShades[productName] = color;
          currentShades[productName] = shadeType.toString();
        }
      }
    });
  }

  String? _getProductName(String overlayCode) {
    switch (overlayCode) {
      case 'E': return 'Eyeshadow';
      case 'B': return 'Blush';
      case 'L': return 'Lipstick';
      default: return null;
    }
  }

  Color? _getColorForShadeType(String productName, String shadeType) {
    final shades = makeupShades[productName];
    if (shades == null) return null;
    
    final index = _getShadeIndex(shadeType);
    return index < shades.length ? shades[index] : null;
  }

  int _getShadeIndex(String shadeType) {
    switch (shadeType.toLowerCase()) {
      case 'primary': return 0;
      case 'light': return 1;
      case 'medium': return 2;
      case 'dark': return 3;
      default: return 0;
    }
  }

  Future<void> _applyFullCombination(String base64Image) async {
    final response = await http.post(
      Uri.parse('https://glamouraika.com/models/generate-makeup-combinations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Image,
        'skin_tone': widget.skinTone ?? 'Medium',
        'undertone': widget.undertone,
        'makeup_type': widget.selectedMakeupType,
        'makeup_look': widget.selectedMakeupLook,
        'eyeshadow_shade': currentShades['Eyeshadow'] ?? 'Primary',
        'blush_shade': currentShades['Blush'] ?? 'Primary',
        'lipstick_shade': currentShades['Lipstick'] ?? 'Primary',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final overlayImageBase64 = data['combinations']['EBL']['image'];
      final imageBytes = base64Decode(overlayImageBase64);
      
      setState(() {
        _processedImage = imageBytes;
        _currentMakeupImage = _processedImage;
      });
    }
  }

  Future<void> _applyVirtualMakeup() async {
  final previousImage = _processedImage;
  setState(() => _isApplyingMakeup = true);

  try {
    if (widget.capturedImage == null) {
      throw Exception('No captured image available');
    }

    final imageBytes = await widget.capturedImage!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final currentOverlays = _getCurrentOverlayCode();
    final currentShadesMap = _getCurrentShadesMap();
    if (currentOverlays == 'none' || _lastChangedProduct == null) {
      await _applyFullCombination(base64Image);
      return;
    }

    final changeInfo = _getChangedOverlayInfo();
    if (changeInfo == null) {
      await _applyFullCombination(base64Image);
      return;
    }

    final response = await http.post(
      Uri.parse('https://glamouraika.com/models/update-single-overlay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Image,
        'skin_tone': widget.skinTone ?? 'Medium',
        'undertone': widget.undertone,
        'makeup_type': widget.selectedMakeupType,
        'makeup_look': widget.selectedMakeupLook,
        'current_overlay': currentOverlays,
        'shades': currentShadesMap,
        'change_overlay': changeInfo['overlayType'],
        'shade': changeInfo['shadeValue'],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final result = data['result'];
        final overlayImageBase64 = result['image'];
        final imageBytes = base64Decode(overlayImageBase64);
        
        setState(() {
          _processedImage = imageBytes;
          _currentMakeupImage = _processedImage;
          
          if (result.containsKey('updated_shades')) {
            _updateCurrentShades(result['updated_shades']);
          }
        });
      } else {
        throw Exception(data['error'] ?? 'Unknown error from API');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
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

  Future<void> removeOverlay(String productName) async {
    setState(() {
      _isRemovingMakeup = true;
      _lastChangedProduct = productName;
      selectedShades[productName] = null;
      currentShades[productName] = 'Primary';
    });

    _startRemovingPhraseTimer();

    try {
      if (widget.capturedImage == null) {
        throw Exception('No captured image available');
      }

      final imageBytes = await widget.capturedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://glamouraika.com/models/update-single-overlay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'skin_tone': widget.skinTone ?? 'Medium',
          'undertone': widget.undertone,
          'makeup_type': widget.selectedMakeupType,
          'makeup_look': widget.selectedMakeupLook,
          'current_overlay': _getCurrentOverlayCode(),
          'shades': _getCurrentShadesMap(),
          'change_overlay': _getOverlayType(productName),
          'shade': 'none',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final result = data['result'];
          final overlayImageBase64 = result['image'];
          final imageBytes = base64Decode(overlayImageBase64);
          
          setState(() {
            _processedImage = imageBytes;
            _currentMakeupImage = _processedImage;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing overlay: $e')),
      );
    } finally {
      setState(() {
        _isRemovingMakeup = false;
        _stopRemovingPhraseTimer();
      });
    }
  }

  Future<void> _applyVirtualMakeupAutomatically(Map<String, dynamic> recommendations) async {
    setState(() => _isApplyingMakeup = true);

    try {
      if (widget.capturedImage == null) {
        throw Exception('No captured image available');
      }

      final imageBytes = await widget.capturedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://glamouraika.com/models/generate-makeup-combinations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'skin_tone': widget.skinTone ?? 'Medium',
          'undertone': widget.undertone,
          'makeup_type': widget.selectedMakeupType,
          'makeup_look': widget.selectedMakeupLook,
          'eyeshadow_shade': 'Primary',
          'blush_shade': 'Primary',
          'lipstick_shade': 'Primary',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final overlayImageBase64 = data['combinations']['EBL']['image'];
        final imageBytes = base64Decode(overlayImageBase64);
        
        setState(() {
          _processedImage = imageBytes;
          _currentMakeupImage = _processedImage;
        });
      } else {
        final bytes = await widget.capturedImage!.readAsBytes();
        setState(() {
          _processedImage = bytes;
          _currentMakeupImage = _processedImage;
        });
      }
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
      // Reset all states to initial values
      setState(() {
        currentShades = {
          'Eyeshadow': 'Primary',
          'Blush': 'Primary',
          'Lipstick': 'Primary',
        };
        selectedShades.updateAll((key, value) => null);
        _userChoseToCustomize = true; // Enable customization again
        _lastChangedProduct = null;
        selectedProduct = null;
        showMakeupProducts = false; // Hide makeup products
        showShades = false; // Hide shades
        
        // Reset all expansion states
        expandedProducts.updateAll((key, value) => false);
        
        // Reset dialog flags to show customization dialog again
        _hasShownCustomizationDialog = false;
        _hasShownCustomizationDialogForSave = false;
        _hasShownCustomizationDialogForProduct = false;
        
        // Reset product dialog flags
        _hasShownProductDialog.updateAll((key, value) => false);
      });

      await _applyVirtualMakeupAutomatically({});
      
      // Show reset success message
      _showResetSuccessMessage();
      
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

  void _showResetSuccessMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Reset Complete'),
        description: const Text('Makeup has been reset. Click any product to customize your look.'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        borderRadius: BorderRadius.circular(12),
        showProgressBar: true,
        icon: const Icon(Icons.refresh, color: Colors.green),
        primaryColor: Colors.green,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      );
    });
  }

  void _processRecommendationData() {
    if (widget.recommendationData != null) {
      final recommendations = widget.recommendationData!['recommendations'] as Map<String, dynamic>?;
      if (recommendations != null) {
        setState(() {
          makeupShades.clear();
          shadeHexCodes.clear();
          allRecommendedShades.clear();
          
          recommendations.forEach((category, shadeMap) {
            if (shadeMap is Map) {
              allRecommendedShades[category] = Map<String, String>.from(shadeMap);
              
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
        allRecommendedShades.clear();
        
        recommendations.forEach((category, shadeMap) {
          if (shadeMap is Map) {
            allRecommendedShades[category] = Map<String, String>.from(shadeMap);
            
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
  
      await _applyVirtualMakeup();
    
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

  Future<void> _handleShadeSelection(String productName, Color color, int index, bool isPrimary) async {
    // Show customization dialog if it hasn't been shown yet
    if (!_hasShownCustomizationDialog && !_hasShownCustomizationDialogForProduct) {
      _hasShownCustomizationDialogForProduct = true;
      await showCustomizationDialog();
      return;
    }
    
    // Prevent customization if user chose not to customize
    if (!_userChoseToCustomize) {
      _showCustomizationDisabledMessage();
      return;
    }
    
    _lastChangedProduct = productName;
    
    final isOverlayProduct = ['Eyeshadow', 'Blush', 'Lipstick'].contains(productName);
    final shadeTypes = ['Primary', 'Light', 'Medium', 'Dark'];
    final shadeType = index < shadeTypes.length ? shadeTypes[index] : 'Primary';

    if (!isPrimary) {
      final wasSelected = selectedShades[productName] == color;
      
      setState(() {
        if (wasSelected) {
          selectedShades[productName] = null;
          if (isOverlayProduct) {
            currentShades[productName] = 'Primary';
          }
        } else {
          selectedShades[productName] = color;
          if (isOverlayProduct) {
            currentShades[productName] = shadeType;
          }
        }
      });
      
      if (isOverlayProduct) {
        if (!wasSelected && selectedShades[productName] != null) {
          // Apply makeup when selecting a shade
          await _applyVirtualMakeup();
        } else if (wasSelected && selectedShades[productName] == null) {
          // Remove overlay when deselecting a shade
          await removeOverlay(productName);
        }
      }
    } else {
      setState(() {
        expandedProducts[productName] = !expandedProducts[productName]!;
        
        if (isOverlayProduct && selectedShades[productName] != null) {
          selectedShades[productName] = null;
          currentShades[productName] = 'Primary';
        }
      });
    }
  }

  void _showCustomizationDisabledMessage() {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: const Text('Customization Disabled'),
      description: const Text('You chose to use AI recommendations. Click "Reset" to enable customization.'),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      icon: const Icon(Icons.info_outline, color: Colors.amber),
      primaryColor: Colors.amber.shade200,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  Future<void> handleShadeDeselection(String productName) async {
    // Prevent customization if user chose not to customize
    if (!_userChoseToCustomize) {
      _showCustomizationDisabledMessage();
      return;
    }
    
    final hasSelectedOverlay = ['Eyeshadow', 'Blush', 'Lipstick'].any(
      (product) => selectedShades[product] != null
    );
    
    if (hasSelectedOverlay) {
      await _applyVirtualMakeup();
    } else {
      await _resetToAIRecommendations();
    }
  }

  Future<void> _resetToAIRecommendations() async {
    setState(() {
      _isResetting = true;
    });

    try {
      setState(() {
        currentShades = {
          'Eyeshadow': 'Primary',
          'Blush': 'Primary',
          'Lipstick': 'Primary',
        };
        selectedShades.updateAll((key, value) => null);
        _lastChangedProduct = null;
      });

      await _applyVirtualMakeupAutomatically({});
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

  void resetVirtualMakeup() {
    setState(() {
      _processedImage = null;
      _currentMakeupImage = null;
      _lastChangedProduct = null;
    });
  }

  Future<String> compressAndEncodeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Image processing error: $e');
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    }
  }

  Future<void> _saveLook() async {
    if (!_hasShownCustomizationDialogForSave && !_hasShownCustomizationDialog) {
      _hasShownCustomizationDialogForSave = true;
      await showCustomizationDialog();
      return;
    }

    if (widget.selectedMakeupLook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No makeup look selected')),
      );
      return;
    }

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
      
      bool hasManualSelections = selectedShades.values.any((color) => color != null);
      
      if (hasManualSelections) {
        selectedShades.forEach((productType, color) {
          if (color != null) {
            String hexColor = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
            labeledShades[productType] = [hexColor];
          }
        });
      } else {
        shadeHexCodes.forEach((productType, hexCodes) {
          if (hexCodes.isNotEmpty) {
            labeledShades[productType] = [hexCodes[0]];
            
            if (makeupShades.containsKey(productType) && makeupShades[productType]!.isNotEmpty) {
              selectedShades[productType] = makeupShades[productType]![0];
            }
          }
        });
      }

      Uint8List? imageBytes;
      if (_processedImage != null) {
        imageBytes = _processedImage!;
      } else if (widget.capturedImage != null) {
        imageBytes = await widget.capturedImage!.readAsBytes();
      } else {
        throw Exception('No image available to save');
      }

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
          color: shade.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

Widget _buildShadeItem(Color color, int index, String productName) {
  final isSelected = selectedShades[productName] == color;
  final isPrimary = index == 0;
  final size = isPrimary ? 70.0 : 50.0;
  final isMediumShade = index == 2;
  final isCustomizationDisabled = !_userChoseToCustomize;

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
          await _handleShadeSelection(productName, color, index, isPrimary);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
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
                            isMediumShade ? Colors.green : Colors.grey,
                      width: isPrimary ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const ui.Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      if (isSelected) 
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                if (isCustomizationDisabled && !isPrimary)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (isPrimary && !expandedProducts[productName]!)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            if (isPrimary && expandedProducts[productName]!)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_drop_up,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
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

 Color getContrastColor(Color color) {
  double luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
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
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.shade400,
                        Colors.purple.shade400,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          selectedShades.updateAll((key, value) => null);
                          _userChoseToCustomize = false;
                          // Show products and shades but disable customization
                          showMakeupProducts = true;
                          showShades = true;
                        });
                        _showSatisfiedToast();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.pink.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.pink.shade400, width: 2),
                        ),
                        elevation: 4,
                        shadowColor: Colors.pink.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          showShades = true;
                          showMakeupProducts = true;
                          _processedImage = null;
                          _currentMakeupImage = null;
                          _userChoseToCustomize = true;
                        });
                        _showCustomizationToast();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        shadowColor: Colors.pink.withValues(alpha: 0.5),
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
      );
    },
  );
}
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
        icon: const Icon(Icons.face, color: ui.Color.fromARGB(255, 6, 6, 6)),
        primaryColor: Colors.pink.shade200,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      );
    });
  }

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

  Widget _buildMakeupLoadingIndicator() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.flickr(
                  leftDotColor: Colors.pinkAccent,
                  rightDotColor: Colors.purpleAccent,
                  size: 60,
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Applying your makeup shades recommendation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const ui.Color.fromARGB(255, 249, 247, 248),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                SlideTransition(
                  position: _phraseSlideAnimation,
                  child: FadeTransition(
                    opacity: _phraseFadeAnimation,
                    child: Text(
                      _currentLoadingPhrase,
                      style: TextStyle(
                        fontSize: 12, 
                        color: const ui.Color.fromARGB(255, 249, 247, 248),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemovingLoadingIndicator() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.flickr(
                  leftDotColor: Colors.blueAccent,
                  rightDotColor: Colors.cyanAccent,
                  size: 60,
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Removing your customized shade',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const ui.Color.fromARGB(255, 249, 247, 248),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                SlideTransition(
                  position: _removingPhraseSlideAnimation,
                  child: FadeTransition(
                    opacity: _removingPhraseFadeAnimation,
                    child: Text(
                      _currentRemovingPhrase,
                      style: TextStyle(
                        fontSize: 12, 
                        color: const ui.Color.fromARGB(255, 249, 247, 248),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _handleSwipeUp();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                onDoubleTap: _resetZoom,
                onTap: _isZooming ? null : _handleTap,
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(_offset.dx, _offset.dy)
                    ..scale(_scale),
                  alignment: Alignment.center,
                  child: _currentMakeupImage != null
                      ? Image.memory(_currentMakeupImage!, 
                          fit: BoxFit.cover, 
                          filterQuality: FilterQuality.high)
                      : (_processedImage != null
                          ? Image.memory(_processedImage!, 
                              fit: BoxFit.cover, 
                              filterQuality: FilterQuality.high)
                          : (widget.capturedImage != null
                              ? Image.file(widget.capturedImage!, 
                                  fit: BoxFit.cover, 
                                  filterQuality: FilterQuality.high)
                              : Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_camera, 
                                            size: 80, color: Colors.grey[600]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Image Available',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please capture an image first',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))),
                ),
              ),
            ),
            
            if (_isApplyingMakeup)
              _buildMakeupLoadingIndicator(),

            if (_isRemovingMakeup)
              _buildRemovingLoadingIndicator(),
            
            // Zoom instructions
            if (_isZooming)
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pinch to zoom • Double tap to reset',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                    color: Colors.amber.shade200.withValues(alpha: 0.9),
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
                  color: Colors.white.withValues(alpha: 0.7),
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
                bottom: 120, 
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    color: Colors.white.withValues(alpha: 0.1),
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
                            fontSize: 14,
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
                                    // Show customization dialog if it hasn't been shown yet
                                    if (!_hasShownCustomizationDialog && !_hasShownCustomizationDialogForProduct) {
                                      _hasShownCustomizationDialogForProduct = true;
                                      await showCustomizationDialog();
                                    }
                                    
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
                                          border: Border.all(
                                            color: selectedProduct == product 
                                              ? Colors.red 
                                              : Colors.transparent,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
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
                top: MediaQuery.of(context).padding.top + 100,
                bottom: 120,
                child: SizedBox(
                  width: 110,
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
                        
                        if (makeupShades[selectedProduct]!.isNotEmpty)
                          _buildShadeItem(makeupShades[selectedProduct]![0], 0, selectedProduct!),
                        
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
            
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => MakeupHubPage(
                                  skinTone: widget.skinTone,
                                  capturedImage: widget.capturedImage,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Re-Glam",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _isResetting ? null : _resetVirtualMakeup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
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
                              : const Text(
                                  "Reset",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _saveLook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
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
                              : const Text(
                                  "Save",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                            color: Colors.pink.withValues(alpha: 0.4),
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
  FeedbackDialogState createState() => FeedbackDialogState();
}

class FeedbackDialogState extends State<FeedbackDialog> with TickerProviderStateMixin {
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
                          color: Colors.pink.withValues(alpha: 0.3),
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
                                  color: Colors.pink.withValues(alpha: 0.4),
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
                color: Colors.pink.withValues(alpha: 0.3),
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
                            color: Colors.pink.withValues(alpha: 0.1),
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
                          fillColor: Colors.white.withValues(alpha: 0.8),
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
                            backgroundColor: Colors.white.withValues(alpha: 0.7),
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
                                    colors: [Colors.white, Colors.white.withValues(alpha: 0.7)],
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