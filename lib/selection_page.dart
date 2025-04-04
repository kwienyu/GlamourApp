import 'package:flutter/material.dart';
import 'makeup_guide.dart';
import 'profile_selection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  dynamic profilePic; // Can be Uint8List or String (URL)

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  File? _newProfilePic;

  @override
  void initState() {
    super.initState();
    _loadCachedProfilePic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfileData());
  }

  Future<void> _loadCachedProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedImage = prefs.getString('profile_pic');

    if (cachedImage != null && cachedImage.isNotEmpty && cachedImage != "null") {
      try {
        if (cachedImage.startsWith('http')) {
          setState(() => profilePic = cachedImage);
        } else {
          final base64Str = cachedImage.split(',').last;
          Uint8List imageBytes = base64Decode(base64Str);
          setState(() => profilePic = imageBytes);
        }
      } catch (e) {
        debugPrint("Error loading cached image: $e");
      }
    }
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String? imageUrl;
if (data['profile_pic'] != null && data['profile_pic'].toString().isNotEmpty) {
  String imagePath = data['profile_pic'];

  // Try to decode from base64 if necessary
  try {
    final decodedPath = utf8.decode(base64.decode(imagePath));
    imageUrl = 'https://glam.ivancarl.com/$decodedPath';
  } catch (e) {
    // If it's not base64-encoded, use as is
    imageUrl = 'https://glam.ivancarl.com/$imagePath';
  }

  await prefs.setString('profile_pic', imageUrl);
}


        setState(() {
          name = data['name'] ?? "Unknown";
          faceShape = data['face_shape'] ?? "Not Available";
          skinTone = data['skin_tone'] ?? "Not Available";
          profilePic = imageUrl;
        });
      } else {
        _setErrorState();
      }
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
      _setErrorState();
    }
  }

  void _setErrorState() {
    setState(() {
      name = 'Error fetching data';
      faceShape = 'Error';
      skinTone = 'Error';
      profilePic = null;
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_pic', base64Image);

      setState(() {
        _newProfilePic = imageFile;
        profilePic = imageBytes;
      });
    }
  }

  Future<void> _updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    var uri = Uri.parse('https://glam.ivancarl.com/api/edit-profile');
    var request = http.MultipartRequest('POST', uri);
    request.fields['user_id'] = userId;

    if (_newProfilePic != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture', _newProfilePic!.path,
      ));
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'),
         backgroundColor: const Color.fromARGB(255, 238, 148, 195),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _fetchProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'),
         backgroundColor: const Color.fromARGB(255, 238, 148, 195),
        ),
        
      );
    }
  }

  void _showEditProfileDialog() {
    File? tempImage = _newProfilePic;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _newProfilePic != null
                      ? FileImage(_newProfilePic!)
                      : (profilePic != null
                          ? (profilePic is Uint8List
                              ? MemoryImage(profilePic!)
                              : NetworkImage(profilePic.toString()) as ImageProvider)
                          : null),
                  child: tempImage == null && profilePic == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      File imageFile = File(pickedFile.path);
                      Uint8List imageBytes = await imageFile.readAsBytes();
                      String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('profile_pic', base64Image);

                      setState(() {
                        _newProfilePic = imageFile;
                        profilePic = imageBytes;
                      });

                      setStateDialog(() {
                        tempImage = imageFile;
                      });
                    }
                  },
                  child: const Text("Choose Profile Picture"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
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
          child: Image.asset('assets/glam_logo.png', height: 60),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MakeupGuide()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Container(
              height: 550,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 239, 156, 207),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: const Color.fromARGB(255, 239, 79, 165),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _newProfilePic != null
                    ? FileImage(_newProfilePic!)
                    : (profilePic != null
                        ? (profilePic is Uint8List
                            ? MemoryImage(profilePic!)
                            : NetworkImage(profilePic.toString()) as ImageProvider)
                        : null),
                child: _newProfilePic == null && profilePic == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          Positioned(
            top: 170,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 247, 205, 227),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color.fromARGB(255, 247, 205, 227), width: 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(name ?? "Loading...", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  Text("Face Shape: ${faceShape ?? "Loading..."}", textAlign: TextAlign.center),
                  Text("Skin Tone: ${skinTone ?? "Loading..."}", textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    onPressed: _showEditProfileDialog,
                    child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 320,
            left: 0,
            right: 0,
            child: DefaultTabController(
              length: 3,
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
                    ],
                  ),
                  SizedBox(
                    height: 350,
                    child: TabBarView(
                      children: [
                        _buildImageCarousel(['assets/oval.png', 'assets/round.png', 'assets/square.png', 'assets/heart.png']),
                        _buildImageCarousel(['assets/skin1.png', 'assets/skin2.png']),
                        _buildImageCarousel(['assets/makeup1.jpg', 'assets/makeup2.jpg']),
                      ],
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

  Widget _buildImageCarousel(List<String> imagePaths) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: imagePaths.map((path) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(path, width: 150, height: 150, fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }
}
