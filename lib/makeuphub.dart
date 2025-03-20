import 'package:flutter/material.dart';
import 'customization.dart'; // Ensure this file exists and defines CustomizationPage.

class MakeupHubPage extends StatefulWidget {
  const MakeupHubPage({super.key});

  @override
  _MakeupHubPageState createState() => _MakeupHubPageState();
}

class _MakeupHubPageState extends State<MakeupHubPage> {
  String? selectedUndertone;
  String? selectedMakeupType;
  String? selectedMakeupLook;

  final List<String> undertones = ["Warm", "Neutral", "Cool"];
  final Map<String, List<String>> makeupLooks = {
    "Light": ["Dewy", "Rosy Cheeks", "Soft Glam"],
    "Casual": ["No-Makeup Look", "Everyday Glow", "Sun-Kissed Glow"],
    "Heavy": ["Matte Look", "Cut Crease Look", "Glam Night Look"]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makeup Match Hub"),
        backgroundColor: Colors.pinkAccent,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 244, 244),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle("Select Undertone"),
            _buildSegmentedControl(undertones, selectedUndertone, (value) {
              setState(() => selectedUndertone = value);
            }),
            const SizedBox(height: 30),

            if (selectedUndertone != null)
              Text(
                "You selected: $selectedUndertone undertone",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 12, 12, 12),
                ),
              ),
            const SizedBox(height: 20),

            _buildSectionTitle("Select Makeup Type"),
            _buildSegmentedControl(makeupLooks.keys.toList(), selectedMakeupType, (value) {
              setState(() {
                selectedMakeupType = value;
                selectedMakeupLook = null;
              });
            }),
            const SizedBox(height: 20),

            if (selectedMakeupType != null && makeupLooks.containsKey(selectedMakeupType)) ...[
              _buildSectionTitle("Choose Your Makeup Look"),
              Column(
                children: makeupLooks[selectedMakeupType]!.map((look) => _buildMakeupLookButton(look)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options, String? selectedValue, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.pink.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: options.map((option) {
          bool isSelected = selectedValue == option;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pinkAccent : Colors.pink.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMakeupLookButton(String look) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedMakeupLook = look;
          });

          // Navigate to CustomizationPage with the selected makeup look
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomizationPage(makeupLook: look),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
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
