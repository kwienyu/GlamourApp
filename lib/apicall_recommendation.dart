import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiCallRecommendation {
  static const String _baseUrl = 'https://glamouraika.com/api';

  // Singleton pattern
  static final ApiCallRecommendation _instance = ApiCallRecommendation._internal();
  factory ApiCallRecommendation() => _instance;
  ApiCallRecommendation._internal();

  /// Fetches full makeup recommendations based on user's attributes
  /// 
  /// Parameters:
  /// - userId: The ID of the user
  /// - skinToneId: Optional filter for skin tone
  /// - faceShapeId: Optional filter for face shape
  /// - undertoneId: Optional filter for undertone
  Future<Map<String, dynamic>> getFullRecommendation(
    int userId, {
    int? skinToneId,
    int? faceShapeId,
    int? undertoneId,
  }) async {
    final uri = Uri.parse('$_baseUrl/$userId/full_recommendation');
    
    // Add query parameters if they exist
    final params = <String, String>{};
    if (skinToneId != null) params['skin_tone_id'] = skinToneId.toString();
    if (faceShapeId != null) params['face_shape_id'] = faceShapeId.toString();
    if (undertoneId != null) params['undertone_id'] = undertoneId.toString();
    
    final response = await http.get(uri.replace(queryParameters: params));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recommendations. Status code: ${response.statusCode}');
    }
  }

  /// Fetches top shades by type and skin tone for a given period
  ///
  /// Parameters:
  /// - period: 'week' or 'month' for the time period
  /// - skinTone: The skin tone to filter by
  Future<List<Map<String, dynamic>>> getTopShades(String period, String skinTone) async {
    final uri = Uri.parse('https://glamouraika.com/api/top_3_shades_by_type_and_skintone?period=$period');
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final topShades = data['top_3_shades_by_skin_tone_and_type'][skinTone];
      
      if (topShades == null) return [];
      
      final convertedData = <String, List<Map<String, dynamic>>>{};
      
      topShades.forEach((category, shadeList) {
        final topShade = (shadeList as List)
            .firstWhere((shade) => shade['rank'] == 1, orElse: () => null);
        if (topShade != null) {
          convertedData[category.toLowerCase()] = [
            {
              'hex_code': topShade['hex_code'],
              'match_count': topShade['times_used'],
              'rank': topShade['rank'],
              'shade_name': topShade['shade_name'],
            }
          ];
        }
      });
      
      return [convertedData];
    } else {
      throw Exception('Failed to load top shades. Status code: ${response.statusCode}');
    }
  }

  /// Alternative method to get top shades that returns a Map directly
  Future<Map<String, List<Map<String, dynamic>>>> getTopShadesMap(
      String period, String skinTone) async {
    final uri = Uri.parse('https://glamouraika.com/api/top_3_shades_by_type_and_skintone?period=$period');
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final topShades = data['top_3_shades_by_skin_tone_and_type'][skinTone];
      
      if (topShades == null) return {};
      
      final convertedData = <String, List<Map<String, dynamic>>>{};
      
      topShades.forEach((category, shadeList) {
        final topShade = (shadeList as List)
            .firstWhere((shade) => shade['rank'] == 1, orElse: () => null);
        if (topShade != null) {
          convertedData[category.toLowerCase()] = [
            {
              'hex_code': topShade['hex_code'],
              'match_count': topShade['times_used'],
              'rank': topShade['rank'],
              'shade_name': topShade['shade_name'],
            }
          ];
        }
      });
      
      return convertedData;
    } else {
      throw Exception('Failed to load top shades. Status code: ${response.statusCode}');
    }
  }
}

