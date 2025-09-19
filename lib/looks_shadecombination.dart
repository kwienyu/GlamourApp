// looks_shadecombination.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MakeupLooksPage extends StatefulWidget {
  final int userId;
  final String makeupType;
  final bool isDefaultData;
  final Map<String, dynamic>? apiResponse;

  const MakeupLooksPage({
    super.key,
    required this.userId,
    required this.makeupType,
    this.isDefaultData = false,
    this.apiResponse,
  });

  @override
  State<MakeupLooksPage> createState() => _MakeupLooksPageState();
}

class _MakeupLooksPageState extends State<MakeupLooksPage> {
  late Future<Map<String, dynamic>> recommendationData;
  List<Map<String, dynamic>> makeupLooks = [];
  bool isLoading = true;
  String? errorMessage;
  bool _hasCompletedAnalysis = false;
  String? _faceShape;
  String? _skinTone;
  String? _undertone;

  /// Map makeup types to static profile images
  final Map<String, String> makeupTypeImages = {
    "Light": "assets/light_type.jpg",
    "Casual": "assets/casual_type.png",
    "Heavy": "assets/heavy_type.jpg",
  };

  /// Map of makeup product icons
  final List<Map<String, dynamic>> makeupProducts = [
    {'name': 'All', 'icon': Icons.all_inclusive, 'key': 'all'},
    {'name': 'Foundation', 'iconPath': 'assets/foundation.png', 'key': 'foundation'},
    {'name': 'Concealer', 'iconPath': 'assets/concealer.png', 'key': 'concealer'},
    {'name': 'Contour', 'iconPath': 'assets/contour.png', 'key': 'contour'},
    {'name': 'Eyeshadow', 'iconPath': 'assets/eyeshadow.png', 'key': 'eyeshadow'},
    {'name': 'Blush', 'iconPath': 'assets/blush.png', 'key': 'blush'},
    {'name': 'Lipstick', 'iconPath': 'assets/lipstick.png', 'key': 'lipstick'},
    {'name': 'Highlighter', 'iconPath': 'assets/highlighter.png', 'key': 'highlighter'},
    {'name': 'Eyebrow', 'iconPath': 'assets/eyebrow.png', 'key': 'eyebrow'},
  ];

  String selectedProduct = 'all';

  @override
  void initState() {
    super.initState();
    _checkAnalysisStatus();
  }

  Future<void> _checkAnalysisStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _faceShape = prefs.getString('face_shape');
      _skinTone = prefs.getString('skin_tone');
      _undertone = prefs.getString('user_undertone');

      setState(() {
        _hasCompletedAnalysis = _faceShape != null && 
                              _faceShape != "Not Available" && 
                              _faceShape != "Not analyzed" &&
                              _skinTone != null && 
                              _skinTone != "Not Available" && 
                              _skinTone != "Not analyzed" &&
                              _undertone != null && 
                              _undertone != "Not Available" && 
                              _undertone != "Not analyzed";
      });

      if (_hasCompletedAnalysis) {
        if (widget.apiResponse != null) {
          _processApiResponse(widget.apiResponse!);
        } else {
          recommendationData = _fetchRecommendationData();
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error checking analysis status: $e';
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchRecommendationData() async {
    try {
      final response = await http.get(
        Uri.parse('http://your-api-url/${widget.userId}/full_recommendation'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _processApiResponse(data);
        return data;
      } else {
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
      rethrow;
    }
  }

  void _processApiResponse(Map<String, dynamic> data) {
    final List<dynamic> topLooksByType = data['top_makeup_looks_by_type'] ?? [];
    final List<dynamic> mostUsedSavedLooks = data['most_used_saved_looks'] ?? [];
    
    List<Map<String, dynamic>> allLooks = [];
    
    for (var look in topLooksByType) {
      if (look['makeup_type_name'] == widget.makeupType) {
        allLooks.add(_convertApiLookToFlutterLook(look, 'recommendation'));
      }
    }
    
    for (var look in mostUsedSavedLooks) {
      if (look['makeup_type_name'] == widget.makeupType) {
        allLooks.add(_convertApiLookToFlutterLook(look, 'user_saved'));
      }
    }

    setState(() {
      makeupLooks = allLooks;
      isLoading = false;
    });
  }

  Map<String, dynamic> _convertApiLookToFlutterLook(
      Map<String, dynamic> apiLook, String source) {
    
    List<Map<String, dynamic>> shades = [];
    
    if (source == 'recommendation') {
      final shadesByType = apiLook['shades_by_type'] ?? {};
      shadesByType.forEach((shadeType, shadeList) {
        for (var shade in shadeList) {
          shades.add({
            'shade_id': shade['shade_id'],
            'hex_code': shade['hex_code'],
            'shade_name': shade['shade_name'],
            'product_type': shadeType.toLowerCase(),
            'times_used': apiLook['usage_count'] ?? 0,
          });
        }
      });
    } else if (source == 'user_saved' && apiLook['shade'] != null) {
      final shade = apiLook['shade'];
      shades.add({
        'shade_id': shade['shade_id'],
        'hex_code': shade['hex_code'],
        'shade_name': shade['shade_name'],
        'product_type': (shade['shade_type'] ?? 'unknown').toString().toLowerCase(),
        'times_used': apiLook['save_count'] ?? 0,
      });
    }

    return {
      'makeup_look_id': apiLook['makeup_look_id'],
      'makeup_look_name': apiLook['makeup_look_name'],
      'makeup_type_name': apiLook['makeup_type_name'],
      'times_used': apiLook['usage_count'] ?? apiLook['save_count'] ?? 0,
      'source': source,
      'shades_by_type': apiLook['shades_by_type'],
      'shade_combinations': [
        {
          'combination_id': '${apiLook['makeup_look_id']}_1',
          'shades': shades,
          'times_used': apiLook['usage_count'] ?? apiLook['save_count'] ?? 0,
        }
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF8F6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Color(0xFFFDF8F6),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2D1B69),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_hasCompletedAnalysis) {
      return _buildAnalysisRequiredScreen();
    }

    String? profileImagePath = makeupTypeImages[widget.makeupType];

    List<Map<String, dynamic>> sortedLooks = List.from(makeupLooks)
      ..sort((a, b) => (b['times_used'] ?? 0).compareTo(a['times_used'] ?? 0));

    List<Map<String, dynamic>> topLooks =
        sortedLooks.isNotEmpty ? [sortedLooks.first] : [];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F6),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE91E63),
                          Color(0xFFD81B60),
                          Color(0xFFAD1457),
                          Color.fromARGB(255, 252, 138, 184),
                          Color.fromARGB(255, 247, 108, 182),
                        ],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                      top: 40, right: 30, child: _buildFloatingElement(60, 0.1)),
                  Positioned(
                      top: 80, left: 40, child: _buildFloatingElement(30, 0.15)),
                  Positioned(
                      bottom: 60,
                      right: 60,
                      child: _buildFloatingElement(45, 0.12)),
                  ClipPath(
                    clipper: EnhancedUShapeClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 155,
                          height: 155,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFFFF3F3)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE91E63),
                                  width: 3,
                                ),
                              ),
                              child: profileImagePath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        profileImagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildNoImageAvailable();
                                        },
                                      ),
                                    )
                                  : _buildNoImageAvailable(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '${widget.makeupType} Makeup Type',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black26),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF8F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: topLooks.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Curated shade combinations tailored for your features',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(179, 4, 4, 4),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Top Recommendations',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D1B69),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _buildCombinedCard(topLooks.first, widget.isDefaultData),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRequiredScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE91E63).withOpacity(0.2),
                      const Color.fromARGB(255, 255, 108, 186).withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.face_retouching_natural,
                  size: 60,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Complete Your Face Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B69),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To see personalized makeup recommendations and top shades, please complete your face analysis first.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildAnalysisStatus(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisStatus() {
    return Column(
      children: [
        _buildAnalysisItem('Face Shape', _faceShape),
        const SizedBox(height: 12),
        _buildAnalysisItem('Skin Tone', _skinTone),
        const SizedBox(height: 12),
        _buildAnalysisItem('Undertone', _undertone),
      ],
    );
  }

  Widget _buildAnalysisItem(String title, String? status) {
    final isCompleted = status != null && 
                       status != "Not Available" && 
                       status != "Not analyzed";
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.circle,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        if (!isCompleted)
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildNoImageAvailable() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF5F5F5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 40,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image\nAvailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingElement(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE91E63).withOpacity(0.2),
                      const Color.fromARGB(255, 255, 108, 186).withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Icon(Icons.palette,
                    size: 50, color: Color(0xFFE91E63)),
              ),
              const SizedBox(height: 24),
              Text(
                'No ${widget.makeupType} looks available',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D1B69),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'re working on adding more amazing looks for you!',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildCombinedCard(Map<String, dynamic> look, bool isDefaultData) {
    final combinations = (look['shade_combinations'] as List).cast<Map<String, dynamic>>().toList();
    
    List<Map<String, dynamic>> displayCombinations;
    
    if (isDefaultData) {
      displayCombinations = combinations;
    } else {
      combinations.sort((a, b) =>
          (b['times_used'] ?? 0).compareTo(a['times_used'] ?? 0));
      displayCombinations = combinations.take(3).toList();
    }

    List<dynamic> shades = displayCombinations.isNotEmpty 
        ? (displayCombinations.first['shades'] as List).where((shade) => shade != null).toList()
        : [];

    // Extract top 3 most used shades for each product type from shades_by_type
    Map<String, List<dynamic>> mostUsedShadesByProduct = {};
    
    // Process shades_by_type from API response
    if (look['shades_by_type'] != null && look['shades_by_type'] is Map) {
      final shadesByType = Map<String, dynamic>.from(look['shades_by_type']);
      
      shadesByType.forEach((productType, shadeList) {
        if (shadeList is List) {
          final List<dynamic> productShades = List.from(shadeList);
          
          // Sort by usage count (assuming usage_count is available, otherwise use times_used)
          productShades.sort((a, b) {
            final aCount = a['usage_count'] ?? a['times_used'] ?? 0;
            final bCount = b['usage_count'] ?? b['times_used'] ?? 0;
            return bCount.compareTo(aCount);
          });
          
          // Take top 3 shades
          mostUsedShadesByProduct[productType.toLowerCase()] = productShades.take(3).toList();
        }
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF8F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: const Color(0xFFE91E63).withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                look['makeup_look_name']?.toString() ?? 'Unnamed Look',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B69),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _buildProductCategories(),
            const SizedBox(height: 20),
            
            // Top 3 Most Used Shades Section
            if (mostUsedShadesByProduct.isNotEmpty) ...[
              const Text(
                'Top 3 Most Used Shades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B69),
                ),
              ),
              const SizedBox(height: 12),
              _buildProductShadesSection(mostUsedShadesByProduct),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCategories() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: makeupProducts.length,
        itemBuilder: (context, index) {
          final product = makeupProducts[index];
          final isSelected = selectedProduct == product['key'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedProduct = product['key'];
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE91E63).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product['key'] == 'all')
                    Icon(
                      product['icon'],
                      size: 32,
                      color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                    )
                  else
                    Image.asset(
                      product['iconPath'],
                      width: 32,
                      height: 32,
                      color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductShadesSection(Map<String, List<dynamic>> shadesByProduct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...shadesByProduct.entries.map((entry) {
          final productType = entry.key;
          final productShades = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${productType[0].toUpperCase()}${productType.substring(1)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.2,
                ),
                itemCount: productShades.length,
                itemBuilder: (context, index) {
                  final shade = productShades[index];
                  final usageCount = shade['usage_count'] ?? shade['times_used'] ?? 0;
                  
                  return Column(
                    children: [
                      _buildEnhancedShadeChip(shade),
                      const SizedBox(height: 4),
                      Text(
                        shade['shade_name']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$usageCount uses',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
    ],
  );
}

Widget _buildEnhancedShadeChip(Map<String, dynamic> shade) {
  final hexCode = shade['hex_code']?.toString() ?? '#FFFFFF';
  final color = _parseColor(hexCode);

  return Center(
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    ),
  );
}

Color _parseColor(String hexColor) {
  try {
    return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
  } catch (e) {
    return Colors.white;
  }
}
}

class EnhancedUShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.70);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.60,
      size.width * 0.5, size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.70,
      size.width, size.height * 0.55,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}