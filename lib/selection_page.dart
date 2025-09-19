import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationScreen extends StatefulWidget {
  final String userId;
  final bool hasCompletedAnalysis;

  const RecommendationScreen({
    super.key,
    required this.userId,
    required this.hasCompletedAnalysis,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final MakeupRecommendationService _service = MakeupRecommendationService(
    apiBaseUrl: 'https://glamouraika.com/api',
  );

  FullRecommendationResponse? _recommendation;
  bool _isLoading = false;
  String _error = '';
  int currentPageIndex = 0;
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Only load recommendations if user has completed analysis
    if (widget.hasCompletedAnalysis) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _service.getFullRecommendation(
        userId: widget.userId,
        timeFilter: 'all',
      );

      setState(() {
        _recommendation = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  AppBar _buildAppBar(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      elevation: 0,
      title: Center(
        child: Image.asset(
          'assets/glam_logo.png',
          height: screenHeight * 0.10,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Image.asset(
              'assets/facscan_icon.gif',
              height: screenHeight * 0.05,
            ),
            onPressed: null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShimmerCard(),
        const SizedBox(height: 20),
        _buildShimmerCard(),
        const SizedBox(height: 20),
        _buildShimmerCard(),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 245, 87, 156).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6EF),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6EF),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6EF),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: List.generate(
                4,
                (index) => Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F8),
      appBar: _buildAppBar(context),
      body: !widget.hasCompletedAnalysis
          ? _buildAnalysisRequiredSection()
          : _isLoading
              ? _buildShimmerLoading()
              : _error.isNotEmpty
                  ? _buildErrorState()
                  : _recommendation == null
                      ? _buildEmptyState()
                      : _buildRecommendationContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 70, color: const Color(0xFFD4A5C0)),
            const SizedBox(height: 20),
            const Text('Oops! Something went wrong',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E4A71),
                    fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 12),
            Text(_error,
                style: const TextStyle(color: Color(0xFF9E8296)),
                textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E4A71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                elevation: 3,
                shadowColor: const Color(0xFFD4A5C0).withOpacity(0.5),
              ),
              child:
                  const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 70, color: const Color(0xFFD4A5C0)),
            const SizedBox(height: 20),
            const Text('No recommendations yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E4A71),
                    fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 12),
            const Text(
                'Your personalized beauty suggestions will appear here soon',
                style: TextStyle(color: Color.fromARGB(255, 170, 92, 148)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

 Widget _buildRecommendationContent() {
  // Check if user has valid analysis data (not "Unknown" or "None")
  final hasValidAnalysis = _recommendation!.userSkinTone != "Unknown" &&
      _recommendation!.userFaceShape != "Unknown" &&
      _recommendation!.userUndertone != "None" &&
      _recommendation!.userUndertone != "Unknown";

  // Check if user has any saved makeup data
  final hasSavedData = _recommendation!.mostUsedSavedLooks.isNotEmpty ||
      _recommendation!.topMakeupLooksByType.isNotEmpty ||
      _recommendation!.overallMostPopularLook != null;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8EFF4),
                Color.fromARGB(255, 248, 191, 219),
              ],
            ),
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A5BD).withOpacity(0.2),
                blurRadius: 20.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE2A6C0),
                          Color(0xFFC98DA9),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC98DA9).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 22.0),
                  ),
                  const SizedBox(width: 16.0),
                  const Text(
                    'Your Beauty Profile',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E4A71),
                      fontFamily: 'PlayfairDisplay',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              _buildProfileDetail('Skin Tone', _recommendation!.userSkinTone),
              const SizedBox(height: 16.0),
              _buildProfileDetail(
                  'Face Shape', _recommendation!.userFaceShape),
              const SizedBox(height: 16.0),
              _buildProfileDetail('Undertone', _recommendation!.userUndertone),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Only show recommendations if user has valid analysis AND saved data
        if (hasValidAnalysis && hasSavedData) ...[
          // Most Popular Look - only show if available
          if (_recommendation!.overallMostPopularLook != null) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16),
              child: Text('🌟 Most Popular Look',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E4A71),
                      fontFamily: 'PlayfairDisplay')),
            ),
            _buildFeaturedLookCard(_recommendation!.overallMostPopularLook!),
            const SizedBox(height: 30),
          ],
          
          // Top Looks by Type - only show if available
          if (_recommendation!.topMakeupLooksByType.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16),
              child: Text('Top Looks by Type',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E4A71),
                      fontFamily: 'PlayfairDisplay')),
            ),
            _buildTopLooksByTypeSection(),
            const SizedBox(height: 30),
          ],
          
          // Most Used Looks - only show if available
          if (_recommendation!.mostUsedSavedLooks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16),
              child: Text('Your Most Used Looks',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E4A71),
                      fontFamily: 'PlayfairDisplay')),
            ),
            ..._recommendation!.mostUsedSavedLooks.map(_buildLookCard),
            const SizedBox(height: 30),
          ],
          
          // Most Used Makeup Shades - only show if user has saved shades
          if (_hasSavedShades()) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16),
              child: Text('Most Used Makeup Shades',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E4A71),
                      fontFamily: 'PlayfairDisplay')),
            ),
            buildMostUsedShadesSection(),
          ],
        ] else if (hasValidAnalysis && !hasSavedData) ...[
          // User has completed analysis but hasn't saved any makeup data
          _buildNoSavedDataSection(),
        ] else ...[
          // Show message if user has analysis but it's incomplete or invalid
          _buildIncompleteAnalysisSection(),
        ],
      ],
    ),
  );
}

// Add this new method for when user has no saved data
Widget _buildNoSavedDataSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFE5B8D2).withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        const Icon(Icons.auto_awesome_outlined,
            size: 50, color: Color(0xFF7E4A71)),
        const SizedBox(height: 16),
        const Text('No Saved Makeup Looks Yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E4A71))),
        const SizedBox(height: 12),
        const Text(
            'Start saving your favorite makeup looks and shades to see personalized recommendations here',
            style: TextStyle(color: Color(0xFF9E8296)),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Navigate to makeup discovery screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => MakeupDiscoveryScreen()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7E4A71),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: const Text('Discover Makeup Looks'),
        ),
      ],
    ),
  );
}

  // Check if user has any saved shades
  bool _hasSavedShades() {
    bool hasShades = false;
    
    // Check top looks
    for (var look in _recommendation!.topMakeupLooksByType) {
      if (look.shadesByType.isNotEmpty) {
        hasShades = true;
        break;
      }
    }
    
    // Check most used looks
    if (!hasShades) {
      for (var look in _recommendation!.mostUsedSavedLooks) {
        if (look.shadesByType.isNotEmpty) {
          hasShades = true;
          break;
        }
      }
    }
    
    // Check most popular look
    if (!hasShades && _recommendation!.overallMostPopularLook != null) {
      if (_recommendation!.overallMostPopularLook!.shadesByType.isNotEmpty) {
        hasShades = true;
      }
    }
    
    return hasShades;
  }

   Widget buildNoSavedShadesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.palette_outlined,
              size: 50, color: Color(0xFF7E4A71)),
          const SizedBox(height: 16),
          const Text('No Saved Shades Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E4A71))),
          const SizedBox(height: 12),
          const Text(
              'Save your favorite makeup shades to see them here',
              style: TextStyle(color: Color(0xFF9E8296)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

 Widget buildMostUsedShadesSection() {
  Map<String, Map<MakeupShade, int>> shadeFrequencyByCategory = {};

  void countShadesFromLook(MakeupLook look) {
    look.shadesByType.forEach((category, shades) {
      if (!shadeFrequencyByCategory.containsKey(category)) {
        shadeFrequencyByCategory[category] = {};
      }
      
      for (var shade in shades) {
        // Find if this shade already exists in the category by comparing shadeId
        bool shadeExists = false;
        MakeupShade? existingShade;
        
        for (var existing in shadeFrequencyByCategory[category]!.keys) {
          if (existing.shadeId == shade.shadeId) {
            shadeExists = true;
            existingShade = existing;
            break;
          }
        }
        
        if (shadeExists && existingShade != null) {
          // Increment count for existing shade
          shadeFrequencyByCategory[category]![existingShade] = 
              (shadeFrequencyByCategory[category]![existingShade] ?? 0) + 1;
        } else {
          // Add new shade with count 1
          shadeFrequencyByCategory[category]![shade] = 1;
        }
      }
    });
  }

  // Count shades from all looks
  _recommendation!.topMakeupLooksByType.forEach(countShadesFromLook);
  _recommendation!.mostUsedSavedLooks.forEach(countShadesFromLook);
  if (_recommendation!.overallMostPopularLook != null) {
    countShadesFromLook(_recommendation!.overallMostPopularLook!);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: shadeFrequencyByCategory.entries.map((entry) {
      final category = entry.key;
      final shadeFrequency = entry.value;

      // Sort by frequency and get top shades
      final sortedShades = shadeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topShades = sortedShades
          .take(10) // Limit to 10 shades
          .map((entry) => entry.key)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E4A71),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topShades.map((shade) => _buildShadeChip(shade)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList(),
  );
}
  List<MakeupLook> _getTopLooksByType() {
    // Return only the user's saved looks, limited to 3
    return _recommendation!.topMakeupLooksByType.take(3).toList();
  }


  Widget _buildAnalysisRequiredSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face_retouching_natural,
                size: 70, color: const Color(0xFFD4A5C0)),
            const SizedBox(height: 20),
            const Text('Complete Your Beauty Analysis',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E4A71),
                    fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 12),
            const Text(
                'Analyze your face shape, skin tone, and undertone to unlock personalized recommendations',
                style: TextStyle(color: Color(0xFF9E8296)),
                textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                // Navigate to analysis screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E4A71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                elevation: 3,
                shadowColor: const Color(0xFFD4A5C0).withOpacity(0.5),
              ),
              child: const Text('Start Analysis', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompleteAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.face_retouching_natural,
              size: 50, color: Color(0xFF7E4A71)),
          const SizedBox(height: 16),
          const Text('Complete Your Beauty Analysis',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E4A71))),
          const SizedBox(height: 12),
          const Text(
              'Your analysis is incomplete. Please complete your face shape, skin tone, and undertone analysis to get personalized recommendations',
              style: TextStyle(color: Color(0xFF9E8296)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<MakeupLook> getTopLooksByType() {
    return _recommendation!.topMakeupLooksByType.take(3).toList();
  }

  Widget _buildTopLooksByTypeSection() {
    final topLooks = _getTopLooksByType();

    if (topLooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No top looks available',
            style: TextStyle(color: Color(0xFF9E8296))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: pageController,
            itemCount: topLooks.length,
            onPageChanged: (index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final look = topLooks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildTopLookByTypeCard(look),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            topLooks.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentPageIndex == index
                    ? const Color(0xFF7E4A71)
                    : const Color(0xFFD4A5C0).withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }


   Widget _buildFeaturedLookCard(MakeupLook look) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD1DC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star,
                                size: 18, color: Color(0xFF7E4A71)),
                          ),
                          const SizedBox(width: 10),
                          Text(look.lookName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7E4A71),
                                  fontFamily: 'PlayfairDisplay')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(look.makeupType,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF9E8296),
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.visibility, size: 16, color: Color(0xFF9E8296)),
                const SizedBox(width: 6),
                Text('${look.usageCount} uses',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9E8296))),
                const SizedBox(width: 20),
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF9E8296)),
                const SizedBox(width: 6),
                Text(look.timePeriod,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9E8296))),
              ],
            ),
            if (look.shadesByType.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...look.shadesByType.entries.map((entry) {
                final category = entry.key;
                final shades = entry.value.take(3).toList(); // Show only top 3 shades

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E4A71),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          shades.map((shade) => _buildShadeChip(shade)).toList(),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopLookByTypeCard(MakeupLook look) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  look.makeupType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E4A71),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(look.lookName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7E4A71))),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.visibility, size: 14, color: Color(0xFF9E8296)),
                  const SizedBox(width: 5),
                  Text('${look.usageCount} uses',
                      style:
                          const TextStyle(fontSize: 12, color: Color(0xFF9E8296))),
                  const SizedBox(width: 18),
                  const Icon(Icons.access_time,
                      size: 14, color: Color(0xFF9E8296)),
                  const SizedBox(width: 5),
                  Text(look.timePeriod,
                      style:
                          const TextStyle(fontSize: 12, color: Color(0xFF9E8296))),
                ],
              ),
              if (look.shadesByType.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Top 3 Shades',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E4A71))),
                const SizedBox(height: 10),
                ...look.shadesByType.entries.map((entry) {
                  final category = entry.key;
                  final shades = entry.value.take(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7E4A71),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            shades.map((shade) => _buildShadeChip(shade)).toList(),
                      ),
                    ],
                  );
                }),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE8CFDE).withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9B6A86),
              fontSize: 15.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF7E4A71),
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookCard(MakeupLook look) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(look.lookName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7E4A71))),
                          const SizedBox(height: 6),
                          Text(look.makeupType,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9E8296),
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8E6F0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_border,
                              size: 14, color: Color(0xFF7E4A71)),
                          const SizedBox(width: 5),
                          Text('${look.saveCount}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7E4A71))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 14, color: Color(0xFF9E8296)),
                    const SizedBox(width: 5),
                    Text('${look.usageCount} uses',
                        style:
                            const TextStyle(fontSize: 12, color: Color(0xFF9E8296))),
                    const SizedBox(width: 18),
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF9E8296)),
                    const SizedBox(width: 5),
                    Text(look.timePeriod,
                        style:
                            const TextStyle(fontSize: 12, color: Color(0xFF9E8296))),
                  ],
                ),
                if (look.shadesByType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('All Shades',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7E4A71))),
                  const SizedBox(height: 10),
                  ...look.shadesByType.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E4A71))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.value
                              .map((shade) => _buildShadeChip(shade))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _buildShadeChip(MakeupShade shade) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5B8D2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _parseHexColor(shade.hexCode),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        if (shade.shadeName.isNotEmpty) const SizedBox(width: 8),
        if (shade.shadeName.isNotEmpty)
          Text(
            shade.shadeName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7E4A71),
            ),
          ),
      ],
    ),
  );
}

  Color _parseHexColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', ''), radix: 16) +
          0xFF000000);
    } catch (e) {
      return const Color(0xFFE5D0DA);
    }
  }
}

class MakeupShade {
  final String shadeId;
  final String hexCode;
  final String shadeName;
  final String shadeType;

  MakeupShade({
    required this.shadeId,
    required this.hexCode,
    required this.shadeName,
    required this.shadeType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupShade &&
          runtimeType == other.runtimeType &&
          shadeId == other.shadeId;

  @override
  int get hashCode => shadeId.hashCode;

  factory MakeupShade.fromJson(Map<String, dynamic> json) {
    return MakeupShade(
      shadeId: json['shade_id'].toString(),
      hexCode: json['hex_code'] ?? '#000000',
      shadeName: json['shade_name'] ?? 'Unknown',
      shadeType: json['shade_type_name'] ?? json['shade_type'] ?? 'Unknown',
    );
  }
}

class MakeupLook {
  final String lookId;
  final String lookName;
  final String makeupType;
  final int usageCount;
  final int saveCount;
  final Map<String, List<MakeupShade>> shadesByType;
  final String source;
  final String timePeriod;

  MakeupLook({
    required this.lookId,
    required this.lookName,
    required this.makeupType,
    required this.usageCount,
    required this.saveCount,
    required this.shadesByType,
    required this.source,
    required this.timePeriod,
  });

  factory MakeupLook.fromJson(Map<String, dynamic> json) {
    Map<String, List<MakeupShade>> shadesMap = {};

    if (json['shades_by_type'] != null) {
      Map<String, dynamic> shadesData =
          Map<String, dynamic>.from(json['shades_by_type']);
      shadesData.forEach((key, value) {
        if (value is List) {
          shadesMap[key] =
              value.map((shade) => MakeupShade.fromJson(shade)).toList();
        }
      });
    }

    return MakeupLook(
      lookId: json['makeup_look_id'].toString(),
      lookName: json['makeup_look_name'] ?? 'Unknown Look',
      makeupType: json['makeup_type_name'] ?? 'Unknown Type',
      usageCount: json['usage_count'] ?? json['save_count'] ?? 0,
      saveCount: json['save_count'] ?? 0,
      shadesByType: shadesMap,
      source: json['source'] ?? 'unknown',
      timePeriod: json['time_period'] ?? 'all',
    );
  }
}

class FullRecommendationResponse {
  final String userId;
  final String userFaceShape;
  final String userSkinTone;
  final String userUndertone;
  final Map<String, dynamic> filtersUsed;
  final List<MakeupLook> topMakeupLooksByType;
  final List<MakeupLook> mostUsedSavedLooks;
  final MakeupLook? overallMostPopularLook;

  FullRecommendationResponse({
    required this.userId,
    required this.userFaceShape,
    required this.userSkinTone,
    required this.userUndertone,
    required this.filtersUsed,
    required this.topMakeupLooksByType,
    required this.mostUsedSavedLooks,
    this.overallMostPopularLook,
  });

  factory FullRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return FullRecommendationResponse(
      userId: json['user_id'].toString(),
      userFaceShape: json['user_face_shape'] ?? 'Unknown',
      userSkinTone: json['user_skin_tone'] ?? 'Unknown',
      userUndertone: json['user_undertone'] ?? 'Unknown',
      filtersUsed: Map<String, dynamic>.from(json['filters_used'] ?? {}),
      topMakeupLooksByType: (json['top_makeup_looks_by_type'] as List? ?? [])
          .map((look) => MakeupLook.fromJson(look))
          .toList(),
      mostUsedSavedLooks: (json['most_used_saved_looks'] as List? ?? [])
          .map((look) => MakeupLook.fromJson(look))
          .toList(),
      overallMostPopularLook: json['overall_most_popular_look'] != null
          ? MakeupLook.fromJson(json['overall_most_popular_look'])
          : null,
    );
  }
}

class MakeupRecommendationService {
  final String apiBaseUrl;

  MakeupRecommendationService({required this.apiBaseUrl});

  Future<FullRecommendationResponse> getFullRecommendation({
    required String userId,
    int? skinToneId,
    int? faceShapeId,
    int? undertoneId,
    String timeFilter = 'all',
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (skinToneId != null) {
        queryParams['skin_tone_id'] = skinToneId.toString();
      }
      if (faceShapeId != null) {
        queryParams['face_shape_id'] = faceShapeId.toString();
      }
      if (undertoneId != null) {
        queryParams['undertone_id'] = undertoneId.toString();
      }
      queryParams['time_filter'] = timeFilter;

      final uri = Uri.parse('$apiBaseUrl/$userId/full_recommendation')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FullRecommendationResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to load full recommendation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch full recommendation: $e');
    }
  }
  

  Future<Map<String, List<MakeupShade>>> getTopShadesByCategory(
      UserPreferences userPrefs) async {
    try {
      final response = await getFullRecommendation(
        userId: userPrefs.userId,
        skinToneId: userPrefs.skinToneId,
        faceShapeId: userPrefs.faceShapeId,
        undertoneId: userPrefs.undertoneId,
      );

      final Map<String, List<MakeupShade>> result = {};

      for (var look in response.topMakeupLooksByType) {
        final category = look.makeupType;
        final allShades = look.shadesByType.values.expand((x) => x).toList();

        if (allShades.isNotEmpty) {
          result[category] = allShades;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch top shades by category: $e');
    }
  }

  Future<List<MakeupLook>> getMostUsedLooks(UserPreferences userPrefs) async {
    try {
      final response = await getFullRecommendation(
        userId: userPrefs.userId,
        skinToneId: userPrefs.skinToneId,
        faceShapeId: userPrefs.faceShapeId,
        undertoneId: userPrefs.undertoneId,
      );

      return response.mostUsedSavedLooks;
    } catch (e) {
      throw Exception('Failed to fetch most used looks: $e');
    }
  }

  Future<List<MakeupLook>> getMostRecommendedLooks(
      UserPreferences userPrefs) async {
    try {
      final response = await getFullRecommendation(
        userId: userPrefs.userId,
        skinToneId: userPrefs.skinToneId,
        faceShapeId: userPrefs.faceShapeId,
        undertoneId: userPrefs.undertoneId,
      );

      final List<MakeupLook> recommendedLooks = [];

      if (response.overallMostPopularLook != null) {
        recommendedLooks.add(response.overallMostPopularLook!);
      }

      recommendedLooks.addAll(response.topMakeupLooksByType);

      return recommendedLooks;
    } catch (e) {
      throw Exception('Failed to fetch most recommended looks: $e');
    }
  }

  Future<Map<String, List<MakeupShade>>> getTop3ShadesByPreferences(
      UserPreferences userPrefs) async {
    try {
      final response = await getFullRecommendation(
        userId: userPrefs.userId,
        skinToneId: userPrefs.skinToneId,
        faceShapeId: userPrefs.faceShapeId,
        undertoneId: userPrefs.undertoneId,
      );

      final Map<String, List<MakeupShade>> result = {};
      for (var preferredLook in userPrefs.preferredLooks) {
        final matchingLooks = response.topMakeupLooksByType
            .where((look) => look.lookName
                .toLowerCase()
                .contains(preferredLook.toLowerCase()))
            .toList();
        final allShades = matchingLooks
            .expand((look) => look.shadesByType.values.expand((x) => x))
            .toList();
        final top3Shades = allShades.take(3).toList();

        if (top3Shades.isNotEmpty) {
          result[preferredLook] = top3Shades;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch top 3 shades: $e');
    }
  }
}

class UserPreferences {
  final String userId;
  final int? skinToneId;
  final int? faceShapeId;
  final int? undertoneId;
  final List<String> preferredLooks;
  final List<String> savedShades;

  UserPreferences({
    required this.userId,
    this.skinToneId,
    this.faceShapeId,
    this.undertoneId,
    required this.preferredLooks,
    required this.savedShades,
  });
}

class TopShadesWidget extends StatelessWidget {
  final Map<String, List<MakeupShade>> topShades;
  final UserPreferences userPreferences;

  const TopShadesWidget({
    super.key,
    required this.topShades,
    required this.userPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Recommendations for ${userPreferences.userId}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...topShades.entries.map((entry) {
          return _buildCategorySection(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<MakeupShade> shades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$category Makeup',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shades.length,
            itemBuilder: (context, index) {
              return _buildShadeCard(shades[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShadeCard(MakeupShade shade) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseHexColor(shade.hexCode),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shade.shadeName,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                shade.shadeType,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', ''), radix: 16) +
          0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}