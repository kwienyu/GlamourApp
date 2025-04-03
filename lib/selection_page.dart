import 'package:flutter/material.dart';
import 'makeup_guide.dart';
import 'profile_selection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SelectionPage extends StatefulWidget {
  final String? skinTone;
  final String? faceShape;

  const SelectionPage({super.key, this.skinTone, this.faceShape});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? name;
  String? faceShape;
  String? skinTone;
  String? profilePic;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
  final prefs = await SharedPreferences.getInstance();
  final userid = prefs.getString('user_id');

  if (userid == null) {
    setState(() {
      name = 'Guest';
      faceShape = 'Unknown';
      skinTone = 'Unknown';
      profilePic = null;
    });
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://glam.ivancarl.com/api/user-profile?user_id=$userid'),
      headers: {'Content-Type': 'application/json'},
    );

    print('API Response Code: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Decoded Data: $data');

      setState(() {
        name = data['name'] ?? "Unknown";
        faceShape = data['face_shape'] ?? "Not Available";
        skinTone = data['skin_tone'] ?? "Not Available";
        profilePic = data['profile_pic'];
      });

      print('Updated State -> Face Shape: $faceShape, Skin Tone: $skinTone');
    } else {
      print('Error: Received status code ${response.statusCode}');
      setState(() {
        name = 'Error fetching data';
        faceShape = 'Error fetching data';
        skinTone = 'Error fetching data';
      });
    }
  } catch (e) {
    print('Exception: $e');
    setState(() {
      name = 'Error fetching data';
      faceShape = 'Error fetching data';
      skinTone = 'Error fetching data';
    });
  }
}


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
            height: 60,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MakeupGuide(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profilePic != null
                  ? MemoryImage(base64Decode(profilePic!))
                  : const AssetImage('assets/ppf.png') as ImageProvider,
            ),
            const SizedBox(height: 10),
            Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 247, 205, 227),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.pinkAccent,
      width: 4,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name ?? "Loading...",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Text("Face Shape: ${faceShape ?? "Loading..."}"),
      Text("Skin Tone: ${skinTone ?? "Loading..."}"),
    ],
  ),
),

            const SizedBox(height: 30),
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.pinkAccent,
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.pinkAccent,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: "Face Shapes"),
                        Tab(text: "Skin Tone"),
                        Tab(text: "Makeup Looks"),
                        Tab(text: "Makeup Shades"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildImageCarousel(['assets/oval.png', 'assets/round.png', 'assets/square.png', 'assets/heart.png']),
                          _buildImageCarousel(['assets/skin1.png', 'assets/skin2.png']),
                          _buildImageCarousel([
                            'assets/makeup1.jpg', 'assets/makeup2.jpg', 'assets/makeup3.jpg', 'assets/makeup4.jpg',
                            'assets/makeup5.jpg', 'assets/makeup6.jpg', 'assets/makeup7.jpg', 'assets/makeup8.jpg',
                            'assets/makeup9.jpg', 'assets/makeup10.jpg', 'assets/makeup11.jpg'
                          ]),
                          _buildImageCarousel(['assets/shade1.png', 'assets/shade2.png']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: imagePaths.map((path) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                path,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
