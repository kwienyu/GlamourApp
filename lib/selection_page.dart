import 'package:flutter/material.dart';
import 'undertone.dart'; // Import the tutorial page
import 'profile_selection.dart';
import 'makeuplook_recommendation.dart'; // Import the makeup look recommendation page

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? selectedUndertone; // To store the selected undertone
  final List<String> undertones = ["Warm", "Neutral", "Cool"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSelection()),
              ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/glam_logo.png',
            height: 50,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UndertoneTutorial(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Profile Section
            Container(
              width: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 247, 205, 227),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/ppf.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Kwienny",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("kwien@email.com", style: TextStyle(color: Color.fromARGB(255, 10, 10, 10))),
                  const Text("09703734277", style: TextStyle(color: Color.fromARGB(255, 12, 12, 12))),

                  // Edit Profile Icon
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                    onPressed: () {
                      // Implement profile edit functionality
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Note to the user
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Note: Before selecting your undertone, please click the (?) button for a tutorial on identifying your undertone.",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 144, 144, 144)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),

            // Undertone Selection
            const Text("Select Your Undertone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: undertones.map((tone) => _buildToggleButton(tone)).toList(),
            ),

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

            // Navigate to Makeup Look Recommendation Page with Water Ripple Effect
            Material(
              color: selectedUndertone != null ? Colors.pinkAccent : Colors.grey, // Change color based on selection
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20), // Ensure ripple effect stays inside
                onTap: selectedUndertone != null
                  ? () {
                  Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => MakeupLookRecommendationPage(
                  ),
                ),
              );
              }
            : null, // Prevent tap when no selection

                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle Button Builder (Moved Outside the build method)
  Widget _buildToggleButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedUndertone == label ? Colors.pink[400] : Colors.pink[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          setState(() {
            selectedUndertone = label; // Set selected undertone
          });
        },
        child: Text(label, style: const TextStyle(color: Colors.black)),
      ),
    );
  }
}
