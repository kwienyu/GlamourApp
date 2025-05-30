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
  bool showBubble = true;
  final PageController _pageController = PageController(viewportFraction: 0.7);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showBubble = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Image.asset(
          'assets/glam_logo.png',
          height: screenHeight * 0.07, 
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MakeupGuide(userId: widget.userId)),
            ),
          ),
        ],
      ),
      drawer: Drawer(child: _buildDrawerContent()),
      body: Stack(
        children: [
          _buildCurvedBackground(screenHeight),
          _buildMainContent(screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildDrawerContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Colors.pinkAccent),
          child: Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          title: const Text('Home'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          title: const Text('Settings'),
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCurvedBackground(double screenHeight) {
    return ClipPath(
      clipper: TopCurveClipper(),
      child: Container(
        height: screenHeight * 0.25, 
        decoration: const BoxDecoration(color: Colors.pinkAccent),
      ),
    );
  }

  Widget _buildMainContent(double screenHeight, double screenWidth) {
    return SingleChildScrollView(
      child: SizedBox(
        height: screenHeight,
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05),
            _buildWelcomeText(),
            SizedBox(height: screenHeight * 0.20),
            _buildProfileCards(screenWidth),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Center(
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
    );
  }

  Widget _buildProfileCards(double screenWidth) {
    return SizedBox(
      height: screenWidth * 0.9, 
      child: PageView(
        controller: _pageController,
        children: [
          _buildProfileCard(Icons.person, "Your Profile", SelectionPage()),
          _buildProfileCard(Icons.camera_alt_rounded, "Test My Look", const CameraPage()),
          _buildProfileCard(Icons.star, "Glam Vault", GlamVaultScreen(userId: int.parse(widget.userId))),
        ],
      ),
    );
  }

  Widget _buildProfileCard(IconData icon, String text, Widget route) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => route)),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 243, 149, 180),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.pink[800], size: MediaQuery.of(context).size.width * 0.15),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildArtistButton() {
    return Container(
      height: MediaQuery.of(context).size.width * 0.22,
      width: MediaQuery.of(context).size.width * 0.22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromARGB(255, 239, 168, 192),
        border: Border.all(
          color: Colors.pinkAccent,
          width: 4,
        ),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 100);
    path.cubicTo(
      size.width * 0.2, size.height - 20,
      size.width * 0.5, size.height - 140,
      size.width, size.height,
    );
    path.lineTo(size.width, 0);
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

    final bubbleRect = RRect.fromLTRBR(
      0, 0, size.width, size.height - 10, Radius.circular(12),
    );
    final tailPath = Path()
      ..moveTo(size.width / 2 - 6, size.height - 10)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 6, size.height - 10)
      ..close();

    canvas.drawPath(Path()..addRRect(bubbleRect), fillPaint);
    canvas.drawPath(tailPath, fillPaint);
    canvas.drawPath(Path()..addRRect(bubbleRect), strokePaint);
    canvas.drawPath(tailPath, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}