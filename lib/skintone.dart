import 'package:flutter/material.dart';
import 'package:better_image_shadow/better_image_shadow.dart';
import 'package:animations/animations.dart';

class SkinTone extends StatelessWidget {
  final String userId;
  const SkinTone({super.key, required this.userId});

   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 11, 11, 11)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.pinkAccent,
          elevation: 0,
          title: Image.asset(
            'assets/glam_logo.png',
            height: MediaQuery.of(context).size.height * 0.10,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FaceShapesWidget(),
        ),
      ),
    );
  }
}

class FaceShapesWidget extends StatefulWidget {
  const FaceShapesWidget({super.key});

  @override
  _FaceShapesWidgetState createState() => _FaceShapesWidgetState();
}

class _FaceShapesWidgetState extends State<FaceShapesWidget> {
  Map<String, String>? _selectedShape;

  final faceShapes = [
    {
      'icon': 'assets/morena-ic2.png',
      'image': 'assets/Morena-tone.jpg',
      'name': 'Morena Skin Tone',
      'description': 'Morena skin tones range from dark brown to warm brown. These shades include deep dark brown, medium brown, light brown, and warm brown. The tone is rich, earthy, and radiant, often with a naturally warm and vibrant appearance.'
    },
    {
      'icon': 'assets/mestiza-ic.png',
      'image': 'assets/Mestiza-tone.jpg',
      'name': 'Mestiza Skin Tone',
      'description': 'Mestiza skin tones range from golden tan to light tan shades. This includes warm tones like golden, light golden, medium tan, warm tan, and light tan. The overall look is soft, sun-kissed, and naturally glowing with beige or golden undertones.'
    },
     {
      'icon': 'assets/chinita-ic.png',
      'image': 'assets/Chinita-tone.jpg',
      'name': 'Chinita Skin Tone',
      'description': 'Chinita skin tones range from soft pink to pale beige. This includes light and delicate shades such as soft pink, light beige, and pale pink. The overall effect is smooth, bright, and fresh, often with cool or neutral undertones.'
    },
  ];

  void _onShapeTap(Map<String, String> shape) {
    setState(() {
      _selectedShape = shape;
    });
  }

  @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final iconSize = screenWidth * 0.20;
      final padding = screenWidth * 0.06;
      final displayImageSize = screenWidth * 0.70;
      final fontSizeTitle = screenWidth * 0.08;
      final fontSizeName = screenWidth * 0.05;
      final fontSizeDescription = screenWidth * 0.045;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Increased space below AppBar
              SizedBox(height: padding * 1),
              // Centered "Face Shape Details" text with fade animation
              FadeTransitionWidget(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: padding),
                  child: Text(
                    'Skin Tone Details',
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Main content with icons on left and details on right
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding * 0.3, vertical: padding),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Icons
                        SizedBox(
                          width: iconSize + padding * 2,
                          child: Column(
                            children: faceShapes.map((shape) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: padding),
                                child: GestureDetector(
                                  onTap: () => _onShapeTap(shape),
                                  child: Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      border: Border.all(color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      shape['icon']!,
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(Icons.error, color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Right side: Selected shape image
                        Expanded(
                          child: _selectedShape != null
                              ? PageTransitionSwitcher(
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> primaryAnimation,
                                    Animation<double> secondaryAnimation,
                                  ) {
                                    return SharedAxisTransition(
                                      animation: primaryAnimation,
                                      secondaryAnimation: secondaryAnimation,
                                      transitionType: SharedAxisTransitionType.horizontal,
                                      child: child,
                                    );
                                  },
                                  child: Padding(
                                    key: ValueKey(_selectedShape!['name']),
                                    padding: EdgeInsets.only(left: padding * 0.3),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BetterImage(
                                        image: AssetImage(_selectedShape!['image']!),
                                        height: displayImageSize,
                                        width: displayImageSize,
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                              padding: EdgeInsets.only(top: padding, left: padding * 0.3),
                              child: Center(
                                child: Text(
                                  'Select a skin tone to view details',
                                  style: TextStyle(
                                    fontSize: fontSizeName,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                        ),
                      ],
                    ),
                    // Name and description below the icons and image
                    if (_selectedShape != null)
                      Padding(
                        padding: EdgeInsets.only(top: padding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _selectedShape!['name']!,
                              style: TextStyle(
                                fontSize: fontSizeName,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: padding * 0.5),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: padding),
                              child: Text(
                                _selectedShape!['description']!,
                                style: TextStyle(
                                  fontSize: fontSizeDescription,
                                  fontWeight: FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: padding * 3), // Extra space for scrolling
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget for FadeTransition with controller
class FadeTransitionWidget extends StatefulWidget {
  final Widget child;

  const FadeTransitionWidget({super.key, required this.child});

  @override
  _FadeTransitionWidgetState createState() => _FadeTransitionWidgetState();
}

class _FadeTransitionWidgetState extends State<FadeTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}