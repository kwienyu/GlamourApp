import 'package:flutter/material.dart';

class UndertoneTutorial extends StatefulWidget {
  const UndertoneTutorial({super.key});

  @override
  _UndertoneTutorialState createState() => _UndertoneTutorialState();
}

class _UndertoneTutorialState extends State<UndertoneTutorial> {
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Undertone Tutorial")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 3),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color.fromARGB(255, 74, 194, 238), size: 20),
                    const SizedBox(width: 5),
                    const Text(
                      "Ensure proper lighting for accuracy",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Image.asset('assets/undertone.png', width: 550, height: 550),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
