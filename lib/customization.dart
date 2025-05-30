import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomizationPage extends StatefulWidget {
  final String imagePath;
  final String? selectedMakeupType;
  final String? selectedMakeupLook;
  final String userId;
  final String undertone;
  final String? skinTone;
  final Map<String, dynamic>? recommendationData;

  const CustomizationPage({
    Key? key,
    required this.imagePath,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
    required this.userId,
    required this.undertone,
    this.skinTone,
    this.recommendationData,
  }) : super(key: key);

  @override
  _CustomizationPageState createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;
  bool isLoading = false;

  // Store selected shades for each product type
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

  // Store all recommended shades from API
  Map<String, List<Color>> makeupShades = {};

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

  @override
  void initState() {
    super.initState();
    _processRecommendationData();
    _fetchRecommendations();

  }

  void _processRecommendationData() {
    if (widget.recommendationData != null) {
      final recommendedShades = widget.recommendationData!['recommended_shades'] as Map<String, dynamic>?;
      
      if (recommendedShades != null) {
        setState(() {
          makeupShades.clear();
          recommendedShades.forEach((type, shades) {
            if (shades is List) {
              makeupShades[type] = List<Color>.from(
                shades.map<Color>((hex) => _parseHexColor(hex.toString())),
              );
            }
          });
        });
      }
    }
  }

  Color _parseHexColor(String hexColor) {
    try {
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
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'undertone': widget.undertone,
          'makeup_type': widget.selectedMakeupType,
          'makeup_look': widget.selectedMakeupLook,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final recommendedShades = data['recommended_shades'] as Map<String, dynamic>;

        setState(() {
          makeupShades.clear();
          recommendedShades.forEach((type, shades) {
            makeupShades[type] = List<Color>.from(
              (shades as List).map<Color>((hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')))),
            );
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: ${response.body}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),

          // Makeup Overlays
          ...selectedShades.entries.map((entry) {
            if (entry.value == null) return Container();
            
            final product = entry.key;
            final shade = entry.value!;
            
            switch (product) {
              case 'foundation':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.3, 
                    MediaQuery.of(context).size.height * 0.4, 
                    MediaQuery.of(context).size.width * 0.4, 
                    MediaQuery.of(context).size.height * 0.4, 0.5);
              case 'concealer':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.35, 
                    MediaQuery.of(context).size.height * 0.45, 
                    MediaQuery.of(context).size.width * 0.2, 
                    MediaQuery.of(context).size.height * 0.2, 0.5);
              case 'contour':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.32, 
                    MediaQuery.of(context).size.height * 0.48, 
                    MediaQuery.of(context).size.width * 0.3, 
                    MediaQuery.of(context).size.height * 0.1, 0.5);
              case 'eyeshadow':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.45, 
                    MediaQuery.of(context).size.height * 0.3, 
                    MediaQuery.of(context).size.width * 0.2, 
                    MediaQuery.of(context).size.height * 0.05, 0.6);
              case 'blush':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.4, 
                    MediaQuery.of(context).size.height * 0.55, 
                    MediaQuery.of(context).size.width * 0.2, 
                    MediaQuery.of(context).size.height * 0.1, 0.5);
              case 'lipstick':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.45, 
                    MediaQuery.of(context).size.height * 0.65, 
                    MediaQuery.of(context).size.width * 0.15, 
                    MediaQuery.of(context).size.height * 0.05, 0.6);
              case 'highlighter':
                return makeupOverlay(shade, MediaQuery.of(context).size.width * 0.43, 
                    MediaQuery.of(context).size.height * 0.35, 
                    MediaQuery.of(context).size.width * 0.2, 
                    MediaQuery.of(context).size.height * 0.07, 0.5);
              default:
                return Container();
            }
          }).toList(),

          // Makeup Look Title
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.selectedMakeupLook ?? 'No look selected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Toggle Makeup Products Button
          Positioned(
            left: 10,
            top: 80,
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

          // Makeup Products Panel
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
                          color: Colors.white,
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
                                child: Container(
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
                                      ),
                                    ],
                                    border: Border.all(
                                      color: selectedProduct == product ? Colors.red : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: _buildProductIcon(product),
                                  ),
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

          // Shades Panel
          if (showShades && selectedProduct != null && makeupShades.containsKey(selectedProduct))
            Positioned(
              right: 0,
              top: 140,
              bottom: 0,
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        selectedProduct!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: makeupShades[selectedProduct]!.map((shade) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedShades[selectedProduct!] = shade;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: shade,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedShades[selectedProduct!] == shade 
                                        ? Colors.pink 
                                        : Colors.white,
                                    width: selectedShades[selectedProduct!] == shade ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: selectedShades[selectedProduct!] == shade
                                          ? Colors.pink.withOpacity(0.6)
                                          : Colors.black26,
                                      blurRadius: selectedShades[selectedProduct!] == shade ? 6 : 4,
                                      spreadRadius: selectedShades[selectedProduct!] == shade ? 1 : 0,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: selectedShades[selectedProduct!] == shade
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
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

          // Bottom Buttons
          Positioned(
            bottom: 20,
            left: 55,
            right: 55,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade100.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Retake"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Makeup look '${widget.selectedMakeupLook}' saved!")),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Save Look"),
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