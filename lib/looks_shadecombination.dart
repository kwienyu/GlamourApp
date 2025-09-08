// looks_shadecombination.dart
import 'package:flutter/material.dart';

class MakeupLooksPage extends StatefulWidget {
  final List<dynamic> makeupLooks;
  final String makeupType;
  final bool isDefaultData;

  const MakeupLooksPage({
    super.key,
    required this.makeupLooks,
    required this.makeupType,
    this.isDefaultData = false,
  });

  @override
  State<MakeupLooksPage> createState() => _MakeupLooksPageState();
}

class _MakeupLooksPageState extends State<MakeupLooksPage> {
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

  String selectedProduct = 'all'; // Track selected product

  @override
  Widget build(BuildContext context) {
    // ✅ Get image path based on type or null if not available
    String? profileImagePath = makeupTypeImages[widget.makeupType];

    // ✅ Sort makeup looks by recommendation (times_used or score)
    List<Map<String, dynamic>> sortedLooks = widget.makeupLooks
        .cast<Map<String, dynamic>>()
      ..sort((a, b) =>
          (b['times_used'] ?? 0).compareTo(a['times_used'] ?? 0));

    // ✅ Only take the top look
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
                  // Gradient background
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

                  // Floating decorative elements
                  Positioned(
                      top: 40, right: 30, child: _buildFloatingElement(60, 0.1)),
                  Positioned(
                      top: 80, left: 40, child: _buildFloatingElement(30, 0.15)),
                  Positioned(
                      bottom: 60,
                      right: 60,
                      child: _buildFloatingElement(45, 0.12)),

                  // Curved background - moved upward
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

                  // Profile section (static image per type) - MOVED UPWARD
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

          // Content
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: topLooks.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              // Moved the curated text to the top of recommendations
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Currated shade combinations tailored for your features',
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
                              
                              // Combined Makeup Look and Shade Combinations Card
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
    final combinations =
        (look['shade_combinations'] as List).cast<Map<String, dynamic>>().toList();
    
    // For default data, just show all combinations
    // For user data, sort by times_used and take top 3
    List<Map<String, dynamic>> displayCombinations;
    
    if (isDefaultData) {
      displayCombinations = combinations;
    } else {
      combinations.sort((a, b) =>
          (b['times_used'] ?? 0).compareTo(a['times_used'] ?? 0));
      displayCombinations = combinations.take(3).toList();
    }

    // Get the first combination's shades
    List<dynamic> shades = displayCombinations.isNotEmpty 
        ? (displayCombinations.first['shades'] as List).where((shade) => shade != null).toList()
        : [];

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
            // Makeup Look Name
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
            
            // Makeup Product Categories - Horizontal Scroll
            _buildProductCategories(),
            
            const SizedBox(height: 20),
            
            // Shade chips - arranged in a grid with 3 shades per row
            _buildShadesGrid(shades),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCategories() {
    return SizedBox(
      height: 100, // Fixed height for the horizontal scroll
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
                  // Icon or Image
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
                  
                  // Product Name
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

  Widget _buildShadesGrid(List<dynamic> shades) {
    if (shades.isEmpty) {
      return const Center(
        child: Text(
          'No shades available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Filter shades based on selected product
    List<dynamic> filteredShades = shades;
    if (selectedProduct != 'all') {
      filteredShades = shades.where((shade) => 
          shade['product_type']?.toString().toLowerCase() == selectedProduct).toList();
    }

    if (filteredShades.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(
              'No $selectedProduct shades available',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 shades per row
        crossAxisSpacing: 12, // Reduced spacing
        mainAxisSpacing: 12, // Reduced spacing
        childAspectRatio: 1.0,
      ),
      itemCount: filteredShades.length,
      itemBuilder: (context, index) {
        return _buildEnhancedShadeChip(filteredShades[index]);
      },
    );
  }

  Widget _buildEnhancedShadeChip(Map<String, dynamic> shade) {
    final hexCode = shade['hex_code']?.toString() ?? '#FFFFFF';
    final color = _parseColor(hexCode);

    return Center(
      child: Container(
        width: 50, // Reduced from 60 to 50
        height: 50, // Reduced from 60 to 50
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1.5), // Slightly thinner border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4, // Reduced blur radius
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

  Color getContrastColor(String hexColor) {
    try {
      final color = _parseColor(hexColor);
      final brightness = color.computeLuminance();
      return brightness > 0.5 ? Colors.black : Colors.white;
    } catch (e) {
      return Colors.black;
    }
  }
}

class EnhancedUShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Start from top-left
    path.lineTo(0, size.height * 0.70);

    // First curve (left → right, top part of S) - moved upward
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.60,
      size.width * 0.5, size.height * 0.65,
    );

    // Second curve (right → left, bottom part of S) - moved upward
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.70,
      size.width, size.height * 0.55,
    );

    // Close shape (right side → bottom → left)
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}