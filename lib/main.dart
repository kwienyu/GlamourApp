import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: LoginScreen(),
    );
  }
}