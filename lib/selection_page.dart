import 'package:flutter/material.dart';
import 'profile_selection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'makeup_artistform.dart';
import 'package:intl/intl.dart';

class SelectionPage extends StatefulWidget {
  final String? skinTone;
  final String? faceShape;
  final String userId;

  const SelectionPage({
    super.key,
    this.skinTone,
    this.faceShape,
    required this.userId,
  });

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
  String? email;
  String? gender;
  String? dob;
  int? age;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  int? calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return null;
    
    try {
      final dobDate = DateFormat('yyyy-MM-dd').parse(dobString);
      final now = DateTime.now();
      int age = now.year - dobDate.year;
      if (now.month < dobDate.month || (now.month == dobDate.month && now.day < dobDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      debugPrint("Error calculating age: $e");
      return null;
    }
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

        Uint8List imageBytes = base64Decode(base64Str);

        if (imageBytes.isNotEmpty) {
          setState(() {
            profilePic = imageBytes;
          });
        }
      } catch (e) {
        debugPrint("Error loading cached image: $e");
      }
    }
  }

 void _setErrorState() {
  setState(() {
    name = 'Guest User'; // Default full name
    faceShape = 'Unknown';
    skinTone = 'Unknown';
    profilePic = null;
    email = 'Not available';
    gender = 'Not specified';
    dob = 'Not specified';
    age = null;
  });
}

 Future<void> _fetchProfileData() async {
  final prefs = await SharedPreferences.getInstance();
  final userid = prefs.getString('user_id');

  if (userid == null || userid.isEmpty) {
    _setErrorState();
    return;
  }

  final uri = Uri.parse('https://glamouraika.com/api/user-profile?user_id=$userid');

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
        }
      }

      // Get first name and last name from API
      String? firstName = data['name'] ?? "";  
      String? lastName = data['last_name'] ?? "";
      String fullName = "$firstName $lastName".trim();

      setState(() {
        name = fullName.isNotEmpty ? fullName : "Unknown User";
        faceShape = data['face_shape'] ?? "Not Available";
        skinTone = data['skin_tone'] ?? "Not Available";
        profilePic = imageBytes;
        email = data['email'] ?? "Not available";
        gender = data['gender'] ?? "Not specified";
        dob = data['dob'] ?? "Not specified";
        age = calculateAge(data['dob']);
      });
    } else {
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
        'profile_picture', 
        _newProfilePic!.path,
      ));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile uploaded successfully'),
          backgroundColor: Color.fromARGB(255, 238, 148, 195),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _fetchProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
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
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
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
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSelection(userId: userId),
              ),
            );
          }
        },
      ),
      title: Center(
        child: Image.asset(
          'assets/glam_logo.png',
          height: 60,
        ),
      ),
    actions: [
  Padding(
    padding: const EdgeInsets.only(right: 10),
    child: GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MakeupArtistForm(userId: int.tryParse(userId) ?? 0),
            ),
          );
        }
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
    // Pink box container
    Container(
      width: 400,
      height: 400,
      margin: const EdgeInsets.only(top: 2), // Increased top margin to make space for avatar
      decoration: const BoxDecoration(
        color: Color.fromARGB(95, 239, 216, 230),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 80), // Adjusted to align content below avatar
          // CircleAvatar removed from here
        ],
      ),
    ),
    // CircleAvatar positioned above the pink box
    Positioned(
      top: 30, // Adjust this value to move the avatar higher or lower
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
    // Other content (face shape, skin tone, and user details)
    Padding(
      padding: const EdgeInsets.only(top: 150),
      child: Column(
        children: [
          Container(
            width: 250,
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
          const SizedBox(height: 30),
          // Transparent white container with user details (restored)
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // White background
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
                _buildDetailRow("Full Name:", name ?? "Loading..."),
                _buildDetailRow("Email:", email ?? "Loading..."),
                _buildDetailRow("Gender:", gender ?? "Loading..."),
                _buildDetailRow("Age:", age != null ? "$age years" : "Not available"),
                _buildDetailRow("Date of Birth:", dob ?? "Loading..."),
                
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
    ),
  );
}

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}