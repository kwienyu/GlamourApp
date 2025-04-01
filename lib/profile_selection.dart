import 'package:flutter/material.dart';
import 'undertone_tutorial.dart';
import 'selection_page.dart';
import 'glamvault.dart';
import 'camera.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Hello👋',
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Welcome to glam-up!!',
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildProfileButton(
                      context,
                      Icons.person,
                      "Your Profile",
                      SelectionPage(),
                    ),
                    SizedBox(width: 30),
                    buildProfileButton(
                      context,
                      Icons.add,
                      "Test My Look",
                      const UndertoneTutorial(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 170,
                  child: buildProfileButton(
                    context,
                    Icons.star,
                    "Glam Vault",
                    GlamVaultPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/home_icon.jpg', width: 30, height: 30),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: IconButton(
                icon: Image.asset('assets/face_2.gif', width: 65, height: 65),
                onPressed: () {
                  // Implement Face Cam functionality here
                   Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
                },
              ),
            ),
            label: "Makeup Artist",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/account.png', width: 30, height: 30),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget buildProfileButton(
      BuildContext context, IconData icon, String text, Widget route) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.pink[100],
          borderRadius: BorderRadius.circular(15),
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
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
