import 'package:flutter/material.dart';
import 'undertone_tutorial.dart';

class ProfileSelection extends StatelessWidget {
  const ProfileSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Selection")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome, Kwien!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("Select a Profile"),
            const SizedBox(height: 20),

            // Kwien's Profile
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UndertoneTutorial(),
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text("Kwien's Profile")),
              ),
            ),
            const SizedBox(height: 20),

            // Add Profile
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/add_profile');
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text("Add Profile")),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
