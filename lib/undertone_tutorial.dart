import 'package:flutter/material.dart';
import 'selection_page.dart';

class UndertoneTutorial extends StatelessWidget {
  const UndertoneTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Undertone Tutorial")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/undertone.png', width: 500, height: 500),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UndertoneSelectionPage(),
                    ),
                  );
                },
                child: const Text("Continue to Assessment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
