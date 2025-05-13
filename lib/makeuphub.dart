import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'camera2.dart'; 
import 'undertone_tutorial.dart'; 

class MakeupHubPage extends StatefulWidget {
  const MakeupHubPage({super.key, this.skinTone});

  final String? skinTone; 
  
  @override
  _MakeupHubPageState createState() => _MakeupHubPageState();
}

class _MakeupHubPageState extends State<MakeupHubPage> {
  String? selectedUndertone;
  String? selectedMakeupType;
  String? selectedMakeupLook;
  String? userSkinTone;
  bool isLoadingSkinTone = false;

  final List<String> undertones = ["Warm", "Neutral", "Cool"];
  final Map<String, List<String>> makeupLooks = {
    'Casual': ['No-Makeup', 'Everyday Glow', 'Sun-Kissed Glow'],
    'Light': ['Dewy', 'Rosy Cheeks', 'Soft Glam'],
    'Heavy': ['Matte', 'Cut Crease', 'Glam Night'],
  };

  @override
  void initState() {
    super.initState();
    userSkinTone = widget.skinTone;
    if (userSkinTone == null) {
      _fetchUserSkinTone();
    }
  }

  Future<void> _fetchUserSkinTone() async {
    setState(() {
      isLoadingSkinTone = true;
    });

    try {
      final userId = await getUserId();
      if (userId != null) {
        final response = await http.get(
          Uri.parse('https://glamouraika.com/api/user/$userId/skin-tone'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          setState(() {
            userSkinTone = responseData['skin_tone'];
            if (userSkinTone != null && undertones.contains(userSkinTone)) {
              selectedUndertone = userSkinTone;
            }
          });
        } else {
          print("Failed to fetch skin tone: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Error fetching skin tone: $e");
    } finally {
      setState(() {
        isLoadingSkinTone = false;
      });
    }
  }

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
          padding: const EdgeInsets.only(top: 20.0, left: 10.0),
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
              if (isLoadingSkinTone)
                const CircularProgressIndicator(),
              if (userSkinTone != null && !isLoadingSkinTone)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Your skin tone: $userSkinTone",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select your undertone first."),
                      backgroundColor: Colors.pinkAccent,
                    ),
                  );
                } else {
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
                  children: makeupLooks[selectedMakeupType]!
                      .map((look) => _buildMakeupLookButton(look))
                      .toList(),
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
        onPressed: () async {
          setState(() {
            selectedMakeupLook = look;
          });

          // Debug print for selected values
  print("Selected Values:");
  print("- Undertone: $selectedUndertone");
  print("- Makeup Type: $selectedMakeupType");
  print("- Makeup Look: $look");
  print("- Skin Tone: $userSkinTone");
  

          if (selectedUndertone != null && selectedMakeupType != null) {
            try {
              final userId = await getUserId();
              if (userId != null) {
                // Create request body matching API requirements
                final requestBody = {
                  'user_id': userId,
                  'undertone': selectedUndertone,
                  'makeup_type': selectedMakeupType,
                  'makeup_look': look,
                  'skin_tone' : userSkinTone,
                };
                print("Request Payload: ${jsonEncode(requestBody)}");


                // Make API call to recommendation endpoint
                final response = await http.post(
                  Uri.parse('https://glamouraika.com/api/recommendation'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(requestBody),
                );
                    // Debug print for full response
        print("API Response:");
        print("- Status Code: ${response.statusCode}");
        print("- Body: ${response.body}");
        print("- Headers: ${response.headers}");

                // Handle API response
                if (response.statusCode == 200) {
                  final responseData = json.decode(response.body);
                  if (responseData['success'] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraPage(
                          selectedUndertone: selectedUndertone!,
                          selectedMakeupType: selectedMakeupType!,
                          selectedMakeupLook: selectedMakeupLook!,
                          userId: userId,
                          skinTone: userSkinTone,
                          recommendationData: responseData, // Pass the API response data
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(responseData['message'] ?? 'Request failed')),
                    );
                  }
                } else if (response.statusCode == 400) {
                  final errorData = json.decode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorData['message'] ?? 'Invalid request')),
                  );
                } else if (response.statusCode == 404) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not found')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server error')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User ID not found')),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select all required fields')),
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

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');  
  }
}