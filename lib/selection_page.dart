import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectionPage extends StatefulWidget {
  final String userId;
  const SelectionPage({super.key, required this.userId});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String _selectedSkinTone = 'morena'; 
  String _selectedShadeCategory = 'foundation';
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, Map<String, List<Map<String, dynamic>>>> _shadesData = {};

  final List<String> _skinToneOptions = ['morena', 'chinita', 'mestiza'];
  final List<String> _categoryOrder = [
    'foundation',
    'concealer',
    'contour',
    'eyeshadow',
    'blush',
    'lipstick',
    'eyebrow',
    'highlighter'
  ];

  // Map of skin tone to image asset
  final Map<String, String> _skinToneImages = {
    'morena': 'assets/morena_button.png',
    'chinita': 'assets/chinita_button.png',
    'mestiza': 'assets/mestiza_button.png',
  };

  @override
  void initState() {
    super.initState();
    _fetchTopShades();
  }
  Future<void> _fetchTopShades() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/top_3_shades_by_type_and_skintone?period=month'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topShades = data['top_3_shades_by_skin_tone_and_type'] as Map<String, dynamic>;
        
        final convertedData = <String, Map<String, List<Map<String, dynamic>>>>{};
        
        topShades.forEach((skinTone, categories) {
          final skinToneKey = skinTone.toLowerCase();
          convertedData[skinToneKey] = {};
          
          (categories as Map<String, dynamic>).forEach((category, shades) {
            final categoryKey = category.toLowerCase();
            convertedData[skinToneKey]![categoryKey] = []; 

            for (var shade in (shades as List<dynamic>)) {
              convertedData[skinToneKey]![categoryKey]!.add({
                'hex_code': shade['hex_code'],
                'match_count': shade['times_used'],
                'shade_name': shade['shade_name'],
                'rank': shade['rank'],
              });
            }
          });
        });

        setState(() {
          _shadesData = convertedData;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shade Recommendations'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.pinkAccent,
            size: 50,
          ),
          const SizedBox(height: 16),
          const Text('Loading recommendations...'),
        ],
      ),
    );
  }

  if (_hasError || _shadesData.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load data'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchTopShades,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  return SingleChildScrollView(
    child: Column(
      children: [
        _buildShadeRecommendationsSection(context),
      ],
    ),
  );
}
  Widget _buildShadeRecommendationsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Added extra space at the top
          Text(
            'Top Shades',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink[800],
            ),
          ),
          const SizedBox(height: 25), // Increased this spacing
          _buildSkinToneSelector(),
          const SizedBox(height: 25), // Increased this spacing
          _buildShadeCategoryTabs(),
          const SizedBox(height: 25), // Increased this spacing
          _buildTopShadesList(),
          const SizedBox(height: 25), // Increased this spacing
          _buildCircularUsageGraph(),
          const SizedBox(height: 25), // Increased this spacing
          _buildViewAnalyticsButton(context),
        ],
      ),
    );
  }

Widget _buildSkinToneSelector() {
    return SizedBox(
      height: 140, // Increased height to accommodate larger images
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _skinToneOptions.length,
        itemBuilder: (context, index) {
          final skinTone = _skinToneOptions[index];
          final displayName = skinTone[0].toUpperCase() + skinTone.substring(1);
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSkinTone = skinTone);
            },
            child: Container(
              width: 110, // Increased width
              margin: const EdgeInsets.only(right: 15), // Increased margin
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSkinTone == skinTone 
                      ? Colors.pinkAccent 
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Align to top
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      height: 100, // Increased height for the image
                      width: double.infinity,
                      color: _getSkinToneColor(skinTone),
                      child: _skinToneImages.containsKey(skinTone)
                          ? Image.asset(
                              _skinToneImages[skinTone]!,
                              fit: BoxFit.contain, // Changed to contain to prevent cutting
                              alignment: Alignment.bottomCenter, // Align image to bottom
                            )
                          : Center(
                              child: Text(
                                displayName[0],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8), // Increased padding
                    decoration: BoxDecoration(
                      color: _selectedSkinTone == skinTone
                          ? Colors.pinkAccent.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 13, // Slightly larger font
                        fontWeight: FontWeight.bold,
                        color: _selectedSkinTone == skinTone
                            ? Colors.pinkAccent
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // Helper method to get a color for each skin tone (fallback if image not available)
  Color _getSkinToneColor(String skinTone) {
    switch (skinTone) {
      case 'morena':
        return const Color(0xFF8D5524);
      case 'chinita':
        return const Color(0xFFFFDBAC);
      case 'mestiza':
        return const Color(0xFFE0AC69);
      default:
        return Colors.grey;
    }
  }

  Widget _buildShadeCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryOrder.length,
        itemBuilder: (context, index) {
          final category = _categoryOrder[index];
          final displayName = category[0].toUpperCase() + category.substring(1);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedShadeCategory == category 
                      ? Colors.white 
                      : Colors.pinkAccent,
                ),
              ),
              selected: _selectedShadeCategory == category,
              selectedColor: Colors.pinkAccent,
              backgroundColor: Colors.pink[50],
              onSelected: (selected) {
                setState(() => _selectedShadeCategory = category);
              },
            ),
          );
        },
      ),
    );
  }

 Widget _buildShadeItem(Map<String, dynamic> shade, int rank) {
  return GestureDetector(
    onTap: () => _showShadeDetails(shade),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Fire icon with rank number
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: _getFireColor(rank),
                  size: 24,
                ),
                Text(
                  '$rank',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 10, 10, 10),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                shade['hex_code'],
                style: TextStyle(
                  fontSize: 10,
                  color: _getContrastColor(shade['hex_code']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shade['shade_name'] != null)
                  Text(
                    shade['shade_name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                LinearProgressIndicator(
                  value: (shade['match_count'] as int) / 1500,
                  backgroundColor: Colors.grey[200],
                  color: Colors.pinkAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${shade['match_count']}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Color _getFireColor(int rank) {
  switch (rank) {
    case 1: return Colors.red;
    case 2: return Colors.orange;
    case 3: return Colors.amber;
    default: return Colors.grey;
  }
}
  Widget _buildTopShadesList() {
    final shades = _shadesData[_selectedSkinTone]?[_selectedShadeCategory] ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var i = 0; i < shades.length; i++)
              _buildShadeItem(shades[i], i + 1),
            if (shades.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No shades available for this category',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularUsageGraph() {
    final shades = _shadesData[_selectedSkinTone]?[_selectedShadeCategory] ?? [];
    if (shades.isEmpty) return Container();

    shades.sort((a, b) => (b['match_count'] as int).compareTo(a['match_count'] as int));
    final totalUsed = shades.fold(0, (sum, shade) => sum + (shade['match_count'] as int));
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shade Usage Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: shades.asMap().entries.map((entry) {
                          final shade = entry.value;
                          return PieChartSectionData(
                            color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                            value: (shade['match_count'] as int) / totalUsed * 100,
                            title: '${((shade['match_count'] as int) / totalUsed * 100).toStringAsFixed(1)}%',
                            radius: 28,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getContrastColor(shade['hex_code']),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: shades.asMap().entries.map((entry) {
                          final shade = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shade['shade_name'] ?? shade['hex_code'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${shade['match_count']} uses',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAnalyticsButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () {
          _showDetailedAnalytics(context);
        },
        child: const Text(
          'View Detailed Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDetailedAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Shade Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'For ${_selectedSkinTone[0].toUpperCase() + _selectedSkinTone.substring(1)} skin tone',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCircularUsageGraph(),
                      const SizedBox(height: 16),
                      Text(
                        'Top Shades Across Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._categoryOrder.map((category) {
                        final shades = _shadesData[_selectedSkinTone]?[category] ?? [];
                        if (shades.isEmpty) return Container();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${category[0].toUpperCase()}${category.substring(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...shades.map((shade) {
                              return _buildDetailedShadeItem(shade);
                            }),
                            const Divider(),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedShadeItem(Map<String, dynamic> shade) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      title: Text(shade['shade_name'] ?? shade['hex_code']),
      subtitle: Text(shade['hex_code']),
      trailing: Text('${shade['match_count']} matches'),
      onTap: () {
        _showShadeDetails(shade);
      },
    );
  }

  void _showShadeDetails(Map<String, dynamic> shade) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    shade['hex_code'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getContrastColor(shade['hex_code']),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (shade['shade_name'] != null)
                Text(
                  shade['shade_name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Match Count: ${shade['match_count']}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Color _getContrastColor(String hexColor) {
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    final brightness = color.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}