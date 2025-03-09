import 'package:flutter/material.dart';

void main() {
  runApp(const GlamourApp());
}

class GlamourApp extends StatelessWidget {
  const GlamourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const UndertoneSelectionPage(),
    );
  }
}

class UndertoneSelectionPage extends StatefulWidget {
  const UndertoneSelectionPage({super.key});

  @override
  State<UndertoneSelectionPage> createState() => _UndertoneSelectionPageState();
}

class _UndertoneSelectionPageState extends State<UndertoneSelectionPage> {
  String? selectedUndertone;
  String? selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Undertone & Event'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Your Undertone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            buildButton('Warm', selectedUndertone == 'Warm', () {
              setState(() {
                selectedUndertone = 'Warm';
              });
            }),
            buildButton('Neutral', selectedUndertone == 'Neutral', () {
              setState(() {
                selectedUndertone = 'Neutral';
              });
            }),
            buildButton('Cool', selectedUndertone == 'Cool', () {
              setState(() {
                selectedUndertone = 'Cool';
              });
            }),
            const SizedBox(height: 20),
            const Text(
              'Select Makeup Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            buildButton('Casual', selectedEvent == 'Casual', () {
              setState(() {
                selectedEvent = 'Casual';
              });
              showSnackbar(context, 'Casual Event');
              navigateToRecommendationPage(context, 'Casual');
            }),
            buildButton('Light', selectedEvent == 'Light', () {
              setState(() {
                selectedEvent = 'Light';
              });
              showSnackbar(context, 'Light Event');
              navigateToRecommendationPage(context, 'Light');
            }),
            buildButton('Heavy', selectedEvent == 'Heavy', () {
              setState(() {
                selectedEvent = 'Heavy';
              });
              showSnackbar(context, 'Heavy Event');
              navigateToRecommendationPage(context, 'Heavy');
            }),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, bool isSelected, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.pinkAccent : Colors.grey[300],
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  void showSnackbar(BuildContext context, String event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You selected $event.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void navigateToRecommendationPage(BuildContext context, String event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeupRecommendationPage(
          undertone: selectedUndertone ?? 'Not Selected',
          event: event,
        ),
      ),
    );
  }
}

class MakeupRecommendationPage extends StatelessWidget {
  final String undertone;
  final String event;

  const MakeupRecommendationPage({super.key, required this.undertone, required this.event});

  @override
  Widget build(BuildContext context) {
    List<String> makeupLooks = [];

    if (event == 'Casual') {
      makeupLooks = ['No-Makeup Look', 'Everyday Glow', 'Sun-Kissed Glow'];
    } else if (event == 'Light') {
      makeupLooks = ['Dewy', 'Rosy Cheeks', 'Soft Glam'];
    } else if (event == 'Heavy') {
      makeupLooks = ['Matte Look', 'Cut Crease Look', 'Glam Night Look'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$event Makeup Looks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Undertone: $undertone',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            for (String look in makeupLooks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(look),
                ),
              ),
          ],
        ),
      ),
    );
  }
}