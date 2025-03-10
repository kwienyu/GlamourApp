import 'package:flutter/material.dart';
import 'camera.dart'; // Import your camera page

class MakeupLookRecommendationPage extends StatelessWidget {
  final String makeupType;

  const MakeupLookRecommendationPage({super.key, required this.makeupType});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> makeupLooks = {
      'Light': ['Dewy', 'Rosy Cheeks', 'Soft Glam'],
      'Casual': ['No-Makeup Look', 'Everyday Glow', 'Sun-Kissed Glow'],
      'Heavy': ['Matte', 'Cut Crease', 'Glam Night Look'],
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Makeup Recommendations',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Makeup Looks for $makeupType',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: makeupLooks[makeupType]!.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.pink[50],
                    child: ListTile(
                      title: Text(
                        makeupLooks[makeupType]![index],
                        style: const TextStyle(color: Colors.black),
                      ),
                      onTap: () {
                        // Navigate to CameraPage after user clicks a look
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraPage(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

