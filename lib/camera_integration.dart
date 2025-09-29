import 'package:camera/camera.dart';

class CameraIntegration {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isInitialized = false;

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);

    await _controller!.initialize();
    _isInitialized = true;
  }

  Future<Map<String, String>> capture() async {
    if (!_isInitialized) {
      await initializeCamera();
    }
    final image = await _controller!.takePicture();
    final faceShape = await _detectFaceShape(image.path);
    final skinTone = await _detectSkinTone(image.path);

    return {
      'face_shape': faceShape,
      'skin_tone': skinTone,
    };
  }
  Future<String> _detectFaceShape(String imagePath) async {
    return 'Round'; 
  }
  Future<String> _detectSkinTone(String imagePath) async {
    return 'Warm'; 
  }
  void dispose() {
    _controller?.dispose();
  }
}
