import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class SelectionPage extends StatefulWidget {
  final String userId;
  const SelectionPage({super.key, required this.userId});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String _selectedShadeCategory = 'foundation';

  // Define the category order explicitly
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

  final Map<String, List<Map<String, dynamic>>> _shadesData = {
    'foundation': [
      {'hex_code': '#D4A373', 'match_count': 876},
      {'hex_code': '#F3D7C4', 'match_count': 754},
      {'hex_code': '#8B5A3C', 'match_count': 689},
    ],
    'concealer': [
      {'hex_code': '#F5E0D0', 'match_count': 932},
      {'hex_code': '#F7C7A2', 'match_count': 821},
      {'hex_code': '#E0B896', 'match_count': 723},
    ],
    'contour': [
      {'hex_code': '#8B6B4D', 'match_count': 652},
      {'hex_code': '#6B4C3A', 'match_count': 543},
      {'hex_code': '#A78B71', 'match_count': 487},
    ],
    'eyeshadow': [
      {'hex_code': '#6A5ACD', 'match_count': 720},
      {'hex_code': '#9370DB', 'match_count': 680},
      {'hex_code': '#483D8B', 'match_count': 590},
    ],
    'blush': [
      {'hex_code': '#FF9F9F', 'match_count': 987},
      {'hex_code': '#F5B2C1', 'match_count': 876},
      {'hex_code': '#D46A6A', 'match_count': 765},
    ],
    'lipstick': [
      {'hex_code': '#FF004F', 'match_count': 1203},
      {'hex_code': '#F5C3C2', 'match_count': 980},
      {'hex_code': '#C93756', 'match_count': 876},
    ],
    'eyebrow': [
      {'hex_code': '#B7A99B', 'match_count': 723},
      {'hex_code': '#6B4E3D', 'match_count': 615},
      {'hex_code': '#3A2D24', 'match_count': 587},
    ],
    'highlighter': [
      {'hex_code': '#F3E0C0', 'match_count': 765},
      {'hex_code': '#F5F0E1', 'match_count': 654},
      {'hex_code': '#FFE6B5', 'match_count': 543},
    ],
  };

  final Map<String, List<double>> _categoryTrends = {
    'Week 1': [22, 15, 18, 20, 28, 35, 12, 10],
    'Week 2': [25, 18, 20, 22, 25, 40, 14, 12],
    'Week 3': [30, 20, 22, 25, 30, 45, 16, 15],
    'Week 4': [28, 22, 25, 23, 32, 38, 18, 18],
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
          _buildShadeCategoryTabs(),
          const SizedBox(height: 16),
          _buildTopShadesList(),
          const SizedBox(height: 20),
          _buildTrendGraph(),
          const SizedBox(height: 16),
          _buildViewAnalyticsButton(context),
        ],
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTrendGraph(),
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
                      ..._shadesData.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...entry.value.map((shade) {
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
      title: Text(shade['hex_code']),
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
            Text(
              'Match Count: ${shade['match_count']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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

 Widget _buildTrendGraph() {
    final List<Color> distinctColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.brown.shade400,
    ];

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
              'Weekly Shade Popularity Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = _categoryOrder[rodIndex];
                        return BarTooltipItem(
                          '$category\n${rod.toY.toInt()}%',
                          TextStyle(
                            color: distinctColors[rodIndex],
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _categoryTrends.keys.elementAt(value.toInt()),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                        interval: 20,
                        reservedSize: 28,
                      ),
                    ),
                    rightTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _categoryTrends.entries.map((week) {
                    final weekIndex = _categoryTrends.keys.toList().indexOf(week.key);
                    return BarChartGroupData(
                      x: weekIndex,
                      barsSpace: 4,
                      barRods: week.value.asMap().entries.map((category) {
                        return BarChartRodData(
                          toY: category.value,
                          color: distinctColors[category.key],
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 50,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Centered legend with all categories
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _categoryOrder.asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: distinctColors[entry.key].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: distinctColors[entry.key],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.value[0].toUpperCase() + entry.value.substring(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink[100],
              ),
              child: Text(
                '$rank',
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
              child: LinearProgressIndicator(
                value: shade['match_count'] / 1500,
                backgroundColor: Colors.grey[200],
                color: Colors.pinkAccent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
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
    final shades = _shadesData[_selectedShadeCategory] ?? [];

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