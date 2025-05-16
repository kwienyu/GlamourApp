import 'package:flutter/material.dart';
import 'selection_page.dart';
import 'camera.dart';
import 'glamvault.dart';
import 'makeup_guide.dart';

class ProfileSelection extends StatefulWidget {

  final String userId;
  const ProfileSelection({super.key, required this.userId});

  @override
  _ProfileSelectionState createState() => _ProfileSelectionState();
}

class _ProfileSelectionState extends State<ProfileSelection> {
  int selectedIndex = 0;
  bool _showBubble = true;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Hide the bubble after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Image.asset(
          'assets/glam_logo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MakeupGuide()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pinkAccent),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Stack(
  children: [
    // Pink curved background
    ClipPath(
      clipper: TopCurveClipper(),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.pinkAccent,
        ),
      ),
    ),

    // Main Content
    SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 40), // Top spacing for curve visibility

          // ⬆️ Text content ABOVE the curve visually
          Center(
            child: Column(
              children: [
                Text(
                  'Hello👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Welcome to glam-up!!',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 80), // Add space between curve and cards

          // ⬇️ Three cards/buttons below the curve
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildProfileButton(context, Icons.person, "Your Profile", SelectionPage()),
                    buildProfileButton(context, Icons.add, "Test My Look", const CameraPage()),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: buildProfileButton(context, Icons.star, "Glam Vault", GlamVaultScreen(userId: int.parse(widget.userId)),
                ),
            )],
            ),
          ),
        ],
      ),
    ),
  ],
),
floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 10), // Align with Glam Vault
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_showBubble)
        CustomPaint(
          painter: BubbleWithTailPainter(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              "Make-up Artist",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      const SizedBox(height: 6),

      // Larger circular button
      Container(
        height: 100, // Increased from 80
        width: 100,  // Increased from 80
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(255, 239, 168, 192),
          border: Border.all(
            color: Colors.pinkAccent,
            width: 4,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraPage()),
            );
          },
          child: Image.asset('assets/facscan_icon.gif', width: 80, height: 80), // Increased from 60
        ),
      ),
    ],
  ),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
    }
  }

  Widget buildProfileButton(BuildContext context, IconData icon, String text, Widget route) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        );
      },
      child: Container(
        width: 130,
        height: 130,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 243, 149, 180),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.pink[800],
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }


// ✅ ADD THIS AT THE END OF THE FILE
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left and curve slightly downward (higher than before)
    path.lineTo(0, size.height - 100);

    // Adjusted cubic curve:
    path.cubicTo(
      size.width * 0.2, size.height - 20,      // slight curve down near left (raised more)
      size.width * 0.5, size.height - 140,     // peak at center (same)
      size.width, size.height,                 // curve down more at right side
    );

    path.lineTo(size.width, 0); // Top-right
    path.lineTo(0, 0);          // Back to top-left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BubbleWithTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.pink[100]!
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final radius = 12.0;
    final bubbleRect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height - 10,
      Radius.circular(radius),
    );

    final bubblePath = Path()..addRRect(bubbleRect);

    // Tail of the bubble
    final tailPath = Path()
      ..moveTo(size.width / 2 - 6, size.height - 10)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 6, size.height - 10)
      ..close();

    // Draw fill
    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(tailPath, fillPaint);

    // Draw border
    canvas.drawPath(bubblePath, strokePaint);
    canvas.drawPath(tailPath, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}