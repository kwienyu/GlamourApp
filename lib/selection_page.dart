import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SelectionPage extends StatefulWidget {
  final String userId;
  const SelectionPage({super.key, required this.userId});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String _selectedSkinTone = 'morena'; // Default to morena
  String _selectedShadeCategory = 'foundation';

  // Define the skin tone options
  final List<String> _skinToneOptions = ['morena', 'chinita', 'mestiza'];

  // Define the category order
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

  // Updated shades data organized by skin tone
  final Map<String, Map<String, List<Map<String, dynamic>>>> _shadesData = {
    'morena': {
      'foundation': [
        {'hex_code': '#C68642', 'match_count': 876, 'shade_name': 'Warm Caramel'},
        {'hex_code': '#D3905D', 'match_count': 754, 'shade_name': 'Golden Tan'},
        {'hex_code': '#7B4A34', 'match_count': 689, 'shade_name': 'Deep Espresso'},
      ],
      'concealer': [
        {'hex_code': '#D3905D', 'match_count': 932, 'shade_name': 'Warm Sand'},
        {'hex_code': '#E8D1BD', 'match_count': 821, 'shade_name': 'Natural Beige'},
        {'hex_code': '#F2D4C1', 'match_count': 723, 'shade_name': 'Light Honey'},
      ],
      'contour': [
        {'hex_code': '#7B4A34', 'match_count': 652, 'shade_name': 'Cocoa'},
        {'hex_code': '#906642', 'match_count': 543, 'shade_name': 'Mocha'},
        {'hex_code': '#5E463B', 'match_count': 487, 'shade_name': 'Dark Walnut'},
      ],
    },
    'chinita': {
      'foundation': [
        {'hex_code': '#ECD4C4', 'match_count': 876, 'shade_name': 'Porcelain'},
        {'hex_code': '#F2D4C1', 'match_count': 754, 'shade_name': 'Ivory'},
        {'hex_code': '#E7C7B2', 'match_count': 689, 'shade_name': 'Natural Beige'},
      ],
      'concealer': [
        {'hex_code': '#F2D4C1', 'match_count': 932, 'shade_name': 'Light'},
        {'hex_code': '#E8D1BD', 'match_count': 821, 'shade_name': 'Medium'},
        {'hex_code': '#FAE7DB', 'match_count': 723, 'shade_name': 'Fair'},
      ],
      'contour': [
        {'hex_code': '#906642', 'match_count': 652, 'shade_name': 'Soft Tan'},
        {'hex_code': '#C0A697', 'match_count': 543, 'shade_name': 'Warm Taupe'},
        {'hex_code': '#A88D7C', 'match_count': 487, 'shade_name': 'Muted Brown'},
      ],
    },
    'mestiza': {
      'foundation': [
        {'hex_code': '#E7C7B2', 'match_count': 876, 'shade_name': 'Warm Beige'},
        {'hex_code': '#F2D4C1', 'match_count': 754, 'shade_name': 'Golden Ivory'},
        {'hex_code': '#D4A373', 'match_count': 689, 'shade_name': 'Caramel'},
      ],
      'concealer': [
        {'hex_code': '#F2D4C1', 'match_count': 932, 'shade_name': 'Light Beige'},
        {'hex_code': '#F5E0D0', 'match_count': 821, 'shade_name': 'Fair Warm'},
        {'hex_code': '#FAE7DB', 'match_count': 723, 'shade_name': 'Ivory'},
      ],
      'contour': [
        {'hex_code': '#C0A697', 'match_count': 652, 'shade_name': 'Taupe'},
        {'hex_code': '#8B6B4D', 'match_count': 543, 'shade_name': 'Warm Brown'},
        {'hex_code': '#6B4C3A', 'match_count': 487, 'shade_name': 'Cocoa'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shade Recommendations'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildShadeRecommendationsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildShadeRecommendationsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Shade Recommendations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSkinToneSelector(),
          const SizedBox(height: 16),
          _buildShadeCategoryTabs(),
          const SizedBox(height: 16),
          _buildTopShadesList(),
          const SizedBox(height: 20),
          _buildCircularUsageGraph(),
          const SizedBox(height: 16),
          _buildViewAnalyticsButton(context),
        ],
      ),
    );
  }

  Widget _buildSkinToneSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _skinToneOptions.length,
        itemBuilder: (context, index) {
          final skinTone = _skinToneOptions[index];
          final displayName = skinTone[0].toUpperCase() + skinTone.substring(1);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedSkinTone == skinTone 
                      ? Colors.white 
                      : Colors.pinkAccent,
                ),
              ),
              selected: _selectedSkinTone == skinTone,
              selectedColor: Colors.pinkAccent,
              backgroundColor: Colors.pink[50],
              onSelected: (selected) {
                setState(() => _selectedSkinTone = skinTone);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircularUsageGraph() {
    final shades = _shadesData[_selectedSkinTone]?[_selectedShadeCategory] ?? [];
    if (shades.isEmpty) return Container();

    // Calculate total match count for percentages
    final total = shades.fold(0, (sum, shade) => sum + (shade['match_count'] as int));
    
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
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: shades.asMap().entries.map((entry) {
                          final shade = entry.value;
                          final percentage = (shade['match_count'] as int) / total * 100;
                          return PieChartSectionData(
                            color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                            value: percentage,
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 20,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: shades.asMap().entries.map((entry) {
                        final shade = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  shade['shade_name'] ?? shade['hex_code'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                            }).toList(),
                            const Divider(),
                          ],
                        );
                      }).toList(),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Try-on feature coming soon!')),
                  );
                },
                child: const Text(
                  'Try This Shade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    String getRankLabel(int rank) {
      switch (rank) {
        case 1: return '🥇';
        case 2: return '🥈';
        case 3: return '🥉';
        default: return '$rank';
      }
    }

    return GestureDetector(
      onTap: () => _showShadeDetails(shade),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                getRankLabel(rank),
                style: TextStyle(
                  color: Colors.pink[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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

  Color _getContrastColor(String hexColor) {
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    final brightness = color.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
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
}