import 'package:flutter/material.dart';

class MakeupRecommendationPage extends StatelessWidget {
  final String event;

  const MakeupRecommendationPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    List<String> makeupLooks = [];

    // Define Makeup Looks based on Event
    if (event == 'Casual') {
      makeupLooks = [
        'No-Makeup Look',
        'Everyday Glow',
        'Sun-Kissed Glow',
      ];
    } else if (event == 'Light') {
      makeupLooks = [
        'Dewy',
        'Rosy Cheeks',
        'Soft Glam',
      ];
    } else if (event == 'Heavy') {
      makeupLooks = [
        'Matte Look',
        'Cut Crease Look',
        'Glam Night Look',
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$event Makeup Looks'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Your Makeup Look',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Generate Buttons Based on Makeup Looks
            for (String look in makeupLooks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to a Final Page if needed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FinalPage(look: look),
                      ),
                    );
                  },
                  child: Text(look),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FinalPage extends StatelessWidget {
  final String look;

  const FinalPage({super.key, required this.look});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Look'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You Selected: $look',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
