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
  final PageController _pageController = PageController(viewportFraction: 0.8); // Adjusted viewport fraction

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

  Widget _buildImageCarousel(List<String> imagePaths) {
    final PageController pageController = PageController();
    final ValueNotifier<int> currentPage = ValueNotifier<int>(0);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            height: 350,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: imagePaths.length,
                  onPageChanged: (index) => currentPage.value = index,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          imagePaths[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      if (currentPage.value > 0) {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                    onPressed: () {
                      if (currentPage.value < imagePaths.length - 1) {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: currentPage,
            builder: (context, value, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imagePaths.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value == index ? Colors.pinkAccent : Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
          height: screenHeight * 0.10, // Slightly smaller logo
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _buildCurvedBackground(screenHeight),
                _buildMainContent(screenHeight, screenWidth),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: const Color.fromARGB(255, 244, 85, 135),
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.pinkAccent,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: "Face Shapes"),
                        Tab(text: "Skin Tone"),
                        Tab(text: "Makeup Looks"),
                      ],
                    ),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        children: [
                          _buildImageCarousel(['assets/oval1.png', 'assets/round.png', 'assets/square.png', 'assets/heart.png']),
                          _buildImageCarousel(['assets/mestiza1.jpg', 'assets/morena.jpg', 'assets/chinita.jpg']),
                          _buildImageCarousel([
                            'assets/makeup1.jpg', 'assets/makeup2.jpg', 'assets/makeup3.jpg',
                            'assets/makeup4.jpg', 'assets/makeup5.jpg', 'assets/makeup6.jpg',
                            'assets/makeup7.jpg', 'assets/makeup8.jpg', 'assets/makeup9.jpg',
                            'assets/makeup10.jpg', 'assets/makeup11.jpg',
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        height: screenHeight * 0.22, // Slightly smaller curve background
        decoration: const BoxDecoration(color: Colors.pinkAccent),
      ),
    );
  }

  Widget _buildMainContent(double screenHeight, double screenWidth) {
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.04), // Reduced spacing
        _buildWelcomeText(),
        SizedBox(height: screenHeight * 0.15), // Reduced spacing
        _buildProfileCards(screenWidth),
        SizedBox(height: screenHeight * 0.04), // Reduced spacing
      ],
    );
  }

  Widget _buildWelcomeText() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Hello👋',
            style: TextStyle(
              fontSize: 26, // Slightly smaller font
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8), // Reduced spacing
          Text(
            'Welcome to glam-up!!',
            style: TextStyle(
              fontSize: 22, // Slightly smaller font
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
      height: screenWidth * 0.7, // Reduced height for smaller cards
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
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.07), // Adjusted margin
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 243, 149, 180),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8, // Slightly smaller shadow
              spreadRadius: 1, // Slightly smaller shadow
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, 
              color: Colors.pink[800], 
              size: MediaQuery.of(context).size.width * 0.12), // Smaller icon
            SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Reduced spacing
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05, // Smaller font
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80); // Adjusted curve
    path.cubicTo(
      size.width * 0.2, size.height - 15,
      size.width * 0.5, size.height - 120,
      size.width, size.height - 20, // Adjusted curve
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}