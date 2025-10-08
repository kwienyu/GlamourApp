import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'makeup_guide.dart';

class MakeupTipsPage extends StatefulWidget {
  final String userId;

  const MakeupTipsPage({super.key, required this.userId});

  @override
  State<MakeupTipsPage> createState() => _MakeupTipsPageState();
}

class _MakeupTipsPageState extends State<MakeupTipsPage> {
  String? faceShape;
  bool isLoading = true;
  String errorMessage = '';
  bool showAnalysisOption = false;

  @override
  void initState() {
    super.initState();
    _fetchUserFaceShape();
  }

  Future<void> _fetchUserFaceShape() async {
    try {
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/user-face-shape?user_id=${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          faceShape = data['face_shape'];
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Face shape analysis not found. Please complete a face analysis first in the app.';
          isLoading = false;
          showAnalysisOption = true; 
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load face shape. Please try again. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      elevation: 0,
      title: Image.asset(
        'assets/glam_logo.png',
        height: screenHeight * 0.10,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.face_retouching_natural,
            color: Colors.black,
            size: isSmallScreen ? screenWidth * 0.08 : 32,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MakeupGuide(userId: widget.userId.toString()),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF2F8),
              Color(0xFFFAF5FF),
            ],
          ),
        ),
        child: isLoading
            ? Center( 
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.pinkAccent,
                  size: isSmallScreen ? 50 : 60,
                ),
              )
            : faceShape != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildFaceShapeCard(faceShape!, theme),
                        const SizedBox(height: 30),
                        ..._buildAllTipCards(context, faceShape!),
                      ],
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? showAnalysisOption
                        ? _buildAnalysisPrompt(context)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          )
                    : Center(
                        child: Text(
                          'Unable to determine face shape',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
      ),
    );
  }

  Widget _buildAnalysisPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 80,
              color: Colors.pink.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Face Shape Analysis Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.pink.shade800,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 15),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            Text(
              'Please complete the face analysis in the app first to get personalized makeup tips.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceShapeCard(String faceShape, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Colors.pink.shade100,
          width: 1.5,
        ),
      ),
      color: Colors.white.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Face Shape:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.pink.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              faceShape,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.pink.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllTipCards(BuildContext context, String faceShape) {
    final categories = [
      'Foundation',
      'Concealer',
      'Blush',
      'Contour',
      'Eyeshadow',
      'Highlighter',
      'Lipstick',
      'Eyebrow',
    ];

    return categories.map((category) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: _buildTipCard(
          context,
          category,
          MakeupTipsGenerator.getTip(faceShape, category),
          _getCategoryImage(category),
        ),
      );
    }).toList();
  }

  Widget _buildTipCard(
      BuildContext context, String title, String tip, String imagePath) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white.withValues(alpha: 0.9),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.help_outline,
                  color: Colors.pink.shade400,
                  size: 20,
                );
              },
            ),
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.pink.shade800,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case 'foundation':
        return 'assets/foundation.png';
      case 'concealer':
        return 'assets/concealer.png';
      case 'blush':
        return 'assets/blush.png';
      case 'contour':
        return 'assets/contour.png';
      case 'eyeshadow':
        return 'assets/eyeshadow.png';
      case 'highlighter':
        return 'assets/highlighter.png';
      case 'lipstick':
        return 'assets/lipstick.png';
      case 'eyebrow':
        return 'assets/eyebrow.png';
      default:
        return 'assets/placeholder.png';
    }
  }
}

class MakeupTipsGenerator {
  static final Map<String, Map<String, String>> _tipsByFaceShape = {
    'Oval': {
      'Foundation': 'Apply evenly. You can lightly contour for dimension but no major reshaping is needed.',
      'Concealer': 'Apply under the eyes in a triangle shape, center of the forehead, and chin to brighten the face.',
      'Blush': 'Apply blush on the apples of your cheeks and blend upwards.',
      'Contour': 'Light contour under cheekbones, from ear to mid-cheek, to add soft structure. Lightly contour sides of the nose.',
      'Eyeshadow': 'Any style works—enhance with soft blending. Try a soft wing to lift the eye.',
      'Highlighter': 'Cheekbones, brow bone, and down the nose. Keep it natural and glowing.',
      'Lipstick': 'Apply evenly. You can play with any lip shape—both defined or soft edges work.',
      'Eyebrow': 'Follow your natural brow arch. Keep them softly curved.'
    },
    'Round': {
      'Foundation': 'Apply even base; blend well into hairline and jaw to avoid obvious edges. ',
      'Concealer': 'Apply under eyes in an upward triangle to lift the eye area.',
      'Blush': 'Place blush a bit higher on your cheekbones (line it up with your eye corner) and brush upward toward your temples.',
      'Contour': 'Shade around the outer edges of your face and under your cheekbones to add definition.',
      'Eyeshadow': 'Darken the outer corners and blend outward to make eyes look longer.',
      'Highlighter': 'Add lightly to nose, forehead, cheekbones, and brow bone — don’t overdo it or it can make your face look wider.',
      'Lipstick': ': No direct face-shape-specific source found for lips on round faces — use general lip rules (center gloss to elongate).',
      'Eyebrow': 'Arched brows help lift your face. Don\'t make them round.'
    },
    'Square': {
      'Foundation': 'Use darker foundation on the outer corners of the jaw and forehead to round them out.',
      'Concealer': 'Brighten under eyes and center of forehead.',
      'Blush': 'Apply blush in a rounded motion on the apples of the cheeks. Avoid sharp diagonal strokes.',
      'Contour': 'Shade the corners of your forehead and jaw, plus under cheekbones, to round out strong lines.',
      'Eyeshadow': 'Use soft, rounded shadow shapes. Avoid harsh lines—blend gently into the crease.',
      'Highlighter': 'Use a soft “C” shape (cheekbone → temple) to draw the eye inward and soften lines.',
      'Lipstick': 'Round out the edges of the lips and use creamy or glossy formulas to soften the mouth shape.',
      'Eyebrow': 'Soften square brows with a gentle arch or curve to balance the face.',
    },
    'Heart': {
      'Foundation': 'Apply evenly all over, blending into your hairline and jaw so your forehead and chin look balanced. ',
      'Concealer': 'Brighten under your eyes, center of forehead, and chin to bring focus to the middle of your face.',
      'Blush': 'Put blush a little away from your nose on the tops of your cheeks, then brush outward toward your ears.',
      'Contour': 'Apply contour to the top of the forehead and blend down toward the temples; contour under the cheekbones to slim the top of the face. ',
      'Eyeshadow': 'Keep color on the outer corners of your eyes, blending outward. Avoid super heavy liner on top.',
      'Highlighter': 'Add a light glow on cheekbones, brow bone, nose bridge, Cupid’s bow, and chin.',
      'Lipstick': 'Use a bold or brighter lip to draw attention downward, balancing a wider top of the face.',
      'Eyebrow': 'Soften with a rounded/soft arch (rounded brows help reduce perceived harshness of the forehead).',
    },
    'Oblong': {
      'Foundation': 'Apply darker shade at top of forehead and chin to reduce length. Keep cheeks bright.',
      'Concealer': 'Focus under eyes and the T-zone; don’t add too much on chin or forehead. ',
      'Blush': 'Put blush on the apples of your cheeks and blend sideways (not upward) to make your face look wider.',
      'Contour': 'Focus under eyes and the T-zone; don’t add too much on chin or forehead.',
      'Eyeshadow': 'Focus on horizontal blending (not upward) to widen eyes.',
      'Highlighter': 'Use on cheekbones only. Avoid forehead and chin highlight.',
      'Lipstick': 'Use wider lip shapes with gloss or ombré style to add horizontal fullness. Avoid overlining vertically.',
      'Eyebrow': 'Go for flat or gently curved brows to shorten vertical space.',
    }
  };

  static String getTip(String faceShape, String productType) {
    return _tipsByFaceShape[faceShape]?[productType] ?? 
        'No specific tips available for $productType with a $faceShape face shape.';
  }
}