import 'package:flutter/material.dart';

class CustomizationPage extends StatefulWidget {
  final String makeupLook;

  const CustomizationPage({super.key, required this.makeupLook});

  @override
  _MakeupCustomizeState createState() => _MakeupCustomizeState();
}

class _MakeupCustomizeState extends State<CustomizationPage> {
  String selectedProduct = 'Blush';
  String capturedImagePath = "assets/facetest.webp";

  // Makeup Shades
  final Map<String, List<Color>> makeupShades = {
    'Foundation': [Colors.brown[100]!, Colors.brown[300]!, Colors.brown[500]!],
    'Concealer': [Colors.amber[100]!, Colors.amber[200]!, Colors.amber[300]!],
    'Contour': [Colors.brown[400]!, Colors.brown[600]!, Colors.brown[800]!],
    'Eyeshadow': [Colors.pink[200]!, Colors.purple[300]!, Colors.blue[300]!],
    'Blush': [Colors.pink[100]!, Colors.pink[300]!, Colors.pink[500]!],
    'Lipstick': [Colors.red[300]!, Colors.red[500]!, Colors.red[700]!],
    'Highlighter': [Colors.yellow[100]!, Colors.yellow[300]!, Colors.yellow[500]!],
  };

  Map<String, Color> appliedShades = {
    'Blush': Colors.transparent,
    'Lipstick': Colors.transparent,
    'Eyeshadow': Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Makeup Customization")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  capturedImagePath,
                  fit: BoxFit.cover, // Makes the image fill the screen
                ),
                _applyMakeupOverlay('Blush',
                    top: MediaQuery.of(context).size.height * 0.45,
                    left: MediaQuery.of(context).size.width * 0.35),
                _applyMakeupOverlay('Lipstick',
                    top: MediaQuery.of(context).size.height * 0.55,
                    left: MediaQuery.of(context).size.width * 0.40),
                _applyMakeupOverlay('Eyeshadow',
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: MediaQuery.of(context).size.width * 0.38),
              ],
            ),
          ),

          // Product Selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: makeupShades.keys.map((product) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedProduct = product;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedProduct == product ? Colors.red : Colors.grey,
                    ),
                    child: Text(product),
                  ),
                );
              }).toList(),
            ),
          ),

          // Shades Selection
          Wrap(
            spacing: 10,
            children: (makeupShades[selectedProduct] ?? []).map((shade) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    appliedShades[selectedProduct] = shade;
                  });
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: shade,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),

          // Retake & Save Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    appliedShades = {
                      'Blush': Colors.transparent,
                      'Lipstick': Colors.transparent,
                      'Eyeshadow': Colors.transparent,
                    };
                  });
                },
                child: const Text('Retake', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                child: const Text('Save Look', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _applyMakeupOverlay(String product, {required double top, required double left}) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (appliedShades[product] ?? Colors.transparent).withOpacity(0.3),
        ),
      ),
    );
  }
}

