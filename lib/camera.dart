import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';


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

  final String apiUrl = 'https://8f21-2001-4456-ceb-6000-3d6f-9fa5-3da8-9360.ngrok-free.app/api/upload_image';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      print('❌ No cameras available');
      return;
    }
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _cameraController.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _imageFile = image;
        _isLoading = true;
      });

      await _analyzeImage(File(image.path));
    } catch (e) {
      print('❌ Error capturing image: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.fields['email'] = 'kwien@gmail.com'; // ✅ Added missing email field

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('📡 Response received: $responseData'); // ✅ Log full API response

      if (response.statusCode == 200) {
        var jsonData;
        try {
          jsonData = json.decode(responseData);
          print('✅ Parsed JSON: $jsonData'); // ✅ Log parsed JSON
        } catch (e) {
          print('❌ Error parsing JSON: $e');
          _showErrorDialog('Error processing server response.');
          return;
        }

        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('skin_tone') && jsonData.containsKey('face_shape')) {
            setState(() {
              _skinTone = jsonData['skin_tone'];
              _faceShape = jsonData['face_shape'];
              _isLoading = false; // ✅ Ensure loading stops on success
            });
            _showResultDialog();
          } else {
            print('⚠️ Missing expected keys: $jsonData');
            _showErrorDialog('No results found. Please try again.');
          }
        } else {
          print('⚠️ Unexpected API response format: $jsonData');
          _showErrorDialog('Unexpected response from the server.');
        }
      } else {
        print('❌ Server error ${response.statusCode}: $responseData');
        _showErrorDialog('Server error ${response.statusCode}. Please try again.');
      }
    } catch (e) {
      print('❌ Error analyzing image: $e');
      _showErrorDialog('Network error. Please check your connection.');
    } finally {
      setState(() => _isLoading = false); // ✅ Ensure loading stops on failure
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.pink[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Analysis Result', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎨 Skin Tone:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_skinTone ?? 'Unknown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
              SizedBox(height: 10),
              Text('📏 Face Shape:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_faceShape ?? 'Unknown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
          ],
        );
      },
    );
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      setState(() {
        _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
        _initializeCamera();
      });
    } else {
      print('⚠️ No secondary camera available');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 40),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.width * 1.5,
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
                              } else {
                                return Center(child: CircularProgressIndicator());
                              }
                            },
                          )
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                    onPressed: _switchCamera,
                  ),
                  SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[300],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: _isLoading ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.camera_alt),
                    label: _isLoading ? Text('Analyzing...') : Text('Capture Look'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
