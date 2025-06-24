import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
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

class _CustomizationPageState extends State<CustomizationPage> {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;
  bool isLoading = false;
  bool isSaved = false;

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
    // Skip decoding/encoding for JPEG images to avoid quality loss
    if (imageFile.path.toLowerCase().endsWith('.jpg') || 
        imageFile.path.toLowerCase().endsWith('.jpeg')) {
      return base64Encode(bytes);
    }
    // For other formats, use the image package to convert to JPEG
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    final compressed = img.encodeJpg(image, quality: 85);
    return base64Encode(compressed);
  } catch (e) {
    debugPrint('Image processing error: $e');
    // Fallback to simple base64 encoding if processing fails
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
          offset: const Offset(0, 1), // Adjusted recommended label position
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
              margin: const EdgeInsets.only(bottom: 4), // Reduced bottom margin
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
              offset: const Offset(0, -6), // Moves hex code up closer to circle
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
        ],
      ),
    );
  }
}