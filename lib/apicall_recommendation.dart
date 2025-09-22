import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiCallRecommendation {
  static const String _baseUrl = 'https://glamouraika.com/api';

  // Singleton pattern
  static final ApiCallRecommendation _instance = ApiCallRecommendation._internal();
  factory ApiCallRecommendation() => _instance;
  ApiCallRecommendation._internal();

  Future<Map<String, dynamic>> getFullRecommendation(
    int userId, {
    int? skinToneId,
    int? faceShapeId,
    int? undertoneId,
    String timeFilter = 'all', 
  }) async {
    final uri = Uri.parse('$_baseUrl/$userId/full_recommendation');
    
    // Add query parameters if they exist
    final params = <String, String>{};
    if (skinToneId != null) params['skin_tone_id'] = skinToneId.toString();
    if (faceShapeId != null) params['face_shape_id'] = faceShapeId.toString();
    if (undertoneId != null) params['undertone_id'] = undertoneId.toString();
    params['time_filter'] = timeFilter; 
    
    final response = await http.get(uri.replace(queryParameters: params));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recommendations. Status code: ${response.statusCode}');
    }
  }

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

// Data models for the recommendation response
class RecommendationResponse {
  final int userId;
  final String userFaceShape;
  final String userSkinTone;
  final String userUndertone;
  final FiltersUsed filtersUsed;
  final List<MakeupLookByType> topMakeupLooksByType;
  final List<SavedLook> mostUsedSavedLooks;
  final OverallLook? overallMostPopularLook;

  RecommendationResponse({
    required this.userId,
    required this.userFaceShape,
    required this.userSkinTone,
    required this.userUndertone,
    required this.filtersUsed,
    required this.topMakeupLooksByType,
    required this.mostUsedSavedLooks,
    this.overallMostPopularLook,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      userId: json['user_id'],
      userFaceShape: json['user_face_shape'],
      userSkinTone: json['user_skin_tone'],
      userUndertone: json['user_undertone'],
      filtersUsed: FiltersUsed.fromJson(json['filters_used']),
      topMakeupLooksByType: List<MakeupLookByType>.from(
          json['top_makeup_looks_by_type'].map((x) => MakeupLookByType.fromJson(x))),
      mostUsedSavedLooks: List<SavedLook>.from(
          json['most_used_saved_looks'].map((x) => SavedLook.fromJson(x))),
      overallMostPopularLook: json['overall_most_popular_look'] != null 
          ? OverallLook.fromJson(json['overall_most_popular_look']) 
          : null,
    );
  }
}

class FiltersUsed {
  final int skinToneId;
  final int faceShapeId;
  final int undertoneId;
  final String timePeriod;

  FiltersUsed({
    required this.skinToneId,
    required this.faceShapeId,
    required this.undertoneId,
    required this.timePeriod,
  });

  factory FiltersUsed.fromJson(Map<String, dynamic> json) {
    return FiltersUsed(
      skinToneId: json['skin_tone_id'],
      faceShapeId: json['face_shape_id'],
      undertoneId: json['undertone_id'],
      timePeriod: json['time_period'],
    );
  }
}

class MakeupLookByType {
  final int makeupTypeId;
  final String makeupTypeName;
  final int makeupLookId;
  final String makeupLookName;
  final int usageCount;
  final Map<String, List<Shade>> shadesByType;
  final String source;
  final String timePeriod;

  MakeupLookByType({
    required this.makeupTypeId,
    required this.makeupTypeName,
    required this.makeupLookId,
    required this.makeupLookName,
    required this.usageCount,
    required this.shadesByType,
    required this.source,
    required this.timePeriod,
  });

  factory MakeupLookByType.fromJson(Map<String, dynamic> json) {
    Map<String, List<Shade>> shadesMap = {};
    if (json['shades_by_type'] != null) {
      json['shades_by_type'].forEach((key, value) {
        shadesMap[key] = List<Shade>.from(value.map((x) => Shade.fromJson(x)));
      });
    }

    return MakeupLookByType(
      makeupTypeId: json['makeup_type_id'],
      makeupTypeName: json['makeup_type_name'],
      makeupLookId: json['makeup_look_id'],
      makeupLookName: json['makeup_look_name'],
      usageCount: json['usage_count'],
      shadesByType: shadesMap,
      source: json['source'],
      timePeriod: json['time_period'],
    );
  }
}

class SavedLook {
  final int makeupTypeId;
  final String makeupTypeName;
  final int makeupLookId;
  final String makeupLookName;
  final int saveCount;
  final Shade? shade;
  final String source;
  final String timePeriod;

  SavedLook({
    required this.makeupTypeId,
    required this.makeupTypeName,
    required this.makeupLookId,
    required this.makeupLookName,
    required this.saveCount,
    this.shade,
    required this.source,
    required this.timePeriod,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    return SavedLook(
      makeupTypeId: json['makeup_type_id'],
      makeupTypeName: json['makeup_type_name'],
      makeupLookId: json['makeup_look_id'],
      makeupLookName: json['makeup_look_name'],
      saveCount: json['save_count'],
      shade: json['shade'] != null ? Shade.fromJson(json['shade']) : null,
      source: json['source'],
      timePeriod: json['time_period'],
    );
  }
}

class OverallLook {
  final int makeupLookId;
  final String makeupLookName;
  final String makeupTypeName;
  final int usageCount;
  final Map<String, List<Shade>> shadesByType;
  final String timePeriod;

  OverallLook({
    required this.makeupLookId,
    required this.makeupLookName,
    required this.makeupTypeName,
    required this.usageCount,
    required this.shadesByType,
    required this.timePeriod,
  });

  factory OverallLook.fromJson(Map<String, dynamic> json) {
    Map<String, List<Shade>> shadesMap = {};
    if (json['shades_by_type'] != null) {
      json['shades_by_type'].forEach((key, value) {
        shadesMap[key] = List<Shade>.from(value.map((x) => Shade.fromJson(x)));
      });
    }

    return OverallLook(
      makeupLookId: json['makeup_look_id'],
      makeupLookName: json['makeup_look_name'],
      makeupTypeName: json['makeup_type_name'],
      usageCount: json['usage_count'],
      shadesByType: shadesMap,
      timePeriod: json['time_period'],
    );
  }
}

class Shade {
  final int shadeId;
  final String hexCode;
  final String shadeName;
  final String? shadeType;

  Shade({
    required this.shadeId,
    required this.hexCode,
    required this.shadeName,
    this.shadeType,
  });

  factory Shade.fromJson(Map<String, dynamic> json) {
    return Shade(
      shadeId: json['shade_id'],
      hexCode: json['hex_code'],
      shadeName: json['shade_name'],
      shadeType: json['shade_type'],
    );
  }
}