import 'package:flutter/material.dart';
import 'camera2.dart'; // Make sure this file contains the camera functionality for face tracking.
import 'undertone_tutorial.dart'; // Your Undertone Tutorial Page.

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
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 10.0), // Adjusted padding
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: const Text(
                  "Note: click (i) for identifying your undertone.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSectionTitle("Select Undertone"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UndertoneTutorial()),
                      );
                    },
                    child: const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSegmentedControl(undertones, selectedUndertone, (value) {
                setState(() => selectedUndertone = value);
              }),
              const SizedBox(height: 20),
              if (selectedUndertone != null)
                Text(
                  "You selected: $selectedUndertone undertone",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 12, 12, 12),
                  ),
                ),
              const SizedBox(height: 30),
              _buildSectionTitle("Select Makeup Type"),
              _buildSegmentedControl(makeupLooks.keys.toList(), selectedMakeupType, (value) {
                if (selectedUndertone == null) {
                  // Show snackbar if undertone is not selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select your undertone first."),
                      backgroundColor: Colors.pinkAccent,
                    ),
                  );
                } else {
                  // Allow selecting makeup type if undertone is already selected
                  setState(() {
                    selectedMakeupType = value;
                    selectedMakeupLook = null;
                  });
                }
              }),
              const SizedBox(height: 20),
              if (selectedUndertone != null && selectedMakeupType != null && makeupLooks.containsKey(selectedMakeupType)) ...[
                _buildSectionTitle("Choose Your Makeup Look"),
                Column(
                  children: makeupLooks[selectedMakeupType]!.map((look) => _buildMakeupLookButton(look)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
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

          if (selectedUndertone != null && selectedMakeupType != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraPage(
                  selectedUndertone: selectedUndertone!,
                  selectedMakeupType: selectedMakeupType!,
                  selectedMakeupLook: selectedMakeupLook!,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select undertone and makeup type first.")),
            );
          }
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


