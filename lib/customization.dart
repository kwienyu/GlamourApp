import 'package:flutter/material.dart';

class CustomizationPage extends StatefulWidget {
  final String makeupLook;

  const CustomizationPage({super.key, required this.makeupLook});

  @override
  _MakeupCustomizeState createState() => _MakeupCustomizeState();
}

class _MakeupCustomizeState extends State<CustomizationPage> {
  String? selectedProduct;
  bool showMakeupProducts = false;
  bool showShades = false;

  Color? selectedLipstickShade;
  Color? selectedFoundationShade;
  Color? selectedConcealerShade;
  Color? selectedContourShade;
  Color? selectedEyeshadowShade;
  Color? selectedBlushShade;
  Color? selectedHighlighterShade;

  final Map<String, List<Color>> makeupShades = {
    'Foundation': [Colors.brown.shade100, Colors.brown.shade300, Colors.brown.shade500],
    'Concealer': [Colors.amber.shade100, Colors.amber.shade200, Colors.amber.shade300],
    'Contour': [Colors.brown.shade400, Colors.brown.shade600, Colors.brown.shade800],
    'Eyeshadow': [Colors.pink.shade200, Colors.purple.shade300, Colors.blue.shade300],
    'Blush': [Colors.pink.shade100, Colors.pink.shade300, Colors.pink.shade500],
    'Lipstick': [Colors.red.shade300, Colors.red.shade500, Colors.red.shade700],
    'Highlighter': [Colors.yellow.shade100, Colors.yellow.shade300, Colors.yellow.shade500],
  };

  final Map<String, String> productIcons = {
    'Foundation': 'assets/icons8-foundation.png',
    'Concealer': 'assets/icons8-concealer.png',
    'Contour': 'assets/icons8-contour.png',
    'Eyeshadow': 'assets/icons8-eyeshadow.png',
    'Blush': 'assets/icons8-blush-on.png',
    'Lipstick': 'assets/icons8-lipstick.png',
    'Highlighter': 'assets/icons8-sparkle.png',
  };

  Widget makeupOverlay(Color shade, double left, double top, double width, double height, double opacity) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: shade.withOpacity(opacity),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double imageWidth = constraints.maxWidth;
          double imageHeight = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/facetest.webp',
                  fit: BoxFit.cover,
                ),
              ),

              if (selectedFoundationShade != null)
                makeupOverlay(selectedFoundationShade!, imageWidth * 0.3, imageHeight * 0.4, imageWidth * 0.4, imageHeight * 0.4, 0.5),

              if (selectedConcealerShade != null)
                makeupOverlay(selectedConcealerShade!, imageWidth * 0.35, imageHeight * 0.45, imageWidth * 0.2, imageHeight * 0.2, 0.5),

              if (selectedContourShade != null)
                makeupOverlay(selectedContourShade!, imageWidth * 0.32, imageHeight * 0.48, imageWidth * 0.3, imageHeight * 0.1, 0.5),

              if (selectedEyeshadowShade != null)
                makeupOverlay(selectedEyeshadowShade!, imageWidth * 0.45, imageHeight * 0.3, imageWidth * 0.2, imageHeight * 0.05, 0.6),

              if (selectedBlushShade != null)
                makeupOverlay(selectedBlushShade!, imageWidth * 0.4, imageHeight * 0.55, imageWidth * 0.2, imageHeight * 0.1, 0.5),

              if (selectedLipstickShade != null)
                makeupOverlay(selectedLipstickShade!, imageWidth * 0.45, imageHeight * 0.65, imageWidth * 0.15, imageHeight * 0.05, 0.6),

              if (selectedHighlighterShade != null)
                makeupOverlay(selectedHighlighterShade!, imageWidth * 0.43, imageHeight * 0.35, imageWidth * 0.2, imageHeight * 0.07, 0.5),

              Positioned(
                left: 10,
                top: 100,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showMakeupProducts = !showMakeupProducts;
                      showShades = false;
                    });
                  },
                  child: Icon(
                    showMakeupProducts ? Icons.visibility : Icons.visibility_off,
                    size: 30,
                    color: Colors.pinkAccent,
                  ),
                ),
              ),

              if (showMakeupProducts)
                Positioned(
                  left: 8,
                  top: 75,
                  bottom: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: makeupShades.keys.map((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedProduct = product;
                              showShades = true;
                            });
                          },
                          child: Transform.scale(
                            scale: selectedProduct == product ? 1.02 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.pink.shade100, Colors.pink.shade300],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: selectedProduct == product ? Colors.red : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              padding: EdgeInsets.all(8),
                              child: Image.asset(
                                productIcons[product] ?? 'assets/icons8-foundation.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              if (showShades && selectedProduct != null)
                Positioned(
                  right: 10,
                  top: 140,
                  child: Column(
                    children: makeupShades[selectedProduct]!.map((shade) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedProduct == 'Lipstick') selectedLipstickShade = shade;
                            if (selectedProduct == 'Foundation') selectedFoundationShade = shade;
                            if (selectedProduct == 'Concealer') selectedConcealerShade = shade;
                            if (selectedProduct == 'Contour') selectedContourShade = shade;
                            if (selectedProduct == 'Eyeshadow') selectedEyeshadowShade = shade;
                            if (selectedProduct == 'Blush') selectedBlushShade = shade;
                            if (selectedProduct == 'Highlighter') selectedHighlighterShade = shade;
                          });
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: shade,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              Positioned(
                bottom: 20,
                left: 30,
                right: 30,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.makeupLook,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedLipstickShade = null;
                                selectedFoundationShade = null;
                                selectedConcealerShade = null;
                                selectedContourShade = null;
                                selectedEyeshadowShade = null;
                                selectedBlushShade = null;
                                selectedHighlighterShade = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text("Retake"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              print("Makeup look '${widget.makeupLook}' saved!");
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: Text("Save Look"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
