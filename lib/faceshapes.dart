import 'package:flutter/material.dart';
import 'package:better_image_shadow/better_image_shadow.dart';
import 'package:animations/animations.dart';

class FaceShapesApp extends StatelessWidget {
  final String userId;
  const FaceShapesApp({Key? key, required this.userId}) : super(key: key);

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
      'icon': 'assets/oval.png',
      'image': 'assets/ovalt_image.png',
      'name': 'Oval Face Shape',
      'description': 'An oval face has a shape where the forehead is slightly wider than the chin. The cheekbones are high, and the face has smooth, balanced lines. This face shape usually works well with many hairstyles and makeup styles.'
    },
    {
      'icon': 'assets/round.png',
      'image': 'assets/round2_image.png',
      'name': 'Round Face Shape',
      'description': 'A round face is almost as wide as it is long. It has full cheeks and a soft, rounded jawline. This face shape does not have sharp angles and often looks youthful.'
    },
    {
      'icon': 'assets/heart.png',
      'image': 'assets/heart2_image.png',
      'name': 'Heart Face Shape',
      'description': 'A heart-shaped face has a wide forehead and high cheekbones that narrow down to a small, pointed chin. It may also have a widow’s peak (a V-shaped hairline). This shape looks like an upside-down triangle.'
    },
    {
      'icon': 'assets/square.png',
      'image': 'assets/square2_image.png',
      'name': 'Square Face Shape',
      'description': 'A square face has a wide forehead, wide cheekbones, and a strong, square jawline. All parts of the face are about the same width. The angles of the face are sharp and well-defined.'
    },
    {
      'icon': 'assets/oblong.png',
      'image': 'assets/oblong2_image.png',
      'name': 'Oblong Face Shape',
      'description': 'An oblong face is longer than it is wide. The forehead, cheekbones, and jawline are about the same width, and the face looks narrow and long. This shape can benefit from styles that add width to the face.'
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
                    'Face Shape Details',
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Icons
                    Container(
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
                    // Right side: Selected shape details with slide animation
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
                                padding: EdgeInsets.only(left: padding * 0.3, top: padding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BetterImage(
                                        image: AssetImage(_selectedShape!['image']!),
                                        height: displayImageSize,
                                        width: displayImageSize,
                                      ),
                                    ),
                                    SizedBox(height: padding),
                                    Text(
                                      _selectedShape!['name']!,
                                      style: TextStyle(
                                        fontSize: fontSizeName,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: padding * 0.5),
                                    Container(
                                      width: displayImageSize,
                                      child: Text(
                                        _selectedShape!['description']!,
                                        style: TextStyle(
                                          fontSize: fontSizeDescription,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                    SizedBox(height: padding * 3), // Extra space for scrolling
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: padding, left: padding * 0.3),
                              child: Center(
                                child: Text(
                                  'Select a face shape to view details',
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

  const FadeTransitionWidget({Key? key, required this.child}) : super(key: key);

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