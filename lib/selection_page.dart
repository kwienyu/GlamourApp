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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Recommended Shades'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _buildBodyContent(screenWidth, screenHeight),
    );
  }

  Widget _buildBodyContent(double screenWidth, double screenHeight) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.pinkAccent,
              size: screenWidth * 0.12,
            ),
            SizedBox(height: screenHeight * 0.02),
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
            Icon(Icons.error_outline, size: screenWidth * 0.12, color: Colors.red),
            SizedBox(height: screenHeight * 0.02),
            const Text('Failed to load data'),
            SizedBox(height: screenHeight * 0.02),
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
          _buildShadeRecommendationsSection(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildShadeRecommendationsSection(BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Top Shades',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.pink[800],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          _buildSkinToneSelector(screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.03),
          _buildShadeCategoryTabs(screenWidth),
          SizedBox(height: screenHeight * 0.03),
          _buildTopShadesList(screenWidth),
          SizedBox(height: screenHeight * 0.03),
          _buildCircularUsageGraph(screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.03),
          _buildViewAnalyticsButton(context, screenWidth),
        ],
      ),
    );
  }

  Widget _buildSkinToneSelector(double screenWidth, double screenHeight) {
    final itemWidth = screenWidth * 0.28;
    final itemHeight = screenHeight * 0.16;
    final imageHeight = screenHeight * 0.12;

    return SizedBox(
      height: itemHeight,
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
              width: itemWidth,
              margin: EdgeInsets.only(right: screenWidth * 0.04),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(
                  color: _selectedSkinTone == skinTone 
                      ? Colors.pinkAccent 
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.03)),
                    child: Container(
                      height: imageHeight,
                      width: double.infinity,
                      color: _getSkinToneColor(skinTone),
                      child: _skinToneImages.containsKey(skinTone)
                          ? Image.asset(
                              _skinToneImages[skinTone]!,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                            )
                          : Center(
                              child: Text(
                                displayName[0],
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      decoration: BoxDecoration(
                        color: _selectedSkinTone == skinTone
                            ? Colors.pinkAccent.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.03)),
                      ),
                      child: Center(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                            color: _selectedSkinTone == skinTone
                                ? Colors.pinkAccent
                                : Colors.grey[700],
                          ),
                        ),
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

  Color _getSkinToneColor(String skinTone) {
    switch (skinTone) {
      case 'morena': return const Color(0xFF8D5524);
      case 'chinita': return const Color(0xFFFFDBAC);
      case 'mestiza': return const Color(0xFFE0AC69);
      default: return Colors.grey;
    }
  }

  Widget _buildShadeCategoryTabs(double screenWidth) {
    return SizedBox(
      height: screenWidth * 0.1,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryOrder.length,
        itemBuilder: (context, index) {
          final category = _categoryOrder[index];
          final displayName = category[0].toUpperCase() + category.substring(1);
          
          return Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.02),
            child: ChoiceChip(
              label: Text(
                displayName,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
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

  Widget _buildShadeItem(Map<String, dynamic> shade, int rank, double screenWidth) {
    return GestureDetector(
      onTap: () => _showShadeDetails(shade),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
        child: Container(
          height: screenWidth * 0.15,
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: _getFireColor(rank),
                      size: screenWidth * 0.06,
                    ),
                    Text(
                      '$rank',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 10, 10, 10),
                        fontSize: screenWidth * 0.025,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    shade['hex_code'],
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: _getContrastColor(shade['hex_code']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (shade['shade_name'] != null)
                      Text(
                        shade['shade_name'],
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: screenWidth * 0.01),
                    LinearProgressIndicator(
                      value: (shade['match_count'] as int) / 1500,
                      backgroundColor: Colors.grey[200],
                      color: Colors.pinkAccent,
                      minHeight: screenWidth * 0.02,
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                '${shade['match_count']}',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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

  Widget _buildTopShadesList(double screenWidth) {
    final shades = _shadesData[_selectedSkinTone]?[_selectedShadeCategory] ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          children: [
            for (var i = 0; i < shades.length; i++)
              _buildShadeItem(shades[i], i + 1, screenWidth),
            if (shades.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
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

  Widget _buildCircularUsageGraph(double screenWidth, double screenHeight) {
    final shades = _shadesData[_selectedSkinTone]?[_selectedShadeCategory] ?? [];
    if (shades.isEmpty) return Container();

    shades.sort((a, b) => (b['match_count'] as int).compareTo(a['match_count'] as int));
    final totalUsed = shades.fold(0, (sum, shade) => sum + (shade['match_count'] as int));
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shade Usage Distribution',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            SizedBox(
              height: screenHeight * 0.25,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: screenWidth * 0.15,
                        sections: shades.asMap().entries.map((entry) {
                          final shade = entry.value;
                          return PieChartSectionData(
                            color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                            value: (shade['match_count'] as int) / totalUsed * 100,
                            title: '${((shade['match_count'] as int) / totalUsed * 100).toStringAsFixed(1)}%',
                            radius: screenWidth * 0.07,
                            titleStyle: TextStyle(
                              fontSize: screenWidth * 0.03,
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
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: shades.asMap().entries.map((entry) {
                          final shade = entry.value;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: screenWidth * 0.03,
                                  height: screenWidth * 0.03,
                                  margin: EdgeInsets.only(top: screenHeight * 0.002),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shade['shade_name'] ?? shade['hex_code'],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${shade['match_count']} uses',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.028,
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

  Widget _buildViewAnalyticsButton(BuildContext context, double screenWidth) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenWidth * 0.03,
          ),
        ),
        onPressed: () {
          _showDetailedAnalytics(context);
        },
        child: Text(
          'View Detailed Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  void _showDetailedAnalytics(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Shade Analytics',
                style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'For ${_selectedSkinTone[0].toUpperCase() + _selectedSkinTone.substring(1)} skin tone',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCircularUsageGraph(screenWidth, MediaQuery.of(context).size.height),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Top Shades Across Categories',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[800],
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
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
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            ...shades.map((shade) {
                              return _buildDetailedShadeItem(shade, screenWidth);
                            }),
                            Divider(height: screenWidth * 0.04),
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

  Widget _buildDetailedShadeItem(Map<String, dynamic> shade, double screenWidth) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: screenWidth * 0.1,
        height: screenWidth * 0.1,
        decoration: BoxDecoration(
          color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      title: Text(
        shade['shade_name'] ?? shade['hex_code'],
        style: TextStyle(fontSize: screenWidth * 0.04),
      ),
      subtitle: Text(
        shade['hex_code'],
        style: TextStyle(fontSize: screenWidth * 0.035),
      ),
      trailing: Text(
        '${shade['match_count']} matches',
        style: TextStyle(fontSize: screenWidth * 0.035),
      ),
      onTap: () {
        _showShadeDetails(shade);
      },
    );
  }

  void _showShadeDetails(Map<String, dynamic> shade) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: screenWidth * 0.25,
                decoration: BoxDecoration(
                  color: Color(int.parse(shade['hex_code'].replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Center(
                  child: Text(
                    shade['hex_code'],
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: _getContrastColor(shade['hex_code']),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              if (shade['shade_name'] != null)
                Text(
                  shade['shade_name'],
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Match Count: ${shade['match_count']}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
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