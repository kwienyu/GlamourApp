import 'package:flutter/material.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'dart:developer' as developer;

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
      appBar: AppBar(title: Text('Glam Vault')),
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
      ..color = const Color.fromARGB(58, 0, 204, 255)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var landmark in landmarks) {
      final Offset position = Offset(
        landmark.x * size.width,
        landmark.y * size.height
      );
      canvas.drawCircle(position, 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
