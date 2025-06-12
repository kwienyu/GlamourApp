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
      'blush': '	Apply blush just above the apples of the cheeks and blend diagonally upward. Avoid placing too close to the nose.',
      'concealer': 'Brighten the center of face (forehead, under eyes, chin) to elongate.',
      'contour': '	Contour under cheekbones in a diagonal line from mid-ear to mouth corner. Lightly contour the jawline and sides of forehead.',
      'eyeshadow': 'lend shadow or eyeliner going outwards (like a cat-eye).',
      'foundation': '	Apply a slightly darker shade on the sides of the face (temples to jawline) to create shadows and slim the face.',
      'highlighter': 'Focus on cheekbones and down the nose bridge for a lifted look. Avoid placing on round parts of the face.',
      'lipstick': 'Slightly overline the top lip, especially the Cupid’s bow, to bring vertical balance.',
      'eyebrow': 'Arched brows help lift your face. Don’t make them round.'
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
      'highlighter': 'ighlight cheekbones and brow bones only. Avoid the chin to prevent focus on it.',
      'lipstick': 'Slightly overline or add gloss to the lower lip to balance the narrow chin.',
      'eyebrow': 'Keep brows soft and slightly curved. Avoid sharp high arches.',
    },
    'Oblong': {
      'blush': 'Apply horizontally across cheeks to add width (not upward).',
      'concealer': 'Brighten under the eyes and cheek area (not forehead or chin) to add focus to the center.',
      'contour': '	Contour top of forehead, under chin, and temples to shorten and widen face. Avoid harsh cheek contour.',
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

