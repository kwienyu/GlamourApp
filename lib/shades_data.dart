import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

class ShadesService {
  static Future<List<Map<String, dynamic>>> fetchShadesData() async {
    final response = await http.get(Uri.parse(
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQAReV2aO8NRhlKbEX4PobyMehTkmshX0Gc6xPHnSuJNwoFoqmfixO5MuGPVkcKZIOlL-ByFAhvKkK4/pub?output=csv',
    ));

    if (response.statusCode == 200) {
      final csvData = const CsvToListConverter().convert(response.body);
      final headers = csvData[0].cast<String>();
      
      return csvData.skip(1).map((row) {
        return Map.fromIterables(headers, row);
      }).toList();
    } else {
      throw Exception('Failed to fetch shades data');
    }
  }

  static Future<Map<String, dynamic>> searchShades({
    String? skintone,
    String? undertone,
  }) async {
    final allShades = await fetchShadesData();
    
    // Filter based on search criteria
    final filteredShades = allShades.where((shade) {
      final skintoneMatch = skintone == null || 
          (shade['skintone']?.toString().toLowerCase() == skintone.toLowerCase());
      final undertoneMatch = undertone == null || 
          (shade['undertone']?.toString().toLowerCase() == undertone.toLowerCase());
      return skintoneMatch && undertoneMatch;
    }).toList();

    // Group by makeup look and type
    final makeupLooks = {};
    final makeupTypes = {};

    for (final shade in filteredShades) {
      final look = shade['makeup_look']?.toString() ?? 'Unknown Look';
      final type = shade['makeup_type']?.toString() ?? 'Unknown Type';
      
      // Add to makeup looks
      if (!makeupLooks.containsKey(look)) {
        makeupLooks[look] = [];
      }
      makeupLooks[look].add(shade);
      
      // Add to makeup types
      if (!makeupTypes.containsKey(type)) {
        makeupTypes[type] = [];
      }
      makeupTypes[type].add(shade);
    }

    return {
      'shades': filteredShades,
      'makeup_looks': makeupLooks,
      'makeup_types': makeupTypes,
    };
  }
}