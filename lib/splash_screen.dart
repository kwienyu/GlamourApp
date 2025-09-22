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
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/phone.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Position the loading indicator lower on the screen
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.15, // CHANGED: Moved downward
                left: 0,
                right: 0,
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.pinkAccent,
                    size: MediaQuery.of(context).size.width * 0.12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isPortrait = screenHeight > screenWidth;

    // Adjusted values for bigger logo and fonts
    final curvedContainerHeight = isPortrait ? screenHeight * 0.4 : screenHeight * 0.6;
    final logoTopPosition = isPortrait ? screenHeight * 0.48 : screenHeight * 0.38; // Even lower
    final buttonWidth = isPortrait ? screenWidth * 0.45 : screenWidth * 0.35; // CHANGED: Made button smaller
    final textScale = isPortrait ? 1.0 : 0.8;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Full background image with shimmer effect
            Shimmer(
              duration: const Duration(seconds: 3),
              color: Colors.white,
              colorOpacity: 0.3,
              enabled: true,
              direction: ShimmerDirection.fromLeftToRight(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
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
                  curveHeight: screenHeight * 0.1,
                  borderWidth: screenWidth * 0.015,
                ),
                child: ClipPath(
                  clipper: CurvedEdgeRectangleClipper(
                    curveHeight: screenHeight * 0.1,
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

            // Logo positioned MUCH HIGHER and BIGGER
            Positioned(
              top: logoTopPosition, // MOVED UPWARD from 0.52 to 0.4
              left: 0,
              right: 0,
              child: Center(
                child: _buildLogo(screenWidth * 0.8),
              ),
            ),

            // Text and Button positioned with BIGGER FONTS
            Positioned(
              bottom: screenHeight * 0.02, // CHANGED: Lowered text position (from 0.03 to 0.02)
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Shaped by you.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.065 * textScale,
                      color: const Color.fromARGB(255, 12, 12, 12),
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  Text(
                    'Toned by you.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.060 * textScale,
                      color: const Color.fromARGB(255, 12, 12, 12),
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  Text(
                    'Glammed for you.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.050 * textScale,
                      color: const Color.fromARGB(255, 12, 12, 12),
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
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
                            height: screenHeight * 0.065, // CHANGED: Made button smaller (from 0.075 to 0.065)
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'GET STARTED',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055 * textScale,
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
        ),
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Image.asset(
      'assets/glam_logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }
}

class CurvedEdgeRectangleClipper extends CustomClipper<Path> {
  final double curveHeight;

  const CurvedEdgeRectangleClipper({this.curveHeight = 80.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final curveWidth = curveHeight * 1.5;

    path.moveTo(0, size.height);
    path.lineTo(0, curveHeight * 2);
    path.quadraticBezierTo(
      0,
      curveHeight,
      curveWidth,
      curveHeight,
    );
    path.lineTo(size.width - curveWidth, curveHeight);
    path.quadraticBezierTo(
      size.width,
      curveHeight,
      size.width,
      curveHeight * 2,
    );
    path.lineTo(size.width, size.height);
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
    final curveWidth = curveHeight * 1.5;

    path.moveTo(0, curveHeight * 2);
    path.quadraticBezierTo(0, curveHeight, curveWidth, curveHeight);
    path.lineTo(size.width - curveWidth, curveHeight);
    path.quadraticBezierTo(
        size.width, curveHeight, size.width, curveHeight * 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      oldDelegate is! InvertedUBorderPainter ||
      oldDelegate.curveHeight != curveHeight ||
      oldDelegate.borderWidth != borderWidth;
}