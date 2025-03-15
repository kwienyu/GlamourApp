import 'package:flutter/material.dart';
import 'selection_page.dart';

class UndertoneTutorial extends StatefulWidget {
  const UndertoneTutorial({super.key});

  @override
  _UndertoneTutorialState createState() => _UndertoneTutorialState();
}

class _UndertoneTutorialState extends State<UndertoneTutorial> {
  void _onProceed() {
    // Trigger water ripple effect and navigate after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectionPage()),
      );
    });
  }

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
              SizedBox(
                width: 150,
                height: 45,
                child: Material(
                  color: const Color.fromARGB(255, 239, 134, 169),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.white.withOpacity(0.3), // Water ripple effect
                    onTap: _onProceed,
                    child: const Center(
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 243, 241, 242),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
