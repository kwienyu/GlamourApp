import 'package:flutter/material.dart';

class MakeupTipsPage extends StatelessWidget {
  final String faceShape;

  const MakeupTipsPage({super.key, required this.faceShape});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Makeup Tips for $faceShape Face',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildFaceShapeCard(faceShape, theme),
              const SizedBox(height: 30),
              ..._buildAllTipCards(context, faceShape),
            ],
          ),
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
      color: Colors.white.withOpacity(0.7),
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
            Icon(
              _getFaceShapeIcon(faceShape),
              size: 50,
              color: Colors.pink.shade400,
            ),
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
      color: Colors.white.withOpacity(0.9),
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
        return 'assets/placeholder.png'; // Fallback image
    }
  }

  IconData _getFaceShapeIcon(String faceShape) {
    switch (faceShape.toLowerCase()) {
      case 'oval':
        return Icons.circle_outlined;
      case 'round':
        return Icons.lens_outlined;
      case 'square':
        return Icons.crop_square_outlined;
      case 'heart':
        return Icons.favorite_border;
      case 'oblong':
        return Icons.rectangle_outlined;
      default:
        return Icons.face;
    }
  }
}

class MakeupTipsGenerator {
  static final Map<String, Map<String, String>> _tipsByFaceShape = {
    'Oval': {
      'blush': 'Apply blush on the apples of your cheeks and blend upwards.',
      'concealer': 'Apply under the eyes in a triangle shape, center of the forehead, and chin to brighten the face.',
      'contour': 'Light contour under cheekbones, from ear to mid-cheek, to add soft structure. Lightly contour sides of the nose.',
      'eyeshadow': 'Any style works—enhance with soft blending. Try a soft wing to lift the eye.',
      'foundation': 'Apply evenly. You can lightly contour for dimension but no major reshaping is needed.',
      'highlighter': 'Cheekbones, brow bone, and down the nose. Keep it natural and glowing.',
      'lipstick': 'Apply evenly. You can play with any lip shape—both defined or soft edges work.',
      'eyebrow': 'Follow your natural brow arch. Keep them softly curved.'
    },
    'Round': {
      'blush': 'Apply blush just above the apples of the cheeks and blend diagonally upward. Avoid placing too close to the nose.',
      'concealer': 'Brighten the center of face (forehead, under eyes, chin) to elongate.',
      'contour': 'Contour under cheekbones in a diagonal line from mid-ear to mouth corner. Lightly contour the jawline and sides of forehead.',
      'eyeshadow': 'Blend shadow or eyeliner going outwards (like a cat-eye).',
      'foundation': 'Apply a slightly darker shade on the sides of the face (temples to jawline) to create shadows and slim the face.',
      'highlighter': 'Focus on cheekbones and down the nose bridge for a lifted look. Avoid placing on round parts of the face.',
      'lipstick': 'Slightly overline the top lip, especially the Cupid\'s bow, to bring vertical balance.',
      'eyebrow': 'Arched brows help lift your face. Don\'t make them round.'
    },
    'Square': {
      'blush': 'Apply blush in a rounded motion on the apples of the cheeks. Avoid sharp diagonal strokes.',
      'concealer': 'Brighten under eyes and center of forehead.',
      'contour': 'Contour along the sides of the jawline, temples, and under cheekbones to soften.',
      'eyeshadow': 'Use soft, rounded shadow shapes. Avoid harsh lines—blend gently into the crease.',
      'foundation': 'Use darker foundation on the outer corners of the jaw and forehead to round them out.',
      'highlighter': 'Focus on high points of the face: cheekbones and brow bones. Avoid jawline highlight.',
      'lipstick': 'Round out the edges of the lips and use creamy or glossy formulas to soften the mouth shape.',
      'eyebrow': 'Soften square brows with a gentle arch or curve to balance the face.',
    },
    'Heart': {
      'blush': 'Apply to outer cheekbones, not center, and blend upward.',
      'concealer': 'Lighten the chin and under the eyes to bring balance.',
      'contour': 'Lightly contour sides of the forehead and under the chin.',
      'eyeshadow': 'Blended shadows and winged eyeliner help even out your look.',
      'foundation': 'Use a slightly darker shade on the sides of the forehead to narrow it. Keep center bright.',
      'highlighter': 'Highlight cheekbones and brow bones only. Avoid the chin to prevent focus on it.',
      'lipstick': 'Slightly overline or add gloss to the lower lip to balance the narrow chin.',
      'eyebrow': 'Keep brows soft and slightly curved. Avoid sharp high arches.',
    },
    'Oblong': {
      'blush': 'Apply horizontally across cheeks to add width (not upward).',
      'concealer': 'Brighten under the eyes and cheek area (not forehead or chin) to add focus to the center.',
      'contour': 'Contour top of forehead, under chin, and temples to shorten and widen face. Avoid harsh cheek contour.',
      'eyeshadow': 'Focus on horizontal blending (not upward) to widen eyes.',
      'foundation': 'Apply darker shade at top of forehead and chin to reduce length. Keep cheeks bright.',
      'highlighter': 'Use on cheekbones only. Avoid forehead and chin highlight.',
      'lipstick': 'Use wider lip shapes with gloss or ombré style to add horizontal fullness. Avoid overlining vertically.',
      'eyebrow': 'Go for flat or gently curved brows to shorten vertical space.',
    }
  };

  static String getTip(String faceShape, String productType) {
    return _tipsByFaceShape[faceShape]?[productType.toLowerCase()] ?? 
        'No tips available for $productType.';
  }
}