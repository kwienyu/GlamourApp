import 'package:flutter/material.dart';
import 'profile_selection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'camera_client.dart';

class SelectionPage extends StatefulWidget {
  final String? skinTone;
  final String? faceShape;
  final String userId;

  const SelectionPage({super.key, this.skinTone, this.faceShape, required this.userId,});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? name;
  String? faceShape;
  String? skinTone;
  File? _newProfilePic;
  dynamic profilePic;
  ImageProvider? image;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }
    

  Future<void> loadCachedProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedImage = prefs.getString('profile_pic');

    if (cachedImage != null && cachedImage.isNotEmpty && cachedImage != "null") {
      try {
        String base64Str = cachedImage;
        if (base64Str.startsWith('data:image')) {
          base64Str = base64Str.split(',').last;
        }

        print("Raw profile_pic base64 length: ${base64Str.length}");

        Uint8List imageBytes = base64Decode(base64Str);

        if (imageBytes.isNotEmpty) {
          setState(() {
            profilePic = imageBytes;
          });
        } else {
          debugPrint("Error: Decoded image bytes are empty");
        }
      } catch (e) {
        debugPrint("Error loading cached image: $e");
      }
    }
  }

  void _setErrorState() {
    setState(() {
      name = 'Guest';
      faceShape = 'Unknown';
      skinTone = 'Unknown';
      profilePic = null;
    });
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString('user_id');

    if (userid == null || userid.isEmpty) {
      debugPrint('No user ID found in shared preferences.');
      _setErrorState();
      return;
    }

    final uri = Uri.parse('https://glamouraika.com/api/user-profile?user_id=$userid');
    debugPrint('Fetching profile from: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String? base64Image = data['profile_pic'];
        Uint8List? imageBytes;

        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            if (base64Image.startsWith('data:image')) {
              base64Image = base64Image.split(',').last;
            }
            imageBytes = base64Decode(base64Image);
            await prefs.setString('user_profile_base64', base64Image);
          } catch (e) {
            debugPrint("Image decoding error: $e");
            imageBytes = null;
          }
        }

        setState(() {
          name = data['name'] ?? "Unknown";
          faceShape = data['face_shape'] ?? "Not Available";
          skinTone = data['skin_tone'] ?? "Not Available";
          profilePic = imageBytes;
        });
      } else {
        debugPrint('API returned status: ${response.statusCode}');
        _setErrorState();
      }
    } catch (e) {
      debugPrint('HTTP error: $e');
      _setErrorState();
    }
  }

  Future<void> pickProfileImage() async {
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

    var uri = Uri.parse('https://glamouraika.com/api/edit-profile');
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
        const SnackBar(content: Text('Profile uploaded successfully'), backgroundColor: Color.fromARGB(255, 238, 148, 195)),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _fetchProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'), backgroundColor: Color.fromARGB(255, 238, 148, 195)),
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
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id') ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSelection(userId: userId),
              ),
            );
          },
        ),
        title: Center(  // Wrap the logo with Center widget
          child: Image.asset(
            'assets/glam_logo.png',
            height: 60,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraClient()),
                );
              },
              child: Image.asset(
                'assets/facscan_icon.gif',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 400,
                  height: 800,
                  margin: const EdgeInsets.only(top: 60),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(95, 239, 216, 230),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
                Column(
                  children: [
                    CircleAvatar(
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
                    const SizedBox(height: 20),
                    Container(
                      width: 350,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 247, 205, 227),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(95, 238, 146, 203).withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            name ?? "Loading...",
                            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Face Shape: ${faceShape ?? "Loading..."}",
                            style: const TextStyle(fontSize: 15, fontFamily: 'Serif'),
                          ),
                          Text(
                            "Skin Tone: ${skinTone ?? "Loading..."}",
                            style: const TextStyle(fontSize: 15, fontFamily: 'Serif'),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                            ),
                            onPressed: _showEditProfileDialog,
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: const Color.fromARGB(255, 244, 85, 135),
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
                            height: 420,
                            child: TabBarView(
                              children: [
                                _buildImageCarousel(['assets/oval1.png', 'assets/round.png', 'assets/square.png', 'assets/heart.png']),
                                _buildImageCarousel(['assets/mestiza1.jpg', 'assets/morena.jpg', 'assets/chinita.jpg']),
                                _buildImageCarousel([
                                  'assets/makeup1.jpg', 'assets/makeup2.jpg', 'assets/makeup3.jpg',
                                  'assets/makeup4.jpg', 'assets/makeup5.jpg', 'assets/makeup6.jpg',
                                  'assets/makeup7.jpg', 'assets/makeup8.jpg', 'assets/makeup9.jpg',
                                  'assets/makeup10.jpg', 'assets/makeup11.jpg',
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    final PageController pageController = PageController();
    final ValueNotifier<int> currentPage = ValueNotifier<int>(0);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            height: 350,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: imagePaths.length,
                  onPageChanged: (index) => currentPage.value = index,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          imagePaths[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      if (currentPage.value > 0) {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                    onPressed: () {
                      if (currentPage.value < imagePaths.length - 1) {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: currentPage,
            builder: (context, value, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imagePaths.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value == index ? Colors.pinkAccent : Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}