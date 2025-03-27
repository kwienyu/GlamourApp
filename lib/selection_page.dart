import 'package:flutter/material.dart';
import 'makeup_guide.dart'; // Import the tutorial page
import 'profile_selection.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileSelection()),
          ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/glam_logo.png',
            height: 60,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MakeupGuide(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Profile Section
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 247, 205, 227),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/ppf.png'),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Kwienny",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text("kwien@gmail.com",
                    style: TextStyle(color: Color.fromARGB(255, 10, 10, 10))),
                const Text("09703734277",
                    style: TextStyle(color: Color.fromARGB(255, 12, 12, 12))),

                // Edit Profile Icon
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                  onPressed: () {
                    // Implement profile edit functionality
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Tab Bar Section
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.pinkAccent,
                    unselectedLabelColor: Colors.black,
                    indicatorColor: Colors.pinkAccent,
                    isScrollable: true, // Allows tabs to scroll and prevents text cutoff
                    tabs: const [
                      Tab(text: "Face Shapes"),
                      Tab(text: "Skin Tone"),
                      Tab(text: "Makeup Looks"),
                      Tab(text: "Makeup Shades"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildImageCarousel([
                          'assets/oval.png',
                          'assets/round.png',
                          'assets/square.png',
                          'assets/heart.png'
                        ]),
                        _buildImageCarousel([
                          'assets/skin1.png',
                          'assets/skin2.png'
                        ]),
                        _buildImageCarousel([
                          'assets/makeup1.jpg',
                          'assets/makeup2.jpg',
                          'assets/makeup3.jpg',
                          'assets/makeup4.jpg',
                          'assets/makeup5.jpg',
                          'assets/makeup6.jpg',
                          'assets/makeup7.jpg',
                          'assets/makeup8.jpg',
                          'assets/makeup9.jpg',
                          'assets/makeup10.jpg',
                          'assets/makeup11.jpg'
                        ]),
                        _buildImageCarousel([
                          'assets/shade1.png',
                          'assets/shade2.png'
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
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: imagePaths.map((path) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                path,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
