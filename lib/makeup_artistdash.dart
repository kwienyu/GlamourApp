import 'package:flutter/material.dart';
import 'camera.dart';

class MakeupArtistDash extends StatefulWidget {
  const MakeupArtistDash({super.key});

  @override
  _MakeupArtistDashState createState() => _MakeupArtistDashState();
}

class _MakeupArtistDashState extends State<MakeupArtistDash>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Row(
          children: [
            Image.asset(
              'assets/glam_logo.png',
              height: 60,
            ),
            SizedBox(width: 8),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Dashboard"),
            Tab(text: "Clients"),
            Tab(text: "Recommendations"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Hello👋",
                  style: TextStyle(fontSize: 30, fontFamily: 'Serif', fontWeight: FontWeight.bold),
                ),
                Text(
                  "Welcome to glam-up!!",
                  style: TextStyle(fontSize: 25, fontFamily: 'Serif'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCard("Your Profile", Icons.person, Colors.blue, () {}),
                  _buildCard("Add Profile", Icons.people, Colors.purple, () {}),
                  _buildCard("Test My Look", Icons.camera_alt_rounded, Colors.pink, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CameraPage()),
                    );
                  }),
                  _buildCard("Glam Vault", Icons.star, Colors.orange, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              size: 40,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 16, 16, 16), // Added white text color for better contrast
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}