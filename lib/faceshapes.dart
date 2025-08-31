import 'package:flutter/material.dart';
import 'package:better_image_shadow/better_image_shadow.dart';
import 'package:animations/animations.dart';

class FaceShapesApp extends StatelessWidget {
  final String userId;
  const FaceShapesApp({super.key, required this.userId});

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
          title: Container(
            width: double.infinity,
            child: Image.asset(
              'assets/glam_logo.png',
              height: MediaQuery.of(context).size.height * 0.08, // Slightly reduced height
              fit: BoxFit.contain,
            ),
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
  int? _selectedIndex;

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
      'description': 'A heart-shaped face has a wide forehead and high cheekbones that narrow down to a small, pointed chin. It may also have a widows peak (a V-shaped hairline). This shape looks like an upside-down triangle.'
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

  void _onShapeTap(Map<String, String> shape, int index) {
    setState(() {
      _selectedShape = shape;
      _selectedIndex = index;
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
              SizedBox(height: padding * 1),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding * 0.3, vertical: padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: iconSize + padding * 2,
                      child: Column(
                        children: faceShapes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final shape = entry.value;
                          final isSelected = index == _selectedIndex;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: padding),
                            child: GestureDetector(
                              onTap: () => _onShapeTap(shape, index),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  border: Border.all(
                                    color: isSelected ? Colors.pinkAccent : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.pinkAccent.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    shape['icon']!,
                                    width: iconSize * 0.8,
                                    height: iconSize * 0.8,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.error, color: Colors.white);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                                    SizedBox(
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
                                    SizedBox(height: padding * 3),
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