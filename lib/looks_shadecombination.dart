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

  int _currentComboPage = 0; // Track current page for shade combinations

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
                    top: 90, // Changed from 110 to 90 (moved up by 20 pixels)
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
                        const SizedBox(height: 15), // Reduced from 18 to 15
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
                        if (widget.isDefaultData)
                          const Padding(
                            padding: EdgeInsets.only(top: 6.0), // Reduced from 8.0 to 6.0
                            child: Text(
                              'Popular Looks for New Users',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
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
                              // Top Makeup Look Section
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Column(
                                  children: [
                                    Text(
                                      'Top Makeup Look',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D1B69),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 2),
                                  ],
                                ),
                              ),
                              
                              // ✅ Show only ONE look card (top look)
                              _buildMakeupLookCard(topLooks.first),
                              
                              const SizedBox(height: 20),
                              
                              // Top Shade Combinations Section
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Column(
                                  children: [
                                    Text(
                                      'Top Shade Combinations',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D1B69),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Curated shade combinations tailored for your features',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Shade Combinations Cards
                              _buildShadeCombinationsSection(topLooks.first, widget.isDefaultData),
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

  Widget _buildMakeupLookCard(Map<String, dynamic> look) {
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    look['makeup_look_name']?.toString() ?? 'Unnamed Look',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1B69),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFFB347)]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Recommended for your features',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadeCombinationsSection(Map<String, dynamic> look, bool isDefaultData) {
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

    return SizedBox(
      height: 350,
      child: PageView.builder(
        itemCount: displayCombinations.length,
        onPageChanged: (index) {
          setState(() => _currentComboPage = index);
        },
        itemBuilder: (context, index) {
          var combo = displayCombinations[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  if (!isDefaultData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Used ${combo['times_used'] ?? 0} times',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  if (!isDefaultData) const SizedBox(height: 12),

                  // Shade chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 15,
                        runSpacing: 12,
                        children: (combo['shades'] as List)
                            .where((shade) => shade != null)
                            .map<Widget>((shade) => _buildEnhancedShadeChip(shade))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedShadeChip(Map<String, dynamic> shade) {
    final hexCode = shade['hex_code']?.toString() ?? '#FFFFFF';
    final shadeName = shade['shade_name']?.toString() ?? hexCode;
    final color = _parseColor(hexCode);
    final textColor = _getContrastColor(hexCode);

    return Tooltip(
      message: shadeName,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                shadeName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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

  Color _getContrastColor(String hexColor) {
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
    path.lineTo(0, size.height * 0.70); // Adjusted from 0.75 to 0.70

    // First curve (left → right, top part of S) - moved upward
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.60, // control point (adjusted from 0.65)
      size.width * 0.5, size.height * 0.65,  // end point (adjusted from 0.70)
    );

    // Second curve (right → left, bottom part of S) - moved upward
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.70, // control point (adjusted from 0.75)
      size.width, size.height * 0.55,        // end point (adjusted from 0.60)
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