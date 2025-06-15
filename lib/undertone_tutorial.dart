import 'package:flutter/material.dart';
import 'dart:async';

class UndertoneTutorial extends StatefulWidget {
  const UndertoneTutorial({super.key});

  @override
  _UndertoneTutorialState createState() => _UndertoneTutorialState();
}

class _UndertoneTutorialState extends State<UndertoneTutorial> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Your Undertone",
            style: TextStyle(fontSize: 20)), // Increased from default
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 30),
            
            // Option 1 Section
            _buildSectionHeader("Option 1: Vein Test"),
            const SizedBox(height: 10),
            _buildSectionDescription(
                "Check the color of veins on your wrist under natural light"),
            const SizedBox(height: 20),
            
            // Vein Test Images - Vertical Layout
            Column(
              children: [
                _buildImageWithLabel('assets/vein_step1.jpg', "Step 1: Find natural light", context),
                const SizedBox(height: 25),
                _buildImageWithLabel('assets/vein_step2.jpg', "Step 2: Flip your wrist", context),
                const SizedBox(height: 25),
                _buildImageWithLabel('assets/vein_step3.jpg', "Step 3: Follow the instructions in the image", context),
                const SizedBox(height: 25),
                _buildImageWithLabel('assets/vein_step4.jpg', "Step 4: Match the color to your undertone", context),
              ],
            ),
            const SizedBox(height: 30),
            
            // Option 2 Section
            _buildSectionDescription(
                "Determine whether gold or silver jewelry complements you better"),
            const SizedBox(height: 20),
            _buildSectionHeader("Option 2: Jewelry Test"),
            const SizedBox(height: 10),
            _buildImageWithLabel('assets/jewelry_step1.jpg', "Step 1: Prepare your skin", context),
            const SizedBox(height: 25),
            _buildImageWithLabel('assets/jewelry_step2.jpg', "Step 2: Find natural lighting", context),
            const SizedBox(height: 25),
            _buildImageWithLabel('assets/jewelry_step3.jpg', "Step 3: Try on silver jewelry", context),
            const SizedBox(height: 25),
            _buildImageWithLabel('assets/jewelry_step4.jpg', "Step 4: Try on gold jewelry", context),
             const SizedBox(height: 25),
            _buildImageWithLabel('assets/jewelry_step5.jpg', "Step 4: Compare", context),
            
            // Interpretation Guide
            const SizedBox(height: 30),
            _buildSectionHeader("How to Interpret:"),
            const SizedBox(height: 15),
            _buildResultTile(
              color: Colors.blue.shade100,
              title: "Cool Undertone",
              description: "Blue/purple veins •Cool undertones suit shades with pink, red, or blue bases. These include rosy blushes, blue-based red lipsticks, plum or berry tones, and foundations labeled with cool or pink undertones.",
            ),
            _buildResultTile(
              color: Colors.green.shade100,
              title: "Warm Undertone",
              description: "Green veins • Warm undertones look best with shades that have yellow, peach, or golden bases. These include peach or coral blushes, brick or orange-red lipsticks, warm nudes, and foundations labeled with warm or golden undertones.",
            ),
            _buildResultTile(
              color: Colors.purple.shade100,
              title: "Neutral Undertone",
              description: "Blue-green veins • Neutral undertones can wear both cool and warm shades well. Soft pink, peach, natural beige foundations, and lipsticks or blushes that are not too warm or too cool usually suit this undertone.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, 
                color: Colors.amber.shade600, size: 24), // Increased from 20
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "For accurate results, follow the steps provided below",
                style: TextStyle(
                  fontSize: 16, // Increased from 15
                  color: Colors.grey.shade700,
                  height: 1.4,
                )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.pink.shade700,
              fontSize: 18, // Explicitly set larger size
            ));
  }

  Widget _buildSectionDescription(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16, // Increased from 14
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildImageWithLabel(String imagePath, String label, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40; // Account for padding
    
    return FutureBuilder(
      future: _getImageSize(imagePath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final imageSize = snapshot.data as Size;
          final aspectRatio = imageSize.width / imageSize.height;
          final imageHeight = screenWidth / aspectRatio;
          
          return Column(
            children: [
              Container(
                width: screenWidth,
                height: imageHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // Increased from 12
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          );
        } else {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }

  Widget buildFullWidthImage(String imagePath, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40; // Account for padding
    
    return FutureBuilder(
      future: _getImageSize(imagePath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final imageSize = snapshot.data as Size;
          final aspectRatio = imageSize.width / imageSize.height;
          final imageHeight = screenWidth / aspectRatio;
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: screenWidth,
                height: imageHeight,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        } else {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }

  Future<Size> _getImageSize(String imagePath) async {
    final Image image = Image.asset(imagePath);
    final Completer<Size> completer = Completer<Size>();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }

  Widget _buildResultTile({
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17, // Increased size
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15, // Increased size
          ),
        ),
      ),
    );
  }
}