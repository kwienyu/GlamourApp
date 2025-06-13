import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glamour App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Arial',
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('assets/phone.png'),
                fit: BoxFit.cover,
              )),
              ),
              Positioned(
                bottom: constraints.maxHeight * 0.2,
                left: 0,
                right: 0,
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.pinkAccent,
                    size: constraints.maxWidth * 0.12, // Responsive size
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = false;

  void _handleGetStarted() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive values
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final curvedContainerHeight = screenHeight * 0.4;
          const curveHeightFraction = 0.25;
          final logoSize = screenWidth * 0.3; // Increased from 0.2 to 0.3 (50% bigger)
          final logoTopPosition = screenHeight * 0.63; // Lowered from 0.65 to 0.55
          final buttonWidth = screenWidth * 0.5;
          final buttonHeight = screenHeight * 0.07;

          return Stack(
            children: [
              // Full background image with shimmer effect
              Shimmer(
                duration: const Duration(seconds: 3),
                color: Colors.white,
                colorOpacity: 0.3,
                enabled: true,
                direction: ShimmerDirection.fromLeftToRight(),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/phone_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Pink Inverted U-Shaped Container at Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  painter: InvertedUBorderPainter(
                    curveHeight: curvedContainerHeight * curveHeightFraction,
                    borderWidth: screenWidth * 0.015,
                  ),
                  child: ClipPath(
                    clipper: CurvedEdgeRectangleClipper(
                      curveHeight: curvedContainerHeight * curveHeightFraction,
                    ),
                    child: Shimmer(
                      duration: const Duration(seconds: 3),
                      color: Colors.white,
                      colorOpacity: 0.3,
                      enabled: true,
                      direction: ShimmerDirection.fromLeftToRight(),
                      child: Container(
                        height: curvedContainerHeight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFAD0C4),
                              Colors.pinkAccent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Logo positioned on top of the U-shape
              Positioned(
  top: logoTopPosition,
  left: 0,
  right: 0,
  child: Center(
    child: Image.asset(
      'assets/glam_logo.png',
      height: logoSize,
      width: logoSize * 3, // Maintain aspect ratio
      fit: BoxFit.contain,
    ),
  ),
),

              // Text and Button positioned lower
              Positioned(
                bottom: screenHeight * 0.03,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Shaped by you.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08, // Responsive font size
                        color: const Color.fromARGB(255, 12, 12, 12),
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Toned by you.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        color: const Color.fromARGB(255, 12, 12, 12),
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Glammed for you.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: const Color.fromARGB(255, 12, 12, 12),
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    _isLoading
                        ? LoadingAnimationWidget.flickr(
                            leftDotColor: Colors.pinkAccent,
                            rightDotColor: Colors.pinkAccent,
                            size: screenWidth * 0.1,
                          )
                        : BouncingWidget(
                            scaleFactor: 1.5,
                            duration: const Duration(milliseconds: 100),
                            onPressed: _handleGetStarted,
                            child: Container(
                              width: buttonWidth,
                              height: buttonHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(20.0),
                                boxShadow: [
                                  BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              ),
                              child: Text(
                                'GET STARTED',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CurvedEdgeRectangleClipper extends CustomClipper<Path> {
  final double curveHeight;

  const CurvedEdgeRectangleClipper({this.curveHeight = 80.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final curveWidth = curveHeight * 1.5; // Maintain curve proportions

    // Start at bottom-left
    path.moveTo(0, size.height);

    // Line up left edge
    path.lineTo(0, curveHeight * 2);

    // Curve from top-left to left-mid
    path.quadraticBezierTo(
      0,
      curveHeight,
      curveWidth,
      curveHeight,
    );

    // Center line — flat
    path.lineTo(size.width - curveWidth, curveHeight);

    // Curve from right-mid to top-right
    path.quadraticBezierTo(
      size.width,
      curveHeight,
      size.width,
      curveHeight * 2,
    );

    // Line to bottom-right
    path.lineTo(size.width, size.height);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) =>
      oldClipper is! CurvedEdgeRectangleClipper ||
      oldClipper.curveHeight != curveHeight;
}

class InvertedUBorderPainter extends CustomPainter {
  final double curveHeight;
  final double borderWidth;

  const InvertedUBorderPainter({
    this.curveHeight = 80.0,
    this.borderWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final curveWidth = curveHeight * 1.5; // Maintain curve proportions

    // Draw only the inverted U-shaped top edge
    path.moveTo(0, curveHeight * 2);
    path.quadraticBezierTo(0, curveHeight, curveWidth, curveHeight); // Left curve
    path.lineTo(size.width - curveWidth, curveHeight); // Flat center
    path.quadraticBezierTo(
        size.width, curveHeight, size.width, curveHeight * 2); // Right curve

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      oldDelegate is! InvertedUBorderPainter ||
      oldDelegate.curveHeight != curveHeight ||
      oldDelegate.borderWidth != borderWidth;
}