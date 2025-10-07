import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'camera2.dart';
import 'glamvault.dart';
import 'faceshapes.dart';
import 'skintone.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'apicall_recommendation.dart';
import 'help_desk.dart';
import 'terms_and_conditions.dart'; 
import 'makeuphub.dart';
import 'login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


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
  final String? userId; // Make userId optional
  
  const ProfileSelection({super.key, this.userId});

  @override
  ProfileSelectionState createState() => ProfileSelectionState();
}

class ProfileSelectionState extends State<ProfileSelection> {
  int selectedIndex = 0;
  bool showBubble = true;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  
  String? name;
  String? lastName;
  String? suffix;
  String? faceShape;
  String? skinTone;
  String? profilePic;
  String? email;
  String? username;
  String? gender;
  String? dob;
  int? age;
  File? _selectedProfileImage;

  final MakeupRecommendationService _recommendationService = MakeupRecommendationService(
    apiBaseUrl: 'https://glamouraika.com/api',
  );
  FullRecommendationResponse? _recommendation;
  bool _isLoadingRecommendations = false;
  String _recommendationError = '';

  final recommendationServiceOld = ApiCallRecommendation();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Future<SharedPreferences> _sharedPrefs;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _sharedPrefs = SharedPreferences.getInstance();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      // Check if we have a valid user ID
      String? effectiveUserId = widget.userId;
      
      // If no userId provided, check shared preferences
      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        final prefs = await _sharedPrefs;
        effectiveUserId = prefs.getString('user_id');
      }

      // If still no user ID, redirect to login
      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Verify token is still valid
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Set loading complete and fetch profile data
      setState(() {
        _isCheckingAuth = false;
      });

      await _fetchProfileData(effectiveUserId);
      
      if (_hasValidAnalysis()) {
        _loadRecommendations(effectiveUserId);
      }
      
    } catch (e) {
      print('Error initializing user data: $e');
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
        // Redirect to login on error
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }

    // Hide welcome bubble after delay
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

  Future<void> _loadRecommendations(String userId) async {
    if (!_hasValidAnalysis()) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = '';
    });

    try {
      final response = await _recommendationService.getFullRecommendation(
        userId: userId,
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
  // Show loading screen while checking authentication
  if (_isCheckingAuth) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/glam_logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.pinkAccent,
              size: 50,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
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
                      child: profilePic == null && _selectedProfileImage == null
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
              Expanded(
                child: Column(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (username != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (gender != null || age != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${gender ?? ''} ${age != null ? '• $age years old' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
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
          subtitle: Text(
            faceShape ?? 'Not analyzed yet',
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ListTile(
          title: const Text('Skin Tone'),
          subtitle: Text(
            skinTone ?? 'Not analyzed yet',
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
          ),
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
        
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Log Out', style: TextStyle(color: Colors.red)),
          onTap: _showLogoutConfirmation,
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
      setState(() {
        profilePic = _getFullImageUrl(cachedImage);
      });
    }
  }

  String _getFullImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return 'https://glamouraika.com$path';
    }
    return 'https://glamouraika.com/static/$path';
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

  Future<void> _fetchProfileData(String userId) async {
    final prefs = await _sharedPrefs;
    final userid = prefs.getString('user_id') ?? userId;

    if (userid.isEmpty) {
      _setErrorState();
      return;
    }

    final uri = Uri.parse('https://glamouraika.com/api/user-profile?user_id=$userid');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String? profilePicPath = data['profile_pic'];
        
        if (profilePicPath != null && profilePicPath.isNotEmpty && profilePicPath != "null") {
          profilePicPath = _getFullImageUrl(profilePicPath);
        }

        setState(() {
          name = data['name'] ?? "";
          lastName = data['last_name'] ?? "";
          suffix = data['suffix'] ?? "";
          faceShape = data['face_shape'] ?? "Not Available";
          skinTone = data['skin_tone'] ?? "Not Available";
          profilePic = profilePicPath;
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

    final prefs = await _sharedPrefs;
    final userId = prefs.getString('user_id') ?? widget.userId ?? '';

    if (userId.isEmpty) return;

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
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
        
        if (responseData['profile'] != null && responseData['profile']['profile_pic'] != null) {
          final newProfilePic = responseData['profile']['profile_pic'];
          setState(() {
            profilePic = _getFullImageUrl(newProfilePic);
          });
        }
        
        await _fetchProfileData(userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')),
        );
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
    
    return NetworkImage(profilePic!);
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

  Future<void> _logout() async {
    try {
      await LoginScreenState.logout();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      _showErrorSnackBar('Logout failed. Please try again.');
    }
  }

void _showLogoutConfirmation() {
  showDialog(
    context: context,
    barrierColor: const Color(0xB3000000),
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4F7),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D9C4D6F),
                    blurRadius: 35,
                    spreadRadius: 3,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple icon without animations
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x66E91E63),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    Text(
                      'Ready to Leave?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7E4A71),
                        fontFamily: 'PlayfairDisplay',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      'Are you sure you want to log out?\nYou\'ll need to sign in again to access your beauty profile and recommendations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E8296),
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: const Color(0xFF7E4A71),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
    ),
    centerTitle: true,
    actions: [
      IconButton(
        icon: Image.asset(
          'assets/facscan_icon.gif',
          height: screenHeight * 0.05,
        ),
        onPressed: null,
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
        clipper: ElegantTopCurveClipper(),
        child: Container(
          height: screenHeight * 0.22,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0x80FF4081),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      ClipPath(
        clipper: ElegantTopCurveClipper(),
        child: Container(
          height: screenHeight * 0.22,
          decoration: const BoxDecoration(
            color: Colors.pinkAccent,
          ),
        ),
      ),
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
                alignment: const Alignment(0.0, -0.4),
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
          ),
          const SizedBox(width: 4),
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
      ),
    ],
  );
}

Widget _buildProfileCards(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  String effectiveUserId = '';
  if (widget.userId != null && widget.userId!.isNotEmpty) {
    effectiveUserId = widget.userId!;
  } else {
    effectiveUserId = '0';
  }

  int? parsedUserId;
  try {
    parsedUserId = int.parse(effectiveUserId);
  } catch (e) {
    parsedUserId = 0; 
  }

  return SizedBox(
    height: screenWidth * 0.7,
    child: PageView(
      controller: _pageController,
      children: [
        _buildProfileCard(context, 'assets/camera.png', "Test My Look", const CameraPage()),
        _buildProfileCard(context, Icons.auto_awesome, "Recommendation For You", MakeupHubPage(
              skinTone: skinTone,
              userId: effectiveUserId,
            )), 
        _buildProfileCard(context, Icons.star, "Glammery", GlamVaultScreen(userId: parsedUserId)), 
      ],
    ),
  );
}

Widget _buildProfileCard(BuildContext context, dynamic icon, String text, Widget route) {
  final size = MediaQuery.of(context).size;

  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => route));
    },
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
              ),
            if (icon is String)
              Image.asset(
                icon,
                width: size.width * 0.20,
                height: size.width * 0.20,
              ),
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
            ),
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
          ),
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
                child: _buildCategoryItem(context, 'assets/face shape 2.png', 'Face Shape', FaceShapesApp(userId: widget.userId ?? '')),
              ),
              _buildCategoryItem(context, 'assets/skin tone 2.png', 'Skin Tone', SkinTone(userId: widget.userId ?? '')),
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
          color: Color.fromRGBO(212, 165, 189, 0.2),
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
                    color: Color.fromRGBO(201, 141, 169, 0.4),
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
        color: Color.fromRGBO(255, 255, 255, 0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Color.fromRGBO(232, 207, 222, 0.5),
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
              color: Color.fromRGBO(229, 184, 210, 0.2),
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
            color: Color.fromRGBO(245, 87, 156, 0.2),
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
              color: Color.fromRGBO(229, 184, 210, 0.2),
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
              onPressed: () => _loadRecommendations(widget.userId ?? ''),
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
              color: Color.fromRGBO(229, 184, 210, 0.2),
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
        _buildBeautyProfileBox(),
        const SizedBox(height: 24),
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
          if (_recommendation!.topMakeupLooksByType.isNotEmpty) ...[
            const Text(
              'Top Looks by Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7E4A71),
              ),
            ),
            const SizedBox(height: 12),
            _buildTopLooksByTypeSection(),
            const SizedBox(height: 24),
          ],
        
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
                .map((look) => _buildLookCard(look)),
            const SizedBox(height: 24),
          ],
          
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

Widget _buildTopLooksByTypeSection() {
  final Map<String, MakeupLook> topLooksByType = {};
  
  for (var look in _recommendation!.topMakeupLooksByType) {
    final currentType = look.makeupType;
    if (!topLooksByType.containsKey(currentType) || 
        look.usageCount > topLooksByType[currentType]!.usageCount) {
      topLooksByType[currentType] = look;
    }
  }
  
  final topLooks = topLooksByType.values.toList()
    ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  
  if (topLooks.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'No top looks available by type',
        style: TextStyle(
          color: Color(0xFF9E8296),
          fontSize: 14,
        ),
      ),
    );
  }
  
  return Column(
    children: [
      SizedBox(
        height: 500,
        child: PageView.builder(
          itemCount: topLooks.length,
          itemBuilder: (context, index) {
            final makeupLook = topLooks[index];
            return _buildMakeupTypeCard(makeupLook);
          },
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(topLooks.length, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0 
                  ? const Color(0xFF7E4A71)
                  : Color.fromRGBO(212, 165, 189, 0.5),
            ),
          );
        }),
      ),
    ],
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
          color: Color.fromRGBO(229, 184, 210, 0.3),
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
              '${makeupLook.lookName} Look', 
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7E4A71),
              ),
            ),
            const SizedBox(height: 24),
            if (makeupLook.shadesByType.isNotEmpty) ...[
              ...makeupLook.shadesByType.entries.map((entry) {
                final productType = entry.key;
                final shades = entry.value;
                
                final top3Shades = shades.take(3).toList();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _capitalizeFirstLetter(productType),
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
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No shade data available for this look',
                  style: TextStyle(
                    color: Color(0xFF9E8296),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

List<MakeupLook> getTopLooksByType() {
  final Map<String, MakeupLook> grouped = {};

  for (var look in _recommendation!.topMakeupLooksByType) {
    if (!grouped.containsKey(look.makeupType)) {
      grouped[look.makeupType] = look;
    }
  }

  final order = ["Casual", "Light", "Heavy"];
  return order
      .map((type) => grouped[type])
      .where((look) => look != null)
      .cast<MakeupLook>()
      .toList();
}

List<MakeupShade> getTopShadesForCategory(String category) {
  final Map<MakeupShade, int> shadeFrequency = {};
  
  for (var look in _recommendation!.topMakeupLooksByType) {
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
  
  final sortedEntries = shadeFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return sortedEntries.map((entry) => entry.key).toList();
}

bool _hasSavedShades() {
  bool hasShades = false;

  for (var look in _recommendation!.topMakeupLooksByType) {
    if (look.shadesByType.isNotEmpty) {
      hasShades = true;
      break;
    }
  }

  if (!hasShades) {
    for (var look in _recommendation!.mostUsedSavedLooks) {
      if (look.shadesByType.isNotEmpty) {
        hasShades = true;
        break;
      }
    }
  }

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
          shadeFrequencyByCategory[category]![existingShade] = 
              (shadeFrequencyByCategory[category]![existingShade] ?? 0) + 1;
        } else {
          shadeFrequencyByCategory[category]![shade] = 1;
        }
      }
    });
  }

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

      final sortedShades = shadeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
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
              _capitalizeFirstLetter(category),
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

  Widget _buildNoSavedDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(229, 184, 210, 0.2),
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
          color: Color.fromRGBO(229, 184, 210, 0.3),
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
                        Text(
                          '${look.lookName} Look', 
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7E4A71)
                          ),
                        ),
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
                    _capitalizeFirstLetter(category),
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
          color: Color.fromRGBO(229, 184, 210, 0.2),
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
          Text(
            '${look.lookName} Look', 
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7E4A71)
            ),
          ),
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
                    _capitalizeFirstLetter(category),
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
                color: Color.fromRGBO(255, 255, 255, 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _capitalizeFirstLetter(shade.shadeName),
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
                    color: Color.fromRGBO(0, 0, 0, 0.15),
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
                  Container(
                    width: 200, 
                    height: 200, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.8),
                          Color.fromRGBO(255, 255, 255, 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
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
                              color: Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25), 
                  
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _capitalizeFirstLetter(shade.shadeName),
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
                  
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _capitalizeFirstLetter(shade.shadeType),
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
                      color: Color.fromRGBO(126, 74, 113, 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
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
                  color: Color.fromRGBO(158, 158, 158, 0.5),
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

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class ElegantTopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.5,
      size.height - 40,
    );
    
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

class ModernLogoutDialogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08E91E63)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0x059C4D6F)
      ..style = PaintingStyle.fill;

    // Soft background circles
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.1),
      size.width * 0.08,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.25),
      size.width * 0.06,
      paint2,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.05,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      size.width * 0.04,
      paint2,
    );

    // Elegant glitter effects
    final sparklePaint = Paint()
      ..color = const Color(0x15FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final random = Random();
    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.3;
      
      // Only draw sparkles in certain areas to keep it elegant
      if (y > size.height * 0.3 && y < size.height * 0.7) {
        canvas.drawCircle(Offset(x, y), radius, sparklePaint);
      }
    }

    // Subtle border decoration
    final borderPaint = Paint()
      ..color = const Color(0x08E91E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(28),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}