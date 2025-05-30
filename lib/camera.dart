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
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _imageFile;
  int _selectedCameraIndex = 0;
  List<CameraDescription>? _cameras;
  String? _skinTone;
  String? _faceShape;
  bool _isLoading = false;
  bool _canProceed = false;
  bool _isCameraReady = false;
  String? _errorMessage;
  bool _showWarning = true;

  final String apiUrl = 'https://glamouraika.com/api/upload_image';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWarning = false;
        });
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _cameraController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isCameraReady = true;
        });
      });

      await _initializeControllerFuture;
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Camera error: ${e.description}';
        _isCameraReady = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
        _isCameraReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                        child: _buildCameraPreview(),
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
                              onPressed: _cameras != null && _cameras!.length > 1 ? _switchCamera : null,
                            ),
                            const SizedBox(width: 25),
                            ElevatedButton.icon(
                              onPressed: _isLoading || !_isCameraReady ? null : _takePicture,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[300],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white))
                                  : const Icon(Icons.camera_alt),
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
            if (_showWarning)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset('assets/warning1.png'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _cameraController == null) {
      setState(() {
        _errorMessage = 'Camera not ready';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _canProceed = false;
      });

      final image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
      });

      await _analyzeImage(File(image.path));
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Camera error: ${e.description}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error capturing image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
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

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

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
          await saveProfileData(_faceShape!, _skinTone!);
        } else {
          _showErrorDialog('No results found. Please try again.');
        }
      } else {
        _showErrorDialog('Server error ${response.statusCode}. $responseData');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    setState(() {
      _isCameraReady = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraReady = true;
        _errorMessage = null;
      });
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Failed to switch camera: ${e.description}';
        _isCameraReady = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print("Error: User ID is null");
        return;
      }

      final response = await http.post(
        Uri.parse("https://glamouraika.com/api/user-profile"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'face_shape': faceShape,
          'skin_tone': skinTone,
        }),
      );

      if (response.statusCode != 200) {
        print("Failed to save data: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

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
                MaterialPageRoute(
                  builder: (context) => MakeupHubPage(skinTone: _skinTone),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_imageFile != null) {
      return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    } else if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    } else if (!_isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return CameraPreview(_cameraController!);
    }
  }
}