import 'package:flutter/material.dart';
import 'undertone_tutorial.dart'; 

class ProfileSelection extends StatelessWidget {
  const ProfileSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar Section
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Image.asset(
          'assets/glam_logo.png',
          width: 200,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),

      // Drawer Section
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

      // Body Section
      body: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(

          children: [
            // Greeting Text
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

            // Space Before Grid
            SizedBox(height: 40),

            // First Two Boxes (Your Profile & Add Profile)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your Profile Box
                buildProfileButton(
                  context,
                  Icons.person,
                  "Your Profile",
                  const UndertoneTutorial(),
                ),
                SizedBox(width: 30),
                // Add Profile Box
                buildProfileButton(
                  context,
                  Icons.add,
                  "Add Profile",
                  const UndertoneTutorial(),
                ),
              ],
            ),

            // Space Between Grid and Center Button
            SizedBox(height: 30),

            // Centered "Recent Looks" Button Below Grid
            Center(
              child: SizedBox(
                width: 170, // Fixed size for the button
                child: buildProfileButton(
                  context,
                  Icons.star,
                  "Recent Looks",
                  const UndertoneTutorial(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Button Builder Function
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
        width: 140, //Fixed square size
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
