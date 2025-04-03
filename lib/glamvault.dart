import 'package:flutter/material.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';

class GlamVaultPage extends StatefulWidget {
  const GlamVaultPage({super.key});

  @override
  _GlamVaultPageState createState() => _GlamVaultPageState();
}

class _GlamVaultPageState extends State<GlamVaultPage> {
  late FlutterMediapipe _mediapipe;
  late Stream<NormalizedLandmarkList> _landmarkStream;
  List<NormalizedLandmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _initializeFaceMesh();
  }

  Future<void> _initializeFaceMesh() async {
    _mediapipe = FlutterMediapipe();
    _landmarkStream = _mediapipe.landMarksStream;
    _landmarkStream.listen(_onLandMarkStream);
  }

  void _onLandMarkStream(NormalizedLandmarkList landmarkList) {
    setState(() {
      _landmarks = landmarkList.landmark;
    });
  }

  Widget _buildFaceMeshOverlay() {
    return CustomPaint(
      painter: FaceMeshPainter(_landmarks),
      child: Container(color: Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Mesh')),
      body: Stack(
        children: [
          NativeView(
            onViewCreated: (FlutterMediapipe c) => setState(() {
              _mediapipe = c;
              c.landMarksStream.listen(_onLandMarkStream);
              c.platformVersion.then((content) => print(content));
            }),
          ),
          _buildFaceMeshOverlay(),
        ],
      ),
    );
  }
}

class FaceMeshPainter extends CustomPainter {
  final List<NormalizedLandmark> landmarks;

  FaceMeshPainter(this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 111, 234, 111)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (landmarks.isEmpty) return;

    final Path path = Path();
    final List<int> faceOutlineIndices = [
      10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379,
      378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127,
      162, 21, 54, 103, 67, 109
    ];

    for (int i = 0; i < faceOutlineIndices.length; i++) {
      int index = faceOutlineIndices[i];
      if (index >= landmarks.length) continue;
      Offset position = Offset(
        landmarks[index].x * size.width,
        landmarks[index].y * size.height,
      );
      if (i == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    path.close(); // Ensure the path is closed properly
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
