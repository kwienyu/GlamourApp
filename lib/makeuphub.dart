import 'package:flutter/material.dart';
import 'camera.dart';

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
            const Text(
              "Select Your Undertone",
              style: TextStyle(fontSize: 18, fontFamily: 'Serif', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Undertone Selection Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  undertones.map((tone) => _buildUndertoneButton(tone)).toList(),
            ),
            const SizedBox(height: 20),

            if (selectedUndertone != null)
              Text(
                "You selected: $selectedUndertone undertone",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                    color: Color.fromARGB(255, 4, 4, 4)),
              ),

            const SizedBox(height: 30),
            const Text("Select Makeup Type",
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  makeupLooks.keys.map((type) => _buildMakeupTypeButton(type)).toList(),
            ),
            const SizedBox(height: 20),

            if (selectedMakeupType != null) ...[
              const Text(
                "Choose Your Makeup Look",
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildUndertoneButton(String tone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedUndertone = tone;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedUndertone == tone
              ? const Color.fromARGB(255, 239, 123, 162)
              : const Color.fromARGB(255, 241, 122, 185),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Text(
          tone,
          style: TextStyle(
            color: selectedUndertone == tone
                ? const Color.fromARGB(255, 237, 229, 232)
                : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMakeupTypeButton(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedMakeupType = type;
            selectedMakeupLook = null; // Reset look selection
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedMakeupType == type
              ? const Color.fromARGB(255, 239, 135, 169)
              : const Color.fromARGB(255, 243, 133, 186),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: selectedMakeupType == type
                ? const Color.fromARGB(255, 239, 233, 236)
                : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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

          // Navigate to Camera Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedMakeupLook == look
              ? const Color.fromARGB(255, 241, 104, 150)
              : const Color.fromARGB(255, 240, 146, 201),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
