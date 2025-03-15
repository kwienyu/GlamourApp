import 'package:flutter/material.dart';
import 'camera.dart';

class MakeupLookRecommendationPage extends StatefulWidget {
  @override
  _MakeupLookRecommendationPageState createState() =>
      _MakeupLookRecommendationPageState();
}

class _MakeupLookRecommendationPageState
    extends State<MakeupLookRecommendationPage> {
  String? selectedMakeupType;
  String? selectedMakeupLook;
  bool showLooks = false;

  final Map<String, List<String>> makeupLooks = {
    "Light": ["Dewy", "Rosy Cheeks", "Soft Glam"],
    "Casual": ["No-makeup look", "Everyday glow", "Sun-kissed glow"],
    "Heavy": ["Matte look", "Cut crease look", "Glam night look"]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makeup Match Hub"),
        backgroundColor: Colors.pinkAccent,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const SizedBox(height: 50),

          const Text(
            "Select Makeup Type",
            style: TextStyle(fontSize: 20, fontFamily: 'Serif', fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Makeup Type Navigation Bar
          Container(
            color: const Color.fromARGB(255, 240, 121, 189),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: makeupLooks.keys.map((type) {
                return Expanded(child: _buildMakeupTypeTab(type));
              }).toList(),
            ),
          ),

          const SizedBox(height: 15),

          if (selectedMakeupType != null) ...[
            const Text(
              "Choose your makeup look",
              style: TextStyle(fontSize: 20, fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Color.fromARGB(255, 10, 10, 10)),
            ),
            const SizedBox(height: 15),
            Column(
              children: makeupLooks[selectedMakeupType]!
                  .map((look) => _buildMakeupLookButton(look))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Makeup Type Tab Button
  Widget _buildMakeupTypeTab(String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMakeupType = type;
          selectedMakeupLook = null;
          showLooks = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selectedMakeupType == type ? const Color.fromARGB(255, 240, 121, 189) : const Color.fromARGB(255, 241, 98, 179),
        ),
        child: Center(
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selectedMakeupType == type ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Makeup Look Selection Button (Now Navigates to Camera Page)
  Widget _buildMakeupLookButton(String look) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedMakeupLook == look
              ? const Color.fromARGB(255, 242, 157, 208)
              : const Color.fromARGB(255, 246, 93, 172),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: () {
          setState(() {
            selectedMakeupLook = look;
          });

          // Navigate to Camera Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraPage()), 
          );
        },
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Text(
              look,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
