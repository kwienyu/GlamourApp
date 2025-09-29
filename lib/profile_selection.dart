import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'camera2.dart';
import 'glamvault.dart';
import 'faceshapes.dart';
import 'skintone.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'makeup_artistform.dart';
import 'package:intl/intl.dart';
import 'apicall_recommendation.dart';
import 'help_desk.dart';
import 'terms_and_conditions.dart'; 


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
    shadeName: json['shade_name'] ?? '', 
    shadeType: json['shade_type_name'] ?? json['shade_type'] ?? '', 
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
    String timeFilter = 'all',
  }) async {
    try {
      final Map<String, String> queryParams = {
        'time_filter': timeFilter,
      };

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
}

class ProfileSelection extends StatefulWidget {
  final String userId;
  const ProfileSelection({super.key, required this.userId});

  @override
  ProfileSelectionState createState() => ProfileSelectionState();
}

class ProfileSelectionState extends State<ProfileSelection> {
  int selectedIndex = 0;
  bool showBubble = true;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  
  // Profile data variables
  String? name;
  String? lastName;
  String? suffix;
  String? faceShape;
  String? skinTone;
  dynamic profilePic;
  String? email;
  String? username;
  String? gender;
  String? dob;
  int? age;
  File? _selectedProfileImage;

  // Recommendation variables
  final MakeupRecommendationService _recommendationService = MakeupRecommendationService(
    apiBaseUrl: 'https://glamouraika.com/api',
  );
  FullRecommendationResponse? _recommendation;
  bool _isLoadingRecommendations = false;
  String _recommendationError = '';

  // API Service instance
  final recommendationServiceOld = ApiCallRecommendation();

  @override
  void initState() {
    super.initState();
    _fetchProfileData().then((_) {
      if (_hasValidAnalysis()) {
        _loadRecommendations();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showBubble = false);
    });
  }

  bool _hasValidAnalysis() {
    return skinTone != null && 
           skinTone != "Unknown" && 
           skinTone != "Not Available" &&
           faceShape != null &&
           faceShape != "Unknown" &&
           faceShape != "Not Available";
  }

  Future<void> _loadRecommendations() async {
    if (!_hasValidAnalysis()) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = '';
    });

    try {
      final response = await _recommendationService.getFullRecommendation(
        userId: widget.userId,
        timeFilter: 'all',
      );

      setState(() {
        _recommendation = response;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _recommendationError = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.pinkAccent),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _getProfileImage(),
                        child: profilePic == null
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFullName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          if (username != null)
                            Text(
                              '@$username',
                              style: const TextStyle(
                                color: Colors.white,
                              fontSize: 12,
                              ),
                            ),
                          if (gender != null || age != null)
                            Text(
                              '${gender ?? ''} ${age != null ? '• $age years old' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Face Analysis',
              style: TextStyle(
                color: const Color.fromARGB(255, 9, 9, 9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Face Shape'),
            subtitle: Text(faceShape ?? 'Not analyzed yet'),
          ),
          ListTile(
            title: const Text('Skin Tone'),
            subtitle: Text(skinTone ?? 'Not analyzed yet'),
          ),
          const Divider(),
          
          ListTile(
            title: const Text('Settings'),
            onTap: () {},
          ),
          
          ListTile(
            title: const Text('Help Desk & Support'),
            leading: const Icon(Icons.help_outline),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpDeskScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms and Conditions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAndConditionsPage(),
                ),
              );
            },
          ),
        ], 
      ), 
    ); 
  }

  String _getFullName() {
    String fullName = name ?? '';
    if (lastName != null && lastName!.isNotEmpty) {
      fullName += ' $lastName';
    }
    if (suffix != null && suffix!.isNotEmpty) {
      fullName += ' $suffix';
    }
    return fullName.trim().isNotEmpty ? fullName.trim() : 'Loading...';
  }

  Future<void> loadCachedProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedImage = prefs.getString('profile_pic');

    if (cachedImage != null && cachedImage.isNotEmpty && cachedImage != "null") {
      try {
        String base64Str = cachedImage;
        if (base64Str.startsWith('data:image')) {
          base64Str = base64Str.split(',').last;
        }

        Uint8List imageBytes = base64Decode(base64Str);

        if (imageBytes.isNotEmpty) {
          setState(() {
            profilePic = imageBytes;
          });
        }
      } catch (e) {
        debugPrint("Error loading cached image: $e");
      }
    }
  }

  void _setErrorState() {
    setState(() {
      name = 'Guest User';
      lastName = '';
      suffix = '';
      faceShape = 'Unknown';
      skinTone = 'Unknown';
      profilePic = null;
      email = 'Not available';
      username = null;
      gender = 'Not specified';
      dob = 'Not specified';
      age = null;
    });
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString('user_id');

    if (userid == null || userid.isEmpty) {
      _setErrorState();
      return;
    }

    final uri = Uri.parse('https://glamouraika.com/api/user-profile?user_id=$userid');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String? base64Image = data['profile_pic'];
        Uint8List? imageBytes;

        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            if (base64Image.startsWith('data:image')) {
              base64Image = base64Image.split(',').last;
            }
            imageBytes = base64Decode(base64Image);
            await prefs.setString('user_profile_base64', base64Image);
          } catch (e) {
            debugPrint("Image decoding error: $e");
          }
        }

        setState(() {
          name = data['name'] ?? "";
          lastName = data['last_name'] ?? "";
          suffix = data['suffix'] ?? "";
          faceShape = data['face_shape'] ?? "Not Available";
          skinTone = data['skin_tone'] ?? "Not Available";
          profilePic = imageBytes;
          email = data['email'] ?? "Not available";
          username = data['username'];
          gender = data['gender'] ?? "Not specified";
          dob = data['dob'] ?? "Not specified";
          age = data['age'] ?? calculateAge(data['dob']);
          
          if (data['undertone'] != null) {
            prefs.setString('user_undertone', data['undertone']);
          }
        });
      } else {
        _setErrorState();
      }
    } catch (e) {
      debugPrint('HTTP error: $e');
      _setErrorState();
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedProfileImage = File(pickedFile.path);
      });
      await _updateProfilePicture();
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_selectedProfileImage == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? widget.userId;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://glamouraika.com/api/edit-profile'),
    );
    request.fields['user_id'] = userId;
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture',
        _selectedProfileImage!.path,
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
        await _fetchProfileData();
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture')),
      );
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedProfileImage != null) {
      return FileImage(_selectedProfileImage!);
    }
    if (profilePic == null) return null;
    
    if (profilePic is Uint8List) {
      return MemoryImage(profilePic as Uint8List);
    } else if (profilePic is String) {
      return NetworkImage(profilePic as String);
    }
    return null;
  }

  int? calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return null;
    
    try {
      final dobDate = DateFormat('yyyy-MM-dd').parse(dobString);
      final now = DateTime.now();
      int age = now.year - dobDate.year;
      if (now.month < dobDate.month || (now.month == dobDate.month && now.day < dobDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      debugPrint("Error calculating age: $e");
      return null;
    }
  }

 AppBar _buildAppBar(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      elevation: 0,
      title: Image.asset(
        'assets/glam_logo.png',
        height: screenHeight * 0.10,
        fit: BoxFit.contain,
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slide(begin: Offset(0, -0.5), end: Offset.zero, duration: 500.ms),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Image.asset(
            'assets/facscan_icon.gif',
            height: screenHeight * 0.05,
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .slide(begin: Offset(-0.5, 0), end: Offset.zero),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MakeupArtistForm(userId: int.parse(widget.userId)),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBody(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildCurvedBackground(screenHeight),
                _buildMainContent(context),
              ],
            ),
            _buildCategoriesSection(context),
            _buildRecommendationsSection(), 
          ],
        ),
      ),
    );
  }
  

  
  Widget _buildCurvedBackground(double screenHeight) {
    return Stack(
      children: [
        ClipPath(
          clipper: ElegantTopCurveClipper (),
          child: Container(
            height: screenHeight * 0.22,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),
        ClipPath(
          clipper: ElegantTopCurveClipper (),
          child: Container(
            height: screenHeight * 0.22,
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.22,
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.0, -0.4),
                  child: _buildWelcomeText(),
                ),
              ),
            ],
          ),
        ),
        _buildProfileCards(context),
        SizedBox(height: screenHeight * 0.04),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 100.ms, delay: 200.ms)
                .scaleXY(begin: 0.8, end: 1),
            SizedBox(width: 4),
            Text(
              '👋',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(
                  begin: -0.1,
                  end: 0.1,
                  duration: 500.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to glam-up!!',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
      ],
    );
  }

Widget _buildProfileCards(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  int? parsedUserId;

  try {
    parsedUserId = int.parse(widget.userId);
  } catch (e) {
    parsedUserId = 0; 
  }

  return SizedBox(
    height: screenWidth * 0.7,
    child: PageView(
      controller: _pageController,
      children: [
        _buildProfileCard(context, 'assets/camera.png', "Test My Look", CameraPage())
            .animate()
            .fadeIn(delay: 300.ms)
            .scaleXY(begin: 0.8, end: 1),
        _buildProfileCard(context, Icons.star, "Glammery", GlamVaultScreen(userId: parsedUserId)) 
            .animate()
            .fadeIn(delay: 400.ms)
            .scaleXY(begin: 0.8, end: 1),
      ],
    ),
  );
}
  

  Widget _buildProfileCard(BuildContext context, dynamic icon, String text, Widget route) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => route)),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.07),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.width * 0.05),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: size.width * 0.02,
              spreadRadius: size.width * 0.002,
            ),
          ],
          image: const DecorationImage(
            image: AssetImage('assets/card.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon is IconData)
                Icon(
                  icon,
                  color: Colors.white,
                  size: size.width * 0.20,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(duration: 2000.ms, hz: 2),
              if (icon is String)
                Image.asset(
                  icon,
                  width: size.width * 0.20,
                  height: size.width * 0.20,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(duration: 2000.ms, hz: 2),
              SizedBox(height: size.height * 0.02),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.06,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 16, 16, 16),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.05),
            child: const Text(
              'Categories',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 10, 10, 10),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .scaleXY(begin: 0.8, end: 1),
          ),
          SizedBox(height: screenWidth * 0.05),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: screenWidth * 0.08,
              runSpacing: screenWidth * 0.05,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.05),
                  child: _buildCategoryItem(context, 'assets/face shape 2.png', 'Face Shape', FaceShapesApp(userId: widget.userId)),
                ),
                _buildCategoryItem(context, 'assets/skin tone 2.png', 'Skin Tone', SkinTone(userId: widget.userId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeautyProfileBox() {
  return Container(
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
          color: const Color(0xFFD4A5BD).withValues(alpha: 0.2),
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
                    color: const Color(0xFFC98DA9).withValues(alpha: 0.4),
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
        _buildProfileDetail('Face Shape', faceShape ?? 'Not analyzed'),
        const SizedBox(height: 16.0),
        _buildProfileDetail('Skin Tone', skinTone ?? 'Not analyzed'),
        const SizedBox(height: 16.0),
        _buildProfileDetail('Undertone', _recommendation?.userUndertone ?? 'Not analyzed'),
        const SizedBox(height: 16.0),
      ],
    ),
  );
}

  Widget _buildProfileDetail(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE8CFDE).withValues(alpha: 0.5),
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

  Widget _buildRecommendationsSection() {
    if (!_hasValidAnalysis()) {
      return _buildAnalysisRequiredSection();
    }

    if (_isLoadingRecommendations) {
      return _buildShimmerLoading();
    }

    if (_recommendationError.isNotEmpty) {
      return _buildErrorState();
    }

    if (_recommendation == null) {
      return _buildEmptyState();
    }

    return _buildRecommendationContent();
  }


  Widget _buildAnalysisRequiredSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5B8D2).withValues(alpha: 0.2),
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
                'Analyze your face shape and skin tone to unlock personalized recommendations',
                style: TextStyle(color: Color(0xFF9E8296)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildShimmerCard(),
          const SizedBox(height: 20),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 245, 87, 156).withValues(alpha: 0.2),
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
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5B8D2).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 50, color: Color(0xFF7E4A71)),
            const SizedBox(height: 16),
            const Text('Oops! Something went wrong',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E4A71))),
            const SizedBox(height: 12),
            Text(_recommendationError,
                style: const TextStyle(color: Color(0xFF9E8296)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E4A71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5B8D2).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, size: 50, color: Color(0xFF7E4A71)),
            const SizedBox(height: 16),
            const Text('No recommendations yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E4A71))),
            const SizedBox(height: 12),
            const Text(
                'Your personalized beauty suggestions will appear here soon',
                style: TextStyle(color: Color(0xFF9E8296)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
 Widget _buildRecommendationContent() {
    final hasValidAnalysis = _recommendation!.userSkinTone != "Unknown" &&
        _recommendation!.userFaceShape != "Unknown";

    final hasSavedData = _recommendation!.mostUsedSavedLooks.isNotEmpty ||
        _recommendation!.topMakeupLooksByType.isNotEmpty ||
        _recommendation!.overallMostPopularLook != null;

    // Get all makeup types with looks
    final makeupTypes = _recommendation!.topMakeupLooksByType
        .where((look) => look.shadesByType.isNotEmpty)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7E4A71),
            ),
          ),
          const SizedBox(height: 16),

          // Your Beauty Profile Box
          _buildBeautyProfileBox(),
          const SizedBox(height: 24),

           // Most Popular Look
            if (_recommendation!.overallMostPopularLook != null) ...[
              const Text(
                '🌟 Most Popular Look',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E4A71),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeaturedLookCard(_recommendation!.overallMostPopularLook!),
              const SizedBox(height: 24),
            ],

          if (hasValidAnalysis && hasSavedData) ...[
            if (makeupTypes.isNotEmpty) ...[
              const Text(
                'Top Looks by Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E4A71),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 600,
                child: PageView.builder(
                  itemCount: makeupTypes.length,
                  itemBuilder: (context, index) {
                    final makeupLook = makeupTypes[index];
                    return _buildMakeupTypeCard(makeupLook);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Dot indicators for page view
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(makeupTypes.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 
                          ? const Color(0xFF7E4A71)
                          : const Color(0xFFD4A5BD).withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
            
            // Most Used Looks
            if (_recommendation!.mostUsedSavedLooks.isNotEmpty) ...[
              const Text(
                'Most Used Looks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E4A71),
                ), 
              ),
              const SizedBox(height: 12),
              ..._recommendation!.mostUsedSavedLooks
                  .take(3)
                  .map(_buildLookCard)
                  ,
              const SizedBox(height: 24),
            ],
            
            // Most Used Makeup Shades
            if (_hasSavedShades()) ...[
              const Text(
                'Most Used Makeup Shades',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E4A71),
                ),
              ),
              const SizedBox(height: 12),
              _buildMostUsedShadesSection(),
            ],
          ] else if (hasValidAnalysis && !hasSavedData) ...[
            _buildNoSavedDataSection(),
          ],
        ],
      ),
    );
  }

Widget _buildMakeupTypeCard(MakeupLook makeupLook) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFE5B8D2).withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(  
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Makeup Type Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD1DC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 20, color: Color(0xFF7E4A71)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  makeupLook.makeupType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E4A71),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            makeupLook.lookName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7E4A71),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.visibility, size: 16, color: Color(0xFF9E8296)),
              const SizedBox(width: 6),
              Text('${makeupLook.usageCount} uses',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9E8296))),
            ],
          ),
          const SizedBox(height: 24),
          
          // Display all shades from this specific makeup look - LIMIT TO 3 SHADES PER PRODUCT
          ...makeupLook.shadesByType.entries.map((entry) {
            final productType = entry.key;
            final shades = entry.value;
            
            // Take only top 3 shades for this product type
            final top3Shades = shades.take(3).toList();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  productType.toLowerCase(),
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
                  children: top3Shades
                      .map((shade) => _buildShadeChip(shade))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    ),
  ),
  );
}

List<Widget> buildAllProductShadesFromUserData() {
  final List<Widget> shadeSections = [];
  
  // Define all makeup product categories we want to show
  final productTypes = [
    'blush', 'concealer', 'contour', 'eyeshadow', 
    'foundation', 'highlighter', 'eyebrow'
  ];

  // Get top shades for each category from ALL user data
  for (final productType in productTypes) {
    final topShades = _getTopShadesForCategory(productType);
    
    if (topShades.isNotEmpty) {
      shadeSections.addAll([
        const SizedBox(height: 12),
        Text(
          productType.toUpperCase(),
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
          children: topShades
              .take(3) // Top 3 shades for this category
              .map((shade) => _buildShadeChip(shade))
              .toList(),
        ),
        const SizedBox(height: 16),
      ]);
    }
  }

  return shadeSections;
}
List<MakeupLook> getTopLooksByType() {
  // Group looks by makeupType
  final Map<String, MakeupLook> grouped = {};

  for (var look in _recommendation!.topMakeupLooksByType) {
    // Keep only the first look for each type
    if (!grouped.containsKey(look.makeupType)) {
      grouped[look.makeupType] = look;
    }
  }

  // Return in fixed order: Casual → Light → Heavy
  final order = ["Casual", "Light", "Heavy"];
  return order
      .map((type) => grouped[type])
      .where((look) => look != null)
      .cast<MakeupLook>()
      .toList();
}


List<MakeupShade> _getTopShadesForCategory(String category) {
  final Map<MakeupShade, int> shadeFrequency = {};
  
  // Count shades from all top looks
  for (var look in _recommendation!.topMakeupLooksByType) {
    final shades = look.shadesByType[category] ?? [];
    for (var shade in shades) {
      // Find if this shade already exists by comparing shadeId
      bool shadeExists = false;
      MakeupShade? existingShade;
      
      for (var existing in shadeFrequency.keys) {
        if (existing.shadeId == shade.shadeId) {
          shadeExists = true;
          existingShade = existing;
          break;
        }
      }
      
      if (shadeExists && existingShade != null) {
        shadeFrequency[existingShade] = (shadeFrequency[existingShade] ?? 0) + 1;
      } else {
        shadeFrequency[shade] = 1;
      }
    }
  }
  
  // Count shades from most used saved looks
  for (var look in _recommendation!.mostUsedSavedLooks) {
    final shades = look.shadesByType[category] ?? [];
    for (var shade in shades) {
      bool shadeExists = false;
      MakeupShade? existingShade;
      
      for (var existing in shadeFrequency.keys) {
        if (existing.shadeId == shade.shadeId) {
          shadeExists = true;
          existingShade = existing;
          break;
        }
      }
      
      if (shadeExists && existingShade != null) {
        shadeFrequency[existingShade] = (shadeFrequency[existingShade] ?? 0) + 1;
      } else {
        shadeFrequency[shade] = 1;
      }
    }
  }
  
  // Count shades from overall most popular look
  if (_recommendation!.overallMostPopularLook != null) {
    final shades = _recommendation!.overallMostPopularLook!.shadesByType[category] ?? [];
    for (var shade in shades) {
      bool shadeExists = false;
      MakeupShade? existingShade;
      
      for (var existing in shadeFrequency.keys) {
        if (existing.shadeId == shade.shadeId) {
          shadeExists = true;
          existingShade = existing;
          break;
        }
      }
      
      if (shadeExists && existingShade != null) {
        shadeFrequency[existingShade] = (shadeFrequency[existingShade] ?? 0) + 1;
      } else {
        shadeFrequency[shade] = 1;
      }
    }
  }
  
  // Sort by frequency and return the shades
  final sortedEntries = shadeFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return sortedEntries.map((entry) => entry.key).toList();
}

// KEEP ALL THE ORIGINAL FUNCTIONS FROM YOUR CODE:

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

Widget _buildMostUsedShadesSection() {
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

      // Sort by frequency and get top 10 shades for this category
      final sortedShades = shadeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // LIMIT TO TOP 10 SHADES ONLY
      final top10Shades = sortedShades
          .take(10) 
          .map((entry) => entry.key)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              category.toLowerCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E4A71),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: top10Shades.map((shade) => _buildShadeChip(shade)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList(),
  );
}
  bool hasSavedShades() {
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

  Widget _buildNoSavedDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withValues(alpha: 0.2),
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
        ],
      ),
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
            color: const Color(0xFFE5B8D2).withValues(alpha: 0.3),
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
                                  color: Color(0xFF7E4A71))),
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
              ],
            ),
            if (look.shadesByType.isNotEmpty) ...[
              const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLookCard(MakeupLook look) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B8D2).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(look.lookName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E4A71))),
            const SizedBox(height: 8),
            Text(look.makeupType,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E8296))),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.visibility, size: 12, color: Color(0xFF9E8296)),
                const SizedBox(width: 4),
                Text('${look.usageCount} uses',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9E8296))),
              ],
            ),
            if (look.shadesByType.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...look.shadesByType.entries.map((entry) {
                final category = entry.key;
                final shades = entry.value.take(3).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E4A71),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          shades.map((shade) => _buildShadeChip(shade)).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          ],
        ),
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

        // Sort by frequency and get top 10 shades
        final sortedShades = shadeFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // LIMIT TO TOP 10 SHADES ONLY
        final top10Shades = sortedShades
            .take(10) 
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E4A71),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: top10Shades.map((shade) => _buildShadeChip(shade)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

Widget _buildShadeChip(MakeupShade shade) {
  return GestureDetector(
    onTap: () => _showShadeVisualization(shade),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _parseHexColor(shade.hexCode),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            shade.shadeName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7E4A71),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showShadeVisualization(MakeupShade shade) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content container - centered properly
            Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Larger color visualization - properly centered
                  Container(
                    width: 200, 
                    height: 200, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 180, 
                        height: 180, 
                        decoration: BoxDecoration(
                          color: _parseHexColor(shade.hexCode),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25), 
                  
                  // Shade name with elegant typography - properly centered
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      shade.shadeName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E4A71),
                        letterSpacing: 1.0,
                        fontFamily: 'PlayfairDisplay',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 8), 
                  
                  // Shade type with subtle styling - properly centered
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      shade.shadeType,
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // X button positioned properly
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7E4A71).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7E4A71),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildCategoryItem(BuildContext context, String imagePath, String label, Widget route) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => route)),
      child: Column(
        children: [
          Container(
            width: size.width * 0.25,
            height: size.width * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontFamily: 'Serif',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFFE5D0DA);
    }
  }

  Widget buildAttributeChip(String text) {
    return Chip(
      backgroundColor: Colors.pink[50],
      label: Text(
        text,
        style: TextStyle(
          color: Colors.pink[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color getContrastColor(String hexColor) {
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    final brightness = color.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}

class ElegantTopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    
    // First curve - more elegant and smooth
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.5,
      size.height - 40,
    );
    
    // Second curve - more elegant and smooth
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 70,
      size.width,
      size.height - 20,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}