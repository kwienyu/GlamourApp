import 'package:flutter/material.dart';
import 'undertone_tutorial.dart';
import 'selection_page.dart';
import 'camera.dart';
import 'glamvault.dart';

class ProfileSelection extends StatefulWidget {
  const ProfileSelection({super.key});

  @override
  _ProfileSelectionState createState() => _ProfileSelectionState();
}

class _ProfileSelectionState extends State<ProfileSelection> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
      body: Container(
  width: double.infinity,
  height: double.infinity,
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage("assets/media.jpg"),
      fit: BoxFit.cover,
    ),
  ),
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
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
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildProfileButton(context, Icons.person, "Your Profile", SelectionPage()),
              buildProfileButton(context, Icons.add, "Test My Look", const UndertoneTutorial()),
            ],
          ),
          SizedBox(height: 30),
          Center(
            child: buildProfileButton(context, Icons.star, "Glam Vault", GlamVaultPage()),
          ),
        ],
      ),
    ),
  ),
),



      // ⬇️ Custom FAB and BottomAppBar starts here ⬇️
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
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
                child: Image.asset('assets/face_2.gif', width: 50, height: 50),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Makeup Artist", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _onItemTapped(0); // Home
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/home_icon.jpg', width: 30, height: 30),
                          const SizedBox(height: 4),
                          const Text("Home", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 60), // Space for FAB
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _onItemTapped(2); // Profile
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/account.png', width: 30, height: 30),
                          const SizedBox(height: 4),
                          const Text("Profile", style: TextStyle(fontSize: 12)),
                        ],
                      ),
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
        color: const Color.fromARGB(255, 245, 110, 173).withOpacity(0.4), // 👈 makes it semi-transparent
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
}