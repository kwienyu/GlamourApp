import 'package:flutter/material.dart';
import 'makeuplook_recommendation.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? selectedMakeupType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Kwien's Profile",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),

            // Undertone Selection
            const Text(
              'Select Undertone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton('Warm'),
                _buildToggleButton('Neutral'),
                _buildToggleButton('Cool'),
              ],
            ),
            const SizedBox(height: 30),

            // Makeup Type Selection
            const Text(
              'Select Makeup Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMakeupTypeButton(context, 'Light'),
                _buildMakeupTypeButton(context, 'Casual'),
                _buildMakeupTypeButton(context, 'Heavy'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pink button for undertone selection
  Widget _buildToggleButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {},
        child: Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  // Pink button for makeup type with navigation
  Widget _buildMakeupTypeButton(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MakeupLookRecommendationPage(makeupType: type),
            ),
          );
        },
        child: Text(
          type,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
