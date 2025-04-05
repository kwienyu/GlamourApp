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
  dynamic profilePic;

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

       print('API Response Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded Data: $data');


        String? imageUrl;
        if (data['profile_pic'] != null && data['profile_pic'].toString().isNotEmpty) {
          String imagePath = data['profile_pic'];

          try {
            final decodedPath = utf8.decode(base64.decode(imagePath));
            imageUrl = 'https://glam.ivancarl.com/$decodedPath';
          } catch (e) {
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
         backgroundColor: Color.fromARGB(255, 238, 148, 195),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _fetchProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'),
         backgroundColor: Color.fromARGB(255, 238, 148, 195),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    File? tempImage = _newProfilePic;
    Uint8List? tempImageBytes;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: tempImage != null
                      ? FileImage(tempImage!)
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

                      setStateDialog(() {
                        tempImage = imageFile;
                        tempImageBytes = imageBytes;
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
                onPressed: () async {
                  if (tempImage != null && tempImageBytes != null) {
                    final prefs = await SharedPreferences.getInstance();
                    String base64Image = "data:image/jpeg;base64,${base64Encode(tempImageBytes!)}";
                    await prefs.setString('profile_pic', base64Image);

                    setState(() {
                      _newProfilePic = tempImage;
                      profilePic = tempImageBytes;
                    });
                  }

                  await _updateProfile();
                  Future.delayed(const Duration(seconds: 1), () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop(); 
                    }
                  });
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
            left: MediaQuery.of(context).size.width * 0.02,
            right: MediaQuery.of(context).size.width * 0.02,
            child: Container(
              height: 550,
              width: MediaQuery.of(context).size.width * 0.9,
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
            top: 165,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 247, 205, 227),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color.fromARGB(255, 247, 205, 227), width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(name ?? "Loading...", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 3),
                  Text("Face Shape: ${faceShape ?? "Loading..."}", textAlign: TextAlign.center),
                  Text("Skin Tone: ${skinTone ?? "Loading..."}", textAlign: TextAlign.center),
                  const SizedBox(height: 2),
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
            top: 300,
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
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: SizedBox(
                      height: 320,
                      child: TabBarView(
                        children: [
                          _buildImageCarousel([
                            'assets/oval.png',
                            'assets/round.png',
                            'assets/square.png',
                            'assets/heart.png'
                          ]),
                          _buildImageCarousel([
                            'assets/skin1.png',
                            'assets/skin2.png',
                          ]),
                          _buildImageCarousel([
                            'assets/makeup1.jpg',
                            'assets/makeup2.jpg',
                          ]),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: const Color.fromARGB(255, 239, 156, 207),
          child: PageView.builder(
            itemCount: imagePaths.length,
            controller: PageController(viewportFraction: 1.0),
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.70,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePaths[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}