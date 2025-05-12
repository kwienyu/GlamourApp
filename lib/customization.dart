import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomizationPage extends StatefulWidget {
  final String imagePath;
  final String? selectedMakeupType;
  final String? selectedMakeupLook;
  final String userId;
  final String undertone;
  final String? skinTone;

  const CustomizationPage({
    Key? key,
    required this.imagePath,
    required this.selectedMakeupType,
    required this.selectedMakeupLook,
    required this.userId,
    required this.undertone,
    this.skinTone,
  }) : super(key: key);

  @override
  _CustomizationPageState createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;
  bool isLoading = false;

  Color? selectedFoundationShade;
  Color? selectedConcealerShade;
  Color? selectedContourShade;
  Color? selectedEyeshadowShade;
  Color? selectedBlushShade;
  Color? selectedLipstickShade;
  Color? selectedHighlighterShade;
  Color? selectedEyebrowShade;

  Map<String, List<Color>> makeupShades = {};
  final Map<String, String> productIcons = {
    'foundation': 'assets/foundation.png',
    'concealer': 'assets/concealer.png',
    'contour': 'assets/contour.png',
    'eyeshadow': 'assets/eyeshadow.png',
    'blush': 'assets/blush.png',
    'lipstick': 'assets/lipstick.png',
    'highlighter': 'assets/highlighter.png',
    'eyebrow': 'assets/eyebrow.png',
  };

  final List<String> orderedProductNames = [
    'foundation',
    'concealer',
    'contour',
    'eyeshadow',
    'blush',
    'lipstick',
    'highlighter',
    'eyebrow',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
    if (widget.skinTone != null) {
      print('User skin tone: ${widget.skinTone}');
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
          'skin_tone': widget.skinTone,
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
    print('Product: $productName, Icon Path: $iconPath'); 
    
    if (iconPath == null) {
      return SizedBox(width: 40, height: 40); 
    }

    return Image.asset(
      iconPath,
      width: 45,
      height: 45,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(width: 40, height: 40); 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator()),

          if (!isLoading)
            LayoutBuilder(
              builder: (context, constraints) {
                double imageWidth = constraints.maxWidth;
                double imageHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    if (selectedFoundationShade != null)
                      makeupOverlay(selectedFoundationShade!, imageWidth * 0.3, imageHeight * 0.4, imageWidth * 0.4, imageHeight * 0.4, 0.5),

                    if (selectedConcealerShade != null)
                      makeupOverlay(selectedConcealerShade!, imageWidth * 0.35, imageHeight * 0.45, imageWidth * 0.2, imageHeight * 0.2, 0.5),

                    if (selectedContourShade != null)
                      makeupOverlay(selectedContourShade!, imageWidth * 0.32, imageHeight * 0.48, imageWidth * 0.3, imageHeight * 0.1, 0.5),

                    if (selectedEyeshadowShade != null)
                      makeupOverlay(selectedEyeshadowShade!, imageWidth * 0.45, imageHeight * 0.3, imageWidth * 0.2, imageHeight * 0.05, 0.6),

                    if (selectedBlushShade != null)
                      makeupOverlay(selectedBlushShade!, imageWidth * 0.4, imageHeight * 0.55, imageWidth * 0.2, imageHeight * 0.1, 0.5),

                    if (selectedLipstickShade != null)
                      makeupOverlay(selectedLipstickShade!, imageWidth * 0.45, imageHeight * 0.65, imageWidth * 0.15, imageHeight * 0.05, 0.6),

                    if (selectedHighlighterShade != null)
                      makeupOverlay(selectedHighlighterShade!, imageWidth * 0.43, imageHeight * 0.35, imageWidth * 0.2, imageHeight * 0.07, 0.5),

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
                                            )],        
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
                                    children: (makeupShades[selectedProduct] ?? []).map((shade) {
                                      bool isSelected = false;
                                      switch (selectedProduct) {
                                        case 'foundation':
                                          isSelected = selectedFoundationShade == shade;
                                          break;
                                        case 'concealer':
                                          isSelected = selectedConcealerShade == shade;
                                          break;
                                        case 'contour':
                                          isSelected = selectedContourShade == shade;
                                          break;
                                        case 'eyeshadow':
                                          isSelected = selectedEyeshadowShade == shade;
                                          break;
                                        case 'blush':
                                          isSelected = selectedBlushShade == shade;
                                          break;
                                        case 'lipstick':
                                          isSelected = selectedLipstickShade == shade;
                                          break;
                                        case 'highlighter':
                                          isSelected = selectedHighlighterShade == shade;
                                          break;
                                        case 'eyebrow':
                                          isSelected = selectedEyebrowShade == shade;
                                          break;
                                      }

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            switch (selectedProduct) {
                                              case 'foundation':
                                                selectedFoundationShade = shade;
                                                break;
                                              case 'concealer':
                                                selectedConcealerShade = shade;
                                                break;
                                              case 'contour':
                                                selectedContourShade = shade;
                                                break;
                                              case 'eyeshadow':
                                                selectedEyeshadowShade = shade;
                                                break;
                                              case 'blush':
                                                selectedBlushShade = shade;
                                                break;
                                              case 'lipstick':
                                                selectedLipstickShade = shade;
                                                break;
                                              case 'highlighter':
                                                selectedHighlighterShade = shade;
                                                break;
                                              case 'eyebrow':
                                                selectedEyebrowShade = shade;
                                                break;
                                            }
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
                                              color: isSelected ? Colors.pink : Colors.white,
                                              width: isSelected ? 3 : 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected 
                                                    ? Colors.pink.withOpacity(0.6)
                                                    : Colors.black26,
                                                blurRadius: isSelected ? 6 : 4,
                                                spreadRadius: isSelected ? 1 : 0,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: isSelected
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
                                setState(() {
                                  selectedLipstickShade = null;
                                  selectedFoundationShade = null;
                                  selectedConcealerShade = null;
                                  selectedContourShade = null;
                                  selectedEyeshadowShade = null;
                                  selectedBlushShade = null;
                                  selectedHighlighterShade = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Retake"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                print("Makeup look '${widget.selectedMakeupLook}' saved!");
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Save Look"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}