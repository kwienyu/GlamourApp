import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Needed for debug settings
import 'glamvault.dart';
//import 'facemesh.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable all debug paint options
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugPaintLayerBordersEnabled = false;

  runApp(const GlamourApp());
}


class GlamourApp extends StatelessWidget {
  const GlamourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GlamVaultPage(),
    );
  }
} 

/*
class GlamourApp extends StatelessWidget {
  const GlamourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(), // Replace with your FaceMesh page
    );
  }
}*/
