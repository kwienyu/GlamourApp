import 'package:flutter/material.dart';

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
        backgroundColor: Colors.pinkAccent, // Match Glamour's theme
        title: Row(
          children: [
            Image.asset(
              'assets/glam_logo.png', // Change to your actual logo path
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
            Tab(text: "Overview"),
            Tab(text: "Clients"),
            Tab(text: "Recommendations"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Welcome Message
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
          // Existing Grid Layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCard("Overview Panel", Icons.dashboard, Colors.blue),
                  _buildCard("Client Management", Icons.people, Colors.purple),
                  _buildCard("Makeup Recommendations", Icons.brush, Colors.pink),
                  _buildCard("Customization & Makeup Application", Icons.edit, Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
