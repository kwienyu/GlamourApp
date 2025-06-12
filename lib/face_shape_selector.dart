import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceShapeSelectorScreen extends StatelessWidget {
  final List<String> faceShapes = ['Oval', 'Round', 'Square', 'Heart', 'Oblong'];

 FaceShapeSelectorScreen({super.key});

  Future<void> _saveFaceShape(String shape, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('face_shape', shape);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Face shape set to $shape!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Face Shape")),
      body: ListView.builder(
        itemCount: faceShapes.length,
        itemBuilder: (ctx, index) => ListTile(
          title: Text(faceShapes[index]),
          onTap: () => _saveFaceShape(faceShapes[index], ctx),
        ),
      ),
    );
  }
}