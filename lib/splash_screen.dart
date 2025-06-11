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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/phone.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2, // Lowered position
            left: 0,
            right: 0,
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.pinkAccent,
                size: 50,
              ),
            ),
          ),
        ],
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
  bool _isLoading = false; // Track loading state

  void _handleGetStarted() async {
    setState(() {
      _isLoading = true; // Show flicker animation
    });
    // Simulate loading for 2 seconds
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
      body: Stack(
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

          // Pink Inverted U-Shaped Container at Bottom with shimmer effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: InvertedUBorderPainter(), // Add border painter for inverted U
              child: ClipPath(
                clipper: CurvedEdgeRectangleClipper(),
                child: Shimmer(
                  duration: const Duration(seconds: 3),
                  color: Colors.white,
                  colorOpacity: 0.3,
                  enabled: true,
                  direction: ShimmerDirection.fromLeftToRight(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
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
            top: MediaQuery.of(context).size.height * 0.65,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/glam_logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Text and Button positioned lower
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Because every face',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 12, 12, 12),
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'deserves its matching hue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 12, 12, 12),
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? LoadingAnimationWidget.flickr(
                        leftDotColor: Colors.pinkAccent,
                        rightDotColor: Colors.pinkAccent,
                        size: 40,
                      )
                    : BouncingWidget(
                        scaleFactor: 1.5,
                        duration: const Duration(milliseconds: 100),
                        onPressed: _handleGetStarted,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40.0,
                            vertical: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: const Text(
                            'GET STARTED',
                            style: TextStyle(
                              fontSize: 18,
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
    );
  }
}

class CurvedEdgeRectangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at bottom-left
    path.moveTo(0, size.height);

    // Line up left edge
    path.lineTo(0, 160);

    // Curve from top-left to left-mid
    path.quadraticBezierTo(
      0,
      80,
      80,
      80,
    );

    // Center line — flat
    path.lineTo(size.width - 80, 80);

    // Curve from right-mid to top-right
    path.quadraticBezierTo(
      size.width,
      80,
      size.width,
      160,
    );

    // Line to bottom-right
    path.lineTo(size.width, size.height);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class InvertedUBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0; // Increased border width

    final path = Path();

    // Draw only the inverted U-shaped top edge
    path.moveTo(0, 160);
    path.quadraticBezierTo(0, 80, 80, 80); // Left curve
    path.lineTo(size.width - 80, 80); // Flat center
    path.quadraticBezierTo(size.width, 80, size.width, 160); // Right curve

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}