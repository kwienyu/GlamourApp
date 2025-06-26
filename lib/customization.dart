import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'camera2.dart';
import 'glamvault.dart';

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
    
    // Heart animation setup
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

  void _processRecommendationData() {
    if (widget.recommendationData != null) {
      final recommendations = widget.recommendationData!['recommendations'] as Map<String, dynamic>?;
      if (recommendations != null) {
        setState(() {
          makeupShades.clear();
          shadeHexCodes.clear();
          recommendations.forEach((category, shadeMap) {
            if (shadeMap is Map) {
              final shadeTypes = ['Light', 'Medium', 'Dark'];
              shadeHexCodes[category] = [];
              makeupShades[category] = [];
              
              for (var shadeType in shadeTypes) {
                if (shadeMap.containsKey(shadeType)) {
                  final hexCode = shadeMap[shadeType] as String;
                  shadeHexCodes[category]!.add(hexCode);
                  makeupShades[category]!.add(_parseHexColor(hexCode));
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
              final shadeTypes = ['Light', 'Medium', 'Dark'];
              shadeHexCodes[category] = [];
              makeupShades[category] = [];
              
              for (var shadeType in shadeTypes) {
                if (shadeMap.containsKey(shadeType)) {
                  final hexCode = shadeMap[shadeType] as String;
                  shadeHexCodes[category]!.add(hexCode);
                  makeupShades[category]!.add(_parseHexColor(hexCode));
                }
              }
            }
          });
        });
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
    } catch (e) {
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

    final imageBytes = await widget.capturedImage.readAsBytes();
    final base64Image = base64Encode(imageBytes);


    Map<String, List<String>> labeledShades = {};
    selectedShades.forEach((productType, color) {
      if (color != null) {
        String hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
        labeledShades[productType] = [hexColor];
      }
    });

    if (labeledShades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shades selected to save')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('https://glamouraika.com/api/saved_looks');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'makeup_look': widget.selectedMakeupLook,
          'shades': labeledShades,
          'image_data': base64Image,
          'is_client_look': false, 
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        await _cacheSavedLook(
          responseData['saved_look_id'],
          widget.selectedMakeupLook!,
          base64Image,
          labeledShades, 
        );

        setState(() {
          isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Look saved successfully to the glamvault!")),
        );

        // Navigate to GlamVault after saving
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GlamVaultScreen(userId: int.parse(widget.userId)),
        ),
      );
      
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save look: ${errorData['error'] ?? response.body}')),
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
    final isRecommended = index == 0;
    final size = isRecommended ? 60.0 : 50.0;
    final hexCode = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecommended)
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
                    color: isSelected ? Colors.pink : 
                          isRecommended ? Colors.green : Colors.grey,
                    width: isRecommended ? 3 : 2,
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
                child: isSelected
                    ? Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.black,
                            size: size * 0.4,
                          ),
                        ),
                      )
                    : null,
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.3),
                  ),
                  child: Text(
                    hexCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 4, 4, 4),
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              widget.capturedImage,
              fit: BoxFit.cover,
            ),
          ),
          ...selectedShades.entries.map((entry) {
            if (entry.value == null) return Container();
            final product = entry.key;
            final shade = entry.value!;
            switch (product) {
              case 'Foundation':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.4,
                    MediaQuery.of(context).size.width * 0.4, MediaQuery.of(context).size.height * 0.4, 0.5);
              case 'Concealer':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.35, MediaQuery.of(context).size.height * 0.45,
                    MediaQuery.of(context).size.width * 0.2, MediaQuery.of(context).size.height * 0.2, 0.5);
              case 'Contour':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.32, MediaQuery.of(context).size.height * 0.48,
                    MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.1, 0.5);
              case 'Eyeshadow':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.45, MediaQuery.of(context).size.height * 0.3,
                    MediaQuery.of(context).size.width * 0.2, MediaQuery.of(context).size.height * 0.05, 0.6);
              case 'Blush':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.4, MediaQuery.of(context).size.height * 0.55,
                    MediaQuery.of(context).size.width * 0.2, MediaQuery.of(context).size.height * 0.1, 0.5);
              case 'Lipstick':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.45, MediaQuery.of(context).size.height * 0.65,
                    MediaQuery.of(context).size.width * 0.15, MediaQuery.of(context).size.height * 0.05, 0.6);
              case 'Highlighter':
                return makeupOverlay(
                    shade, MediaQuery.of(context).size.width * 0.43, MediaQuery.of(context).size.height * 0.35,
                    MediaQuery.of(context).size.width * 0.2, MediaQuery.of(context).size.height * 0.07, 0.5);
              default:
                return Container();
            }
          }),
          Positioned(
            left: 10,
            top: 100,
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
              top: 140,
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
          if (showShades && selectedProduct != null && makeupShades.containsKey(selectedProduct))
            Positioned(
              right: 0,
              top: 140,
              bottom: 0,
              child: Container(
                width: 100,
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
                    const SizedBox(height: 2),
                    Expanded(
                      child: ListView(
                        children: makeupShades[selectedProduct]!.asMap().entries.map((entry) {
                          return _buildShadeItem(entry.value, entry.key);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.2,
            right: MediaQuery.of(context).size.width * 0.2,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(width: 10),
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
                            : const Text("Save Look"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Add the new animated feedback heart icon
          if (_showHeart)
            Positioned(
              right: 20,
              top: 95,
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
                        // Glitter effect
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
          'recommendation_id': widget.recommendationId,
          'user_id': widget.userId,
          'rating': _rating,
          'comment': _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Feedback submitted successfully')),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Missing required fields')),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Recommendation not found')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to submit feedback')),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request timed out')),
      );
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
          height: MediaQuery.of(context).size.height * 0.46, // Adjusted height
          padding: const EdgeInsets.all(20), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                 Colors.pink.shade200,
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
              SingleChildScrollView( // Added for scrollable content
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
                        size: 36, // Slightly smaller icon
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10), // Reduced spacing
                    Text(
                      'Share Your Glam Experience',
                      style: TextStyle(
                        fontSize: 18, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [Colors.pink.shade700, Colors.purple.shade700],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15), // Reduced spacing
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
                            margin: const EdgeInsets.symmetric(horizontal: 4), // Tighter spacing
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
                                size: 32, // Slightly smaller stars
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15), // Reduced spacing
                    Container(
                      height: 90, // Fixed height for text field
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
                        maxLines: 3, // Reduced max lines
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
                    const SizedBox(height: 15), // Reduced spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // Smaller buttons
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.7),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: Colors.pink.shade800,
                              fontSize: 13, // Smaller font
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // Smaller buttons
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
                                      fontSize: 13, // Smaller font
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