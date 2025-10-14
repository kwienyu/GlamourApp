import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'customization.dart'; 
import 'undertone_tutorial.dart'; 
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MakeupHubPage extends StatefulWidget {
  const MakeupHubPage({
    super.key, 
    this.skinTone, 
    this.capturedImage,
    this.userId,
  });

  final String? skinTone; 
  final File? capturedImage;
  final String? userId;
  
  @override
  MakeupHubPageState createState() => MakeupHubPageState();
}

class MakeupHubPageState extends State<MakeupHubPage> {
  String? selectedUndertone;
  String? selectedMakeupType;
  String? selectedMakeupLook;
  String? userSkinTone;
  File? _capturedImage;
  bool isLoadingSkinTone = false;
  bool isLoadingImage = false;
  bool isProcessingMakeupLook = false;
  String? currentlyProcessingLook; 

  final List<String> undertones = ["Warm", "Neutral", "Cool"];
  final Map<String, List<String>> makeupLooks = {
    'Casual': ['No-Makeup', 'Everyday Glow', 'Sun-Kissed'],
    'Light': ['Dewy', 'Rosy Cheeks', 'Soft Glam'],
    'Heavy': ['Matte', 'Cut Crease', 'Glam Night'],
  };

  @override
  void initState() {
    super.initState();
    userSkinTone = widget.skinTone;
    _capturedImage = widget.capturedImage;
    if (userSkinTone == null) {
      _fetchUserSkinTone();
    }
    if (_capturedImage == null) {
      _loadCapturedImage();
    }
  }

  Future<void> _loadCapturedImage() async {
    setState(() {
      isLoadingImage = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('last_captured_image_path');
      
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        final fileExists = await imageFile.exists();
        
        if (fileExists) {
          setState(() {
            _capturedImage = imageFile;
          });
        } else {
          await prefs.remove('last_captured_image_path');
        }
      }
    } catch (e) {
      print("Error loading captured image: $e");
    } finally {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  Future<void> _fetchUserSkinTone() async {
  setState(() {
    isLoadingSkinTone = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = prefs.getString('user_id');
    final userSkinToneFromPrefs = prefs.getString('user_skin_tone');
    final userUndertoneFromPrefs = prefs.getString('user_undertone');
    
    if (userSkinToneFromPrefs != null && userSkinToneFromPrefs.isNotEmpty) {
      setState(() {
        userSkinTone = userSkinToneFromPrefs;
        if (userUndertoneFromPrefs != null && undertones.contains(userUndertoneFromPrefs)) {
          selectedUndertone = userUndertoneFromPrefs;
        }
      });
    } else if (userId != null) {
      // Fallback to API only if we have userId but no local data
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
        
        // Save to SharedPreferences for future use
        if (userSkinTone != null) {
          await prefs.setString('user_skin_tone', userSkinTone!);
        }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 10.0),
              child: Column(
                children: [
                  if (isLoadingImage)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.shade100),
                      ),
                      child: Row(
                        children: [
                          LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.pink.shade100,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Loading your captured image...",
                            style: TextStyle(
                              color: Color.fromARGB(255, 6, 6, 6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Show warning if no image found 
                  if (!isLoadingImage && _capturedImage == null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "No captured image found.",
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Makeup application will use a default face model.",
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),      
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
                  const SizedBox(height: 20),
                  
                  if (isLoadingSkinTone)
                    Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.pinkAccent,
                        size: 50,
                      ),
                    ),
                  
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
          
          if (isProcessingMakeupLook)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.pinkAccent,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Wait a minute...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Processing $currentlyProcessingLook look",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          if (isProcessingMakeupLook) return; 
          
          setState(() {
            selectedMakeupLook = look;
            isProcessingMakeupLook = true;
            currentlyProcessingLook = look;
          });
          try {
            final userId = widget.userId ?? await getUserId();
            if (userId != null) {
              final userData = {
                'success': true,
                'user_id': userId,
                'undertone': selectedUndertone,
                'skin_tone': userSkinTone,
                'makeup_type': selectedMakeupType,
                'makeup_look': look,
              };
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomizationPage(
                    capturedImage: _capturedImage,
                    selectedMakeupType: selectedMakeupType!,
                    selectedMakeupLook: selectedMakeupLook!,
                    userId: userId,
                    undertone: selectedUndertone!,
                    skinTone: userSkinTone,
                    recommendationData: userData,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID not found')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          } finally {
            if (mounted) {
              setState(() {
                isProcessingMakeupLook = false;
                currentlyProcessingLook = null;
              });
            }
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
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    // If userId is not found in prefs, use the one from widget
    if (userId == null || userId.isEmpty) {
      return widget.userId;
    }
    
    return userId;
  } catch (e) {
    print("Error getting user ID: $e");
    return widget.userId;
  }
}
}