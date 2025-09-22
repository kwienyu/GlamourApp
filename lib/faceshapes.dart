import 'package:flutter/material.dart';
import 'package:better_image_shadow/better_image_shadow.dart';

class FaceShapesApp extends StatelessWidget {
  final String userId;
  const FaceShapesApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 7, 7, 7)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Image.asset(
            'assets/glam_logo.png',
            height: MediaQuery.of(context).size.height * 0.10,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Image.asset(
                'assets/face_shapeicon.png',
                height: MediaQuery.of(context).size.height * 0.05,
                fit: BoxFit.contain,
              ),
            ),
          ],
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
  FaceShapesWidgetState createState() => FaceShapesWidgetState();
}

class FaceShapesWidgetState extends State<FaceShapesWidget> {
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

  void _onShapeTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Dynamic sizing based on screen dimensions
        final bool isSmallScreen = screenWidth < 350;
        final bool isLargeScreen = screenWidth > 600;
        final bool isLandscape = screenWidth > screenHeight;
        
        // Responsive values - Increased icon size
        final double basePadding = isSmallScreen ? 8.0 : 12.0;
        final double iconSize = isLandscape 
            ? screenHeight * 0.14
            : isLargeScreen 
                ? screenWidth * 0.14
                : screenWidth * 0.18;
        
        final double displayImageSize = isLandscape
            ? screenHeight * 0.4
            : screenWidth * 0.7;
        
        final double fontSizeTitle = isSmallScreen 
            ? screenWidth * 0.06 
            : screenWidth * 0.065;
        
        final double fontSizeName = isSmallScreen 
            ? screenWidth * 0.045 
            : screenWidth * 0.05;
        
        final double fontSizeDescription = isSmallScreen 
            ? screenWidth * 0.035 
            : screenWidth * 0.04;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Title Section
                Padding(
                  padding: EdgeInsets.all(basePadding * 1.5),
                  child: FadeTransitionWidget(
                    child: Column(
                      children: [
                        Text(
                          'Face Shape Details',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: basePadding * 0.5),
                        // Swipe Instruction Text
                        Text(
                          'Click on a face shape icon to view details',
                          style: TextStyle(
                            fontSize: fontSizeDescription * 0.8,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Face Shape Icons - Horizontal Scrollable if needed
                Container(
                  height: isLandscape ? screenHeight * 0.28 : screenHeight * 0.22,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: basePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: faceShapes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final shape = entry.value;
                          final isSelected = index == _selectedIndex;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: basePadding),
                            child: GestureDetector(
                              onTap: () => _onShapeTap(index),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon Container
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                              )
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              )
                                            ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(basePadding * 0.8),
                                      child: Image.asset(
                                        shape['icon']!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.face, color: Colors.grey);
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: basePadding),
                                  
                                  // Shape Name
                                  Container(
                                    width: iconSize * 1.5,
                                    child: Text(
                                      shape['name']!.replaceAll(' Face Shape', ''),
                                      style: TextStyle(
                                        fontSize: fontSizeName * 0.8,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.pinkAccent : Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                ),

                // Content Section - Flexible to use remaining space
                Expanded(
                  child: _selectedIndex == null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(basePadding * 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face, size: 48, color: Colors.grey),
                                SizedBox(height: basePadding),
                                Text(
                                  'Select a face shape to view details',
                                  style: TextStyle(
                                    fontSize: fontSizeName,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(basePadding * 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Image
                              Container(
                                width: displayImageSize,
                                height: displayImageSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BetterImage(
                                    image: AssetImage(faceShapes[_selectedIndex!]['image']!),
                                    width: displayImageSize,
                                    height: displayImageSize,
                                  ),
                                ),
                              ),
                              
                              // Reduced spacing between image and text
                              SizedBox(height: basePadding),
                              
                              // Shape Name
                              Text(
                                faceShapes[_selectedIndex!]['name']!,
                                style: TextStyle(
                                  fontSize: fontSizeName,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              SizedBox(height: basePadding * 0.3),
                              
                              // Description - Now positioned closer to the image
                              Container(
                                width: displayImageSize,
                                padding: EdgeInsets.symmetric(horizontal: basePadding * 0.5),
                                child: Text(
                                  faceShapes[_selectedIndex!]['description']!,
                                  style: TextStyle(
                                    fontSize: fontSizeDescription,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                              
                              SizedBox(height: basePadding * 3),
                            ],
                          ),
                        ),
                ),
              ],
            ),
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
  FadeTransitionWidgetState createState() => FadeTransitionWidgetState();
}

class FadeTransitionWidgetState extends State<FadeTransitionWidget>
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