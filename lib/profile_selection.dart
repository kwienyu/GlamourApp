import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'selection_page.dart';
import 'camera2.dart';
import 'glamvault.dart';
import 'makeup_artistform.dart';
import 'faceshapes.dart';
import 'skintone.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'apicall_recommendation.dart';
import 'looks_shadecombination.dart';
import 'package:animations/animations.dart';


class ProfileSelection extends StatefulWidget {
  final String userId;
  const ProfileSelection({super.key, required this.userId});

  @override
  _ProfileSelectionState createState() => _ProfileSelectionState();
}

class MakeupRecommendation {
  final int userId;
  final String? faceShape;
  final String? skinTone;
  final String? undertone;
  final List<dynamic> recommendedTypes;
  final List<dynamic> makeupLooks;

  MakeupRecommendation({
    required this.userId,
    this.faceShape,
    this.skinTone,
    this.undertone,
    required this.recommendedTypes,
    required this.makeupLooks,
  });

  factory MakeupRecommendation.fromJson(Map<String, dynamic> json) {
    return MakeupRecommendation(
      userId: json['user_id'] ?? 0,
      faceShape: json['user_face_shape']?.toString(),
      skinTone: json['user_skin_tone']?.toString(),
      undertone: json['user_undertone']?.toString(),
      recommendedTypes: json['recommended_makeup_types'] ?? [],
      makeupLooks: json['makeup_looks_with_shade_combinations'] ?? [],
    );
  }
}

class _ProfileSelectionState extends State<ProfileSelection> {
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

  // Shade recommendations variables
  Map<String, dynamic>? _weeklyTopShadesData;
  Map<String, dynamic>? _monthlyTopShadesData;
  bool _isLoadingShades = false;
  String? _userSkinTone;
  String _selectedWeeklyShadeCategory = 'foundation';
  String _selectedMonthlyShadeCategory = 'foundation';
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
    
  // Makeup recommendation variables
  Map<String, dynamic>? _makeupRecommendations;
  bool _isLoadingRecommendations = false;

  // API Service instance
  final _recommendationService = ApiCallRecommendation();

  @override
  void initState() {
    super.initState();
    _fetchProfileData().then((_) {
      _fetchTopShades();
      _fetchMakeupRecommendations();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showBubble = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

Future<void> _fetchMakeupRecommendations() async {
  setState(() => _isLoadingRecommendations = true);
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = int.parse(prefs.getString('user_id') ?? widget.userId);
    
    final response = await _recommendationService.getFullRecommendation(userId);
    
    setState(() {
      _makeupRecommendations = response;
    });
  } on Exception catch (e) {
    debugPrint('Error fetching recommendations: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load recommendations: $e')),
    );
    setState(() {
      _makeupRecommendations = null;
    });
  } finally {
    setState(() => _isLoadingRecommendations = false);
  }
}

  Future<void> _fetchTopShades() async {
    if (_userSkinTone == null) return;

    setState(() => _isLoadingShades = true);

    try {
      final weeklyResponse = await _recommendationService.getTopShadesMap('week', _userSkinTone!);
      final monthlyResponse = await _recommendationService.getTopShadesMap('month', _userSkinTone!);

      setState(() {
        _weeklyTopShadesData = weeklyResponse;
        _monthlyTopShadesData = monthlyResponse;
      });
    } catch (e) {
      debugPrint('Error fetching top shades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load shade recommendations: $e')),
      );
    } finally {
      setState(() => _isLoadingShades = false);
    }
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
                        radius: 50,
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
            title: const Text('Home')
                .animate()
                .fadeIn(delay: 200.ms)
                .slideX(begin: -0.2, end: 0),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Settings')
                .animate()
                .fadeIn(delay: 300.ms)
                .slideX(begin: -0.2, end: 0),
            onTap: () => Navigator.pop(context),
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
        _userSkinTone = data['skin_tone'];
        profilePic = imageBytes;
        email = data['email'] ?? "Not available";
        username = data['username'];
        gender = data['gender'] ?? "Not specified";
        dob = data['dob'] ?? "Not specified";
        age = data['age'] ?? calculateAge(data['dob']);
        
        // Try to get undertone from profile data if available
        // If not, we'll get it from the recommendations API later
        if (data['undertone'] != null) {
          // Store undertone in shared preferences for later use
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
          _buildPersonalizedAnalysisSection(),
          _buildRecommendedMakeupTypesSection(),
          _buildWeeklyTopShadesSection(),
          _buildMonthlyTopShadesSection(),
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
                  color: Colors.pinkAccent.withOpacity(0.5),
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
          _buildProfileCard(context, Icons.star, "Glam Vault", GlamVaultScreen(userId: parsedUserId))
              .animate()
              .fadeIn(delay: 400.ms)
              .scaleXY(begin: 0.8, end: 1),
              _buildProfileCard(context, 'assets/top_report.png', "Top Recommended Shades", SelectionPage(userId: widget.userId))
              .animate()
              .fadeIn(delay: 200.ms)
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
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.08,
            runSpacing: screenWidth * 0.05,
            children: [
              _buildCategoryItem(context, 'assets/face shape 2.png', 'Face Shape', FaceShapesApp(userId: widget.userId)),
              _buildCategoryItem(context, 'assets/skin tone 2.png', 'Skin Tone', SkinTone(userId: widget.userId)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPersonalizedAnalysisSection() {
  if (_isLoadingRecommendations) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.pinkAccent,
        size: 50,
      ),
    );
  }

  String? displayedUndertone;

  // First try to get undertone from local storage
  if (_makeupRecommendations == null) {
    // If no recommendations yet, try to get undertone from shared preferences
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final storedUndertone = prefs.getString('user_undertone');
      if (storedUndertone != null && mounted) {
        setState(() {
          displayedUndertone = storedUndertone;
        });
      }
    });
  } else {
    // If we have recommendations, get undertone from there
    final recommendation = MakeupRecommendation.fromJson(_makeupRecommendations!);
    displayedUndertone = recommendation.undertone;
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Personalized Analysis',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 10, 10, 10),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildAttributeChip('Face Shape: ${faceShape ?? "Not analyzed"}'),
              const SizedBox(width: 8),
              _buildAttributeChip('Skin Tone: ${skinTone ?? "Not analyzed"}'),
              const SizedBox(width: 8),
              _buildAttributeChip('Undertone: ${displayedUndertone ?? "Not analyzed"}'),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRecommendedMakeupTypesSection() {
  // Default makeup types for new users or when no recommendations are available
  final defaultMakeupTypes = [
    {'makeup_type_name': 'Casual', 'usage_count': 0},
    {'makeup_type_name': 'Light', 'usage_count': 0},
    {'makeup_type_name': 'Heavy', 'usage_count': 0}
  ];

  // Default makeup looks for each type
  final defaultMakeupLooks = [
    {'makeup_look_name': 'No-Makeup', 'shade_combinations': []},
    {'makeup_look_name': 'Everyday Glow', 'shade_combinations': []},
    {'makeup_look_name': 'SunKissed Glow', 'shade_combinations': []},
    {'makeup_look_name': 'Dewy', 'shade_combinations': []},
    {'makeup_look_name': 'Rosy Cheeks', 'shade_combinations': []},
    {'makeup_look_name': 'Soft Glam', 'shade_combinations': []},
    {'makeup_look_name': 'Matte', 'shade_combinations': []},
    {'makeup_look_name': 'Cut Crease', 'shade_combinations': []},
    {'makeup_look_name': 'Glam Night', 'shade_combinations': []}
  ];

  // Map of makeup types to their looks
  final makeupTypeLooks = {
    'Casual': ['No-Makeup', 'Everyday Glow', 'SunKissed Glow'],
    'Light': ['Dewy', 'Rosy Cheeks', 'Soft Glam'],
    'Heavy': ['Matte', 'Cut Crease', 'Glam Night'],
  };

  // Determine which data to use
  final List<dynamic> typesToDisplay = _makeupRecommendations != null 
      ? MakeupRecommendation.fromJson(_makeupRecommendations!).recommendedTypes
      : defaultMakeupTypes;

  final List<dynamic> looksToUse = _makeupRecommendations != null
      ? MakeupRecommendation.fromJson(_makeupRecommendations!).makeupLooks
      : defaultMakeupLooks;

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Makeup Types',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 10, 10, 10),
          ),
        ),
        const SizedBox(height: 16),
        if (_makeupRecommendations == null && !_isLoadingRecommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Explore popular makeup types and discover looks that suit you',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
         SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: typesToDisplay.length,
            itemBuilder: (context, index) {
              final type = typesToDisplay[index];
              final typeName = type['makeup_type_name']?.toString() ?? 'Unknown';
              final usageCount = type['usage_count'] ?? 0;
              final looks = makeupTypeLooks[typeName] ?? [];
              
              return GestureDetector(
                onTap: () {
                  // Filter the makeup looks for this type
                  final filteredLooks = looksToUse.where((look) {
                    final lookName = look['makeup_look_name']?.toString();
                    return lookName != null && looks.contains(lookName);
                  }).toList();
                  
                  Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => MakeupLooksPage(
      makeupLooks: filteredLooks,
      makeupType: typeName,
      isDefaultData: _makeupRecommendations == null,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 600),
  ),
);
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 254, 138, 177).withOpacity(0.8),
                        Colors.pinkAccent.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glow effect
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pink.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        left: -10,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purple.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Makeup type name with elegant styling
                            Text(
                              typeName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.pink[800],
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            // Usage count with decorative styling - CENTERED
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.pink.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _makeupRecommendations == null 
                                      ? 'Explore Looks' 
                                      : '$usageCount\nrecommendations',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.pink[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // "Tap to view" text
                            Text(
                              'View Popular Look and Shade Combinations',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(
                  onPlay: (controller) => controller.forward(),
                )
                .scale(
                  duration: 200.ms,
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOut,
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildWeeklyTopShadesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Top Recommended Shade',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 16, 16, 16),
            ),
          ),
          const SizedBox(height: 16),
          if (_userSkinTone != null)
            Text(
              'Based on your $_userSkinTone skin tone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          _buildShadeCategoryTabs('weekly'),
          const SizedBox(height: 16),
          _buildTopShadesList(_weeklyTopShadesData, _selectedWeeklyShadeCategory),
          const SizedBox(height: 20),
          _buildViewAnalyticsButton(_weeklyTopShadesData, 'Weekly'),
        ],
      ),
    );
  }

  Widget _buildMonthlyTopShadesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Top Recommended Shade',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 16, 16, 16),
            ),
          ),
          const SizedBox(height: 16),
          if (_userSkinTone != null)
            Text(
              'Based on your $_userSkinTone skin tone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          _buildShadeCategoryTabs('monthly'),
          const SizedBox(height: 16),
          _buildTopShadesList(_monthlyTopShadesData, _selectedMonthlyShadeCategory),
          const SizedBox(height: 20),
          _buildViewAnalyticsButton(_monthlyTopShadesData, 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildShadeCategoryTabs(String period) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryOrder.length,
        itemBuilder: (context, index) {
          final category = _categoryOrder[index];
          final displayName = category[0].toUpperCase() + category.substring(1);
          final isSelected = period == 'weekly' 
              ? _selectedWeeklyShadeCategory == category
              : _selectedMonthlyShadeCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.pinkAccent,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.pinkAccent,
              backgroundColor: Colors.pink[50],
              onSelected: (selected) {
                setState(() {
                  if (period == 'weekly') {
                    _selectedWeeklyShadeCategory = category;
                  } else {
                    _selectedMonthlyShadeCategory = category;
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopShadesList(Map<String, dynamic>? shadesData, String selectedCategory) {
    if (_isLoadingShades) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Colors.pinkAccent,
          size: 50,
        ),
      );
    }

    if (shadesData == null || shadesData.isEmpty) {
      return const Center(child: Text('No shade data available'));
    }

    final shades = shadesData[selectedCategory] ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (shades.isNotEmpty)
              _buildShadeItem(shades[0]),
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

  Widget _buildShadeItem(Map<String, dynamic> shade) {
    return GestureDetector(
      onTap: () => _showShadeDetails(shade),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
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
                  Text(
                    'Top Match',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (shade['shade_name'] != null)
                    Text(
                      shade['shade_name'],
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  LinearProgressIndicator(
                    value: (shade['match_count'] ?? 0) / 1500,
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
              '${shade['match_count'] ?? 0}',
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

  Widget _buildViewAnalyticsButton(Map<String, dynamic>? shadesData, String period) {
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
          _showDetailedAnalytics(shadesData, period);
        },
        child: Text(
          'View $period Shades Applied',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDetailedAnalytics(Map<String, dynamic>? shadesData, String period) {
    if (shadesData == null) return;

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
                '$period Top Shades',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Based on your $_userSkinTone skin tone',
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
                      Text(
                        'Top Shades Across Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...shadesData.entries.map((entry) {
                        if (entry.value.isEmpty) return const SizedBox();
                        final shade = entry.value[0];
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
                            _buildDetailedShadeItem(shade, 1),
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

  Widget _buildDetailedShadeItem(Map<String, dynamic> shade, int rank) {
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
      subtitle: Text('${shade['hex_code']} • Top #$rank'),
      trailing: Text('${shade['match_count'] ?? 0} matches'),
      onTap: () => _showShadeDetails(shade),
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
                'Match Count: ${shade['match_count'] ?? 0}',
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

  Widget _buildAttributeChip(String text) {
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
                  color: Colors.grey.withOpacity(0.5),
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
  Color _getContrastColor(String hexColor) {
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