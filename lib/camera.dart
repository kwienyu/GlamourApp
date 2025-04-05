import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'makeuphub.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserProfile {
  static String? skinTone;
  static String? faceShape;

  static void setProfile(String? skinTone, String? faceShape) {
    UserProfile.skinTone = skinTone;
    UserProfile.faceShape = faceShape;
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  int _selectedCameraIndex = 0;
  late List<CameraDescription> _cameras;
  String? _skinTone;
  String? _faceShape;
  bool _isLoading = false;
  bool _canProceed = false;

  final String apiUrl = 'https://glam.ivancarl.com/api/upload_image';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('No cameras available');
        return;
      }
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _imageFile = image;
        _isLoading = true;
        _canProceed = false;
      });

      await _analyzeImage(File(image.path));
    } catch (e) {
      print('Error capturing image: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

  // Attach the image
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('email');

  if (email == null || email.trim().isEmpty) {
    _showErrorDialog('No email found in storage. Please log in again.');
    setState(() => _isLoading = false);
    return;
  }

  final normalizedEmail = email.trim().toLowerCase();
  request.fields['email'] = normalizedEmail;

  print("📧 Sending email: $normalizedEmail");

  try {
    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: $responseData');

    if (response.statusCode == 200) {
      var jsonData = json.decode(responseData);

      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('skin_tone') &&
          jsonData.containsKey('face_shape')) {
        setState(() {
          _skinTone = jsonData['skin_tone'];
          _faceShape = jsonData['face_shape'];
          _canProceed = true;
        });
      } else {
        _showErrorDialog('No results found. Please try again.');
      }
    } else {
      _showErrorDialog('Server error ${response.statusCode}. $responseData');
    }
  } catch (e) {
    print('Network error: $e');
    _showErrorDialog('Network error. Please check your connection.');
  } finally {
    setState(() => _isLoading = false);
  }
}


  void _switchCamera() async {
    if (_cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _cameraController.dispose();
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> saveProfileData(String faceShape, String skinTone) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  if (userId == null) {
    print("Error: User ID is null");
    return;
  }

  String apiUrl = "https://glam.ivancarl.com/api/user-profile";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'face_shape': faceShape,
        'skin_tone': skinTone,
      }),
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      print("Data saved successfully");
    } else {
      print("Failed to save data: ${response.body}");
    }
  } catch (e) {
    print("Exception: $e");
  }
}


  // New method for handling the alert before saving and redirecting
  void _handleProceed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Your result will be saved to your profile.'),
        actions: [
          TextButton(
            onPressed: () {
              
              UserProfile.setProfile(_skinTone, _faceShape);    
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MakeupHubPage()),
              );
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _imageFile == null
                        ? FutureBuilder<void>( 
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                return CameraPreview(_cameraController);
                              } else if (snapshot.hasError) {
                                return const Center(
                                  child: Text('Error loading camera', style: TextStyle(color: Colors.white)),
                                );
                              } else {
                                return const Center(child: CircularProgressIndicator());
                              }
                            },
                          )
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _skinTone == null && _faceShape == null
                            ? 'Click capture to scan your face'
                            : 'Skin Tone: $_skinTone\nFace Shape: $_faceShape',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                          onPressed: _switchCamera,
                        ),
                        const SizedBox(width: 25),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _takePicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.camera_alt),
                          label: _isLoading ? const Text('Analyzing...') : const Text('Capture'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _canProceed ? _handleProceed : null, 
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}