import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'makeuphub.dart';
import 'glamvault.dart';
import 'package:toastification/toastification.dart';

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
  CustomizationPageState createState() => CustomizationPageState();
}

class CustomizationPageState extends State<CustomizationPage> with SingleTickerProviderStateMixin {
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
  Uint8List? _processedImage;
  Uint8List? _currentMakeupImage;
  bool _hasShownCustomizationDialog = false;
  bool _isFirstTimeSelection = true;
  bool _isResetting = false;
  bool _userChoseToCustomize = false;

  // Navigation bar control variables
  bool _isNavigationBarVisible = false;
  DateTime? _lastTapTime;

  // Track last changed product for incremental updates
  String? _lastChangedProduct;

  // Store all recommended shades from API
  Map<String, Map<String, String>> allRecommendedShades = {};
  
  // Current selected shades for overlay products (Eyeshadow, Blush, Lipstick)
  Map<String, String> currentShades = {
    'Eyeshadow': 'Primary',
    'Blush': 'Primary',
    'Lipstick': 'Primary',
  };

  // For non-overlay products (just display)
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

  @override
  void initState() {
    super.initState();
    _processRecommendationData();
    _fetchRecommendations();
    
    for (var product in orderedProductNames) {
      expandedProducts[product] = false;
      _hasShownProductDialog[product] = false;
    }

    // Initialize heart animation controller
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

    _hideNavigationBar();
  }

  @override
  void dispose() {
    _heartController.dispose();
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

  void _handleTap() {
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

  // NEW: Helper method to get current overlay code (e.g., "E+L", "E+B", etc.)
  String _getCurrentOverlayCode() {
    final List<String> activeOverlays = [];
    
    if (selectedShades['Eyeshadow'] != null) activeOverlays.add('E');
    if (selectedShades['Blush'] != null) activeOverlays.add('B');
    if (selectedShades['Lipstick'] != null) activeOverlays.add('L');
    
    return activeOverlays.isNotEmpty ? activeOverlays.join('+') : 'none';
  }

  // NEW: Helper method to get current shades in the format expected by API
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

  // NEW: Helper method to convert color to shade type (Primary, Light, Medium, Dark)
  String _getShadeType(String productName, Color color) {
    final shades = makeupShades[productName];
    if (shades == null || shades.isEmpty) return 'Primary';
    
    // Find the index of the selected color
    final index = shades.indexOf(color);
    if (index == -1) return 'Primary';
    
    // Map index to shade type
    switch (index) {
      case 0: return 'Primary';
      case 1: return 'Light';
      case 2: return 'Medium';
      case 3: return 'Dark';
      default: return 'Primary';
    }
  }

  // NEW: Helper method to detect what changed
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

  // NEW: Convert product name to overlay code
  String _getOverlayType(String productName) {
    switch (productName) {
      case 'Eyeshadow': return 'E';
      case 'Blush': return 'B';
      case 'Lipstick': return 'L';
      default: return '';
    }
  }

  // NEW: Helper to update current shades from API response
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

  // NEW: Convert overlay code to product name
  String? _getProductName(String overlayCode) {
    switch (overlayCode) {
      case 'E': return 'Eyeshadow';
      case 'B': return 'Blush';
      case 'L': return 'Lipstick';
      default: return null;
    }
  }

  // NEW: Get color for shade type
  Color? _getColorForShadeType(String productName, String shadeType) {
    final shades = makeupShades[productName];
    if (shades == null) return null;
    
    final index = _getShadeIndex(shadeType);
    return index < shades.length ? shades[index] : null;
  }

  // NEW: Get shade index from type
  int _getShadeIndex(String shadeType) {
    switch (shadeType.toLowerCase()) {
      case 'primary': return 0;
      case 'light': return 1;
      case 'medium': return 2;
      case 'dark': return 3;
      default: return 0;
    }
  }

  // NEW: Fallback method for full combination application
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

  // UPDATED: Apply makeup using the new incremental update API
  Future<void> _applyVirtualMakeup() async {
    if (!_userChoseToCustomize && !_hasSelectedShades()) return;

    final previousImage = _processedImage;
    
    setState(() => _isApplyingMakeup = true);

    try {
      // Convert captured image to base64
      final imageBytes = await widget.capturedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Determine which overlays are currently active
      final currentOverlays = _getCurrentOverlayCode();
      final currentShadesMap = _getCurrentShadesMap();

      // Determine what changed
      final changeInfo = _getChangedOverlayInfo();
      if (changeInfo == null) {
        // No changes detected, use the full combination approach
        await _applyFullCombination(base64Image);
        return;
      }

      // Call the new incremental update API
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
          
          // Update current state with the new overlay combination
          setState(() {
            _processedImage = imageBytes;
            _currentMakeupImage = _processedImage;
            
            // Update shades mapping with the new state
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

  // NEW: Method to remove a specific overlay
  Future<void> removeOverlay(String productName) async {
    setState(() {
      _lastChangedProduct = productName;
      selectedShades[productName] = null;
      currentShades[productName] = 'Primary';
    });

    try {
      final imageBytes = await widget.capturedImage.readAsBytes();
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
          'shade': 'none', // This removes the overlay
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
    }
  }

  Future<void> _applyVirtualMakeupAutomatically(Map<String, dynamic> recommendations) async {
    setState(() => _isApplyingMakeup = true);

    try {
      // Apply initial AI recommendations
      final imageBytes = await widget.capturedImage.readAsBytes();
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
        // Fallback to original image
        final bytes = await widget.capturedImage.readAsBytes();
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
      // Reset to AI recommendations
      setState(() {
        currentShades = {
          'Eyeshadow': 'Primary',
          'Blush': 'Primary',
          'Lipstick': 'Primary',
        };
        selectedShades.updateAll((key, value) => null);
        _userChoseToCustomize = false;
        _lastChangedProduct = null;
      });

      // Re-apply with primary shades
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
              // Store in allRecommendedShades for hybrid approach
              allRecommendedShades[category] = Map<String, String>.from(shadeMap);
              
              // Keep original structure for compatibility
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
              // Store in allRecommendedShades for hybrid approach
              allRecommendedShades[category] = Map<String, String>.from(shadeMap);
              
              // Keep original structure
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

  // UPDATED: Handle shade selection with real-time overlay updates
  Future<void> _handleShadeSelection(String productName, Color color, int index, bool isPrimary) async {
    // Track the product that was changed
    _lastChangedProduct = productName;
    
    final isOverlayProduct = ['Eyeshadow', 'Blush', 'Lipstick'].contains(productName);
    final shadeTypes = ['Primary', 'Light', 'Medium', 'Dark'];
    final shadeType = index < shadeTypes.length ? shadeTypes[index] : 'Primary';

    if (!isPrimary) {
      // For small circles (non-primary shades)
      final wasSelected = selectedShades[productName] == color;
      
      setState(() {
        // Toggle selection - if already selected, unselect it
        if (wasSelected) {
          selectedShades[productName] = null;
          // For overlay products, reset to Primary when unselected
          if (isOverlayProduct) {
            currentShades[productName] = 'Primary';
          }
        } else {
          selectedShades[productName] = color;
          // For overlay products, update current shade
          if (isOverlayProduct) {
            currentShades[productName] = shadeType;
          }
        }
      });
      
      // Apply or remove makeup based on selection changes for overlay products
      if (isOverlayProduct) {
        if (!wasSelected && selectedShades[productName] != null) {
          // A shade was selected - apply makeup
          await _applyVirtualMakeup();
        } else if (wasSelected && selectedShades[productName] == null) {
          // A shade was deselected - remove makeup for this product
          await _applyVirtualMakeup(); // This will re-apply without the deselected shade
        }
      }
    } else {
      // For primary (big circle) shades - only expand/collapse, don't apply makeup
      setState(() {
        expandedProducts[productName] = !expandedProducts[productName]!;
        
        // If clicking primary shade while a custom shade is selected, reset to primary
        if (isOverlayProduct && selectedShades[productName] != null) {
          selectedShades[productName] = null;
          currentShades[productName] = 'Primary';
        }
      });
      
      // Show customization dialog when primary is first clicked
      if (_isFirstTimeSelection && !_hasShownProductDialog[productName]!) {
        _hasShownProductDialog[productName] = true;
        _isFirstTimeSelection = false;
        await showCustomizationDialog();
      }
    }
  }

  Future<void> handleShadeDeselection(String productName) async {
    // Check if any overlay products are still selected
    final hasSelectedOverlay = ['Eyeshadow', 'Blush', 'Lipstick'].any(
      (product) => selectedShades[product] != null
    );
    
    if (hasSelectedOverlay) {
      // If other overlay products are still selected, re-apply makeup
      await _applyVirtualMakeup();
    } else {
      // If no overlay products are selected, reset to AI recommendations
      await _resetToAIRecommendations();
    }
  }

  Future<void> _resetToAIRecommendations() async {
    setState(() {
      _isResetting = true;
    });

    try {
      // Reset all selections
      setState(() {
        currentShades = {
          'Eyeshadow': 'Primary',
          'Blush': 'Primary',
          'Lipstick': 'Primary',
        };
        selectedShades.updateAll((key, value) => null);
        _lastChangedProduct = null;
      });

      // Apply AI recommendations
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
        // Use manually selected shades
        selectedShades.forEach((productType, color) {
          if (color != null) {
            String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
            labeledShades[productType] = [hexColor];
          }
        });
      } else {
        // Use AI-recommended shades
        shadeHexCodes.forEach((productType, hexCodes) {
          if (hexCodes.isNotEmpty) {
            labeledShades[productType] = [hexCodes[0]];
            
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
          color: shade.withOpacity(opacity),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

 // UPDATED: Build nested shade selection without remove button and without shade name labels
Widget _buildShadeItem(Color color, int index, String productName) {
  final isSelected = selectedShades[productName] == color;
  final isPrimary = index == 0;
  final size = isPrimary ? 70.0 : 50.0;
  
  // Determine if this is the medium shade (index 2 in the small circles)
  final isMediumShade = index == 2;

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
                        isMediumShade ? Colors.green : Colors.grey, // Green border only for medium shade
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

  // UPDATED: Clean loading indicator with completely transparent border
  Widget _buildMakeupLoadingIndicator() {
    return Stack(
      children: [
        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        
        // Loading content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading animation
                LoadingAnimationWidget.flickr(
                  leftDotColor: Colors.pinkAccent,
                  rightDotColor: Colors.purpleAccent,
                  size: 60,
                ),
                
                const SizedBox(height: 24),
                
                // Loading text
                Text(
                  'Applying your makeup recommendation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const ui.Color.fromARGB(255, 249, 247, 248),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Creating your perfect ${widget.selectedMakeupLook ?? 'makeup look'}...',
                  style: TextStyle(
                    fontSize: 14,
                    color:  const ui.Color.fromARGB(255, 249, 247, 248),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
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
            // Background image - use current makeup image if available
            Positioned.fill(
              child: _currentMakeupImage != null
                  ? Image.memory(_currentMakeupImage!, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                  : (_processedImage != null
                      ? Image.memory(_processedImage!, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                      : Image.file(widget.capturedImage, fit: BoxFit.cover, filterQuality: FilterQuality.high)),
            ),
            
            // UPDATED: Clean loading indicator with transparent border
            if (_isApplyingMakeup)
              _buildMakeupLoadingIndicator(),
            
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
                                    setState(() {
                                      selectedProduct = product;
                                      showShades = true;
                                    });
                                    
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
                bottom: 120, // Added bottom constraint to avoid overlapping with action buttons
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
                        
                        // Always show the primary shade (big circle)
                        if (makeupShades[selectedProduct]!.isNotEmpty)
                          _buildShadeItem(makeupShades[selectedProduct]![0], 0, selectedProduct!),
                        
                        // Show other shades when expanded (small circles)
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
            
            // Action buttons at bottom - FIXED: Added proper spacing and constraints
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