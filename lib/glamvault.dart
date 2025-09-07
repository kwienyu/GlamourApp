import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:intl/intl.dart';
import 'makeup_tips_generator.dart';
import 'profile_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'makeup_guide.dart';  // Added import


enum LookType { user, client }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glam Vault',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const GlamVaultScreen(userId: 1),
    );
  }
}

class GlamVaultScreen extends StatefulWidget {
  final int userId;
  final File? initialImage;

  const GlamVaultScreen({
    super.key, 
    required this.userId,
    this.initialImage,
  });

  @override
  _GlamVaultScreenState createState() => _GlamVaultScreenState();
}

class _GlamVaultScreenState extends State<GlamVaultScreen> {
  List<SavedLook> savedLooks = [];
  bool isLoading = true;
  Map<int, Map<String, dynamic>> lookShades = {};
  Map<int, Uint8List?> lookImages = {};
  LookType _selectedLookType = LookType.user;
  File? _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    _fetchSavedLooks();
  }

  List<SavedLook> get _filteredLooks {
    return savedLooks.where((look) {
      if (_selectedLookType == LookType.user) {
        return !look.isClientLook;
      } else {
        return look.isClientLook;
      }
    }).toList()
      ..sort((a, b) => b.capturedDate.compareTo(a.capturedDate));
  }

  Widget _buildImagePreview(File imageFile, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: screenWidth * 0.06,
          ),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id') ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSelection(userId: userId),
              ),
            );
          },
        ),
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: screenHeight * 0.09,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.face_retouching_natural,
              color: Colors.black,
              size: screenWidth * 0.08,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MakeupGuide(userId: widget.userId.toString()),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.pinkAccent[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'My Looks',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: _selectedLookType == LookType.user
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        selected: _selectedLookType == LookType.user,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLookType = LookType.user;
                          });
                        },
                        selectedColor: Colors.pinkAccent,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Client Looks',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: _selectedLookType == LookType.client
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        selected: _selectedLookType == LookType.client,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLookType = LookType.client;
                          });
                        },
                        selectedColor: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.pinkAccent,
                          size: 50,
                        ),
                      )
                    : Column(
                        children: [
                          if (_currentImage != null)
                            _buildImagePreview(_currentImage!, screenWidth),
                          Expanded(
                            child: _filteredLooks.isEmpty
                                ? Center(
                                    child: Text(
                                      'No ${_selectedLookType == LookType.user ? 'user' : 'client'} looks yet!',
                                      style: TextStyle(fontSize: screenWidth * 0.045),
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.025),
                                    child: CustomScrollView(
                                      slivers: [
                                        SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                (screenWidth > 600) ? 3 : 2,
                                            crossAxisSpacing: screenWidth * 0.02,
                                            mainAxisSpacing: screenWidth * 0.02,
                                            childAspectRatio: 0.7,
                                          ),
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final look = _filteredLooks[index];
                                              return GestureDetector(
                                                onTap: () =>
                                                    _navigateToLookDetails(look),
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        screenWidth * 0.04),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                            top: Radius.circular(
                                                                screenWidth * 0.04),
                                                          ),
                                                          child: _buildLookImage(
                                                              lookImages[
                                                                  look.savedLookId],
                                                              screenWidth),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.all(
                                                            screenWidth * 0.02),
                                                        child: Text(
                                                          look.makeupLookName,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize:
                                                                screenWidth * 0.035,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth * 0.02),
                                                        child: Text(
                                                          look.formattedDate,
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth * 0.025,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      if (look.isClientLook)
                                                        Padding(
                                                          padding: EdgeInsets.only(
                                                              bottom:
                                                                  screenWidth * 0.01),
                                                          child: Text(
                                                            'Client Look',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  screenWidth * 0.03,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: _filteredLooks.length,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _fetchSavedLooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/user/${widget.userId}/saved_looks'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<SavedLook> loadedLooks = [];

        for (var lookData in data['saved_looks']) {
          try {
            final dateString = lookData['saved_date'];
            DateTime savedDate;
            
            if (dateString is String) {
              if (dateString.contains('T')) {
                savedDate = DateTime.parse(dateString).toLocal();
              } else {
                try {
                  savedDate = DateTime.parse(dateString).toLocal();
                } catch (e) {
                  savedDate = DateTime.now().toLocal();
                }
              }
            } else if (dateString is int) {
              savedDate = DateTime.fromMillisecondsSinceEpoch(dateString * 1000).toLocal();
            } else {
              savedDate = DateTime.now().toLocal();
            }

            final look = SavedLook.fromJson({
              ...lookData,
              'saved_date': savedDate,
            });
            
            loadedLooks.add(look);

            if (look.imageData != null) {
              final processedImage = await _processAndCacheImage(
                look.savedLookId, 
                look.imageData!,
                prefs
              );
              lookImages[look.savedLookId] = processedImage;
            }

            await _fetchShadesForLook(look.savedLookId);
          } catch (e) {
            debugPrint('Error processing look ${lookData['saved_look_id']}: $e');
          }
        }

        setState(() {
          savedLooks = loadedLooks;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load saved looks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved looks: $e')),
      );
    }
  }

  Future<Uint8List?> _processAndCacheImage(
    int lookId, 
    String imageData, 
    SharedPreferences prefs
  ) async {
    try {
      final cachedKey = 'look_image_$lookId';
      final cachedImage = prefs.getString(cachedKey);
      
      if (cachedImage != null) {
        try {
          return base64Decode(cachedImage);
        } catch (e) {
          debugPrint('Failed to decode cached image for look $lookId: $e');
          await prefs.remove(cachedKey);
        }
      }

      Uint8List? imageBytes;
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',').last;
        imageBytes = base64Decode(base64String);
      } else {
        imageBytes = base64Decode(imageData);
      }

      return imageBytes;
    } catch (e) {
      debugPrint('Error processing image for look $lookId: $e');
      return null;
    }
  }

  Future<void> _fetchShadesForLook(int savedLookId) async {
    try {
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/saved_looks/$savedLookId/shades'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          lookShades[savedLookId] = Map<String, dynamic>.from(data['shades']);
        });

        if (data['image_data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final imageBytes = await _processAndCacheImage(
            savedLookId,
            data['image_data'],
            prefs
          );
          
          if (imageBytes != null) {
            setState(() {
              lookImages[savedLookId] = imageBytes;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading shades for look $savedLookId: $e');
    }
  }

 void _navigateToLookDetails(SavedLook look) {
  final shades = lookShades[look.savedLookId] ?? {};
  final imageBytes = lookImages[look.savedLookId];

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LookDetailsScreen(
        look: look,
        shades: shades,
        imageBytes: imageBytes,
        userId: widget.userId.toString(), // Pass the user ID here
      ),
    ),
  );
}

  Widget _buildLookImage(Uint8List? imageBytes, double screenWidth) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return _buildPlaceholder(screenWidth);
    }

    try {
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image.memory error: $error');
          return _buildErrorPlaceholder(screenWidth);
        },
      );
    } catch (e) {
      debugPrint('Error building image: $e');
      return _buildErrorPlaceholder(screenWidth);
    }
  }

  Widget _buildPlaceholder(double screenWidth) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.photo_library,
          size: screenWidth * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double screenWidth) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: screenWidth * 0.1,
            ),
            Text(
              'Invalid image',
              style: TextStyle(
                color: Colors.red,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedLook {
  final int savedLookId;
  final String makeupLookName;
  final String? imageData;
  final bool isClientLook;
  final DateTime capturedDate;

  SavedLook({
    required this.savedLookId,
    required this.makeupLookName,
    this.imageData,
    this.isClientLook = false,
    required this.capturedDate,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    DateTime parseCapturedDate(dynamic date) {
      if (date == null) return DateTime.now();

      try {
        if (date is String) {
          if (date.contains('T')) {
            return DateTime.parse(date).toLocal();
          }
          try {
            return DateFormat('yyyy-MM-dd HH:mm:ss').parse(date).toLocal();
          } catch (e) {
            debugPrint('Failed to parse date string: $date');
          }
        } else if (date is int) {
          return DateTime.fromMillisecondsSinceEpoch(date * 1000).toLocal();
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
      return DateTime.now();
    }

    return SavedLook(
      savedLookId: json['saved_look_id'],
      makeupLookName: json['makeup_look_name'],
      imageData: json['image_data'],
      isClientLook: json['is_client_look'] ?? false,
      capturedDate: parseCapturedDate(json['captured_date'] ?? json['saved_date']),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String formatTime(DateTime date) {
      return DateFormat('h:mm a').format(date);
    }

    if (capturedDate.year == now.year &&
        capturedDate.month == now.month &&
        capturedDate.day == now.day) {
      return 'Today at ${formatTime(capturedDate)}';
    } else if (capturedDate.year == yesterday.year &&
        capturedDate.month == yesterday.month &&
        capturedDate.day == yesterday.day) {
      return 'Yesterday at ${formatTime(capturedDate)}';
    } else {
      return DateFormat('MM/dd/yyyy').format(capturedDate);
    }
  }
}

class LookDetailsScreen extends StatefulWidget {
  final SavedLook look;
  final Map<String, dynamic> shades;
  final Uint8List? imageBytes;
  final String userId;

  const LookDetailsScreen({
    super.key,
    required this.look,
    required this.shades,
    this.imageBytes,
    required this.userId, // Add this
  });

  @override
  State<LookDetailsScreen> createState() => _LookDetailsScreenState();
}

class _LookDetailsScreenState extends State<LookDetailsScreen> {
  String _userFaceShape = 'Oval';
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  bool _showTipsBox = false;
  String? _currentProductName;
  String? _currentTip;

  @override
  void initState() {
    super.initState();
    _loadFaceShape();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  Future<void> _loadFaceShape() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userFaceShape = prefs.getString('face_shape') ?? 'Oval';
    });
  }

  void toggleTipsBox(String productName) {
    final tip = MakeupTipsGenerator.getTip(_userFaceShape, productName);

    setState(() {
      if (_showTipsBox && _currentProductName == productName) {
        _showTipsBox = false;
        _currentProductName = null;
        _currentTip = null;
      } else {
        _showTipsBox = true;
        _currentProductName = productName;
        _currentTip = tip;
      }
    });
  }

  Widget _buildShadeChip(dynamic shade) {
    try {
      final hexCode = shade['hex_code']?.toString() ?? '';
      final isSelected = shade['is_selected'] ?? false;
      final colorValue = hexCode.isNotEmpty
          ? int.parse(
              hexCode.startsWith('#') ? hexCode.substring(1, 7) : hexCode,
              radix: 16) +
              0xFF000000
          : 0xFFCCCCCC;

      return Container(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        decoration: BoxDecoration(
          color: Color(colorValue),
          borderRadius: BorderRadius.circular(screenWidth * 0.075),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.black12,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                hexCode.isNotEmpty ? hexCode : '',
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  color: _getContrastColor(hexCode),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[800],
                  size: screenWidth * 0.04,
                ),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error rendering shade: $e');
      return Container();
    }
  }

  Color _getContrastColor(String hexColor) {
    if (hexColor.isEmpty) return Colors.black;

    try {
      final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
      final brightness = color.computeLuminance();
      return brightness > 0.5 ? Colors.black : Colors.white;
    } catch (e) {
      return Colors.black;
    }
  }

  Widget _buildTipsBox() {
    if (!_showTipsBox || _currentTip == null || _currentProductName == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: screenWidth * 0.02,
      top: screenHeight * 0.60,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: screenWidth * 0.6,
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.pinkAccent[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_currentProductName Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  color: Colors.pinkAccent,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                _currentTip!,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductWithTips(String productName, List<dynamic> shades) {
    final selectedShade = shades.firstWhere(
      (shade) => shade['is_selected'] == true,
      orElse: () => null,
    );

    return Padding(
      padding: EdgeInsets.only(top: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
              fontFamily: 'Serif',
            ),
          ),
          if (selectedShade != null)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.005),
              child: Text(
                'Selected: ${selectedShade['shade_name']}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.green[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SizedBox(height: screenHeight * 0.01),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenWidth * 0.02,
            children: shades.map((shade) => _buildShadeChip(shade)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.photo_library,
          size: screenWidth * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: screenWidth * 0.1,
            ),
            Text(
              'Invalid image',
              style: TextStyle(
                color: Colors.red,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeScreenWidth =
        screenWidth > 0 ? screenWidth : MediaQuery.of(context).size.width;
    final safeScreenHeight =
        screenHeight > 0 ? screenHeight : MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: safeScreenWidth * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: safeScreenHeight * 0.08,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.lightbulb_outline,
              size: safeScreenWidth * 0.06,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                   builder: (context) => MakeupTipsPage(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(safeScreenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved on: ${widget.look.formattedDate}',
                  style: TextStyle(
                    fontSize: safeScreenWidth * 0.035,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: safeScreenHeight * 0.015),
                SizedBox(
                  height: safeScreenHeight * 0.4,
                  width: double.infinity,
                  child: widget.imageBytes != null
                      ? Image.memory(
                          widget.imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildErrorPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
                SizedBox(height: safeScreenHeight * 0.025),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Type of makeup Look:',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: safeScreenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: safeScreenHeight * 0.005),
                      Text(
                        widget.look.makeupLookName,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: safeScreenWidth * 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: safeScreenHeight * 0.015),
                if (widget.look.isClientLook)
                  Padding(
                    padding: EdgeInsets.only(bottom: safeScreenHeight * 0.02),
                    child: Text(
                      'Client Look',
                      style: TextStyle(
                        fontSize: safeScreenWidth * 0.04,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (widget.shades.isNotEmpty) ...[
                  Text(
                    'Shades:',
                    style: TextStyle(
                      fontSize: safeScreenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                  ...widget.shades.entries.map((entry) =>
                      _buildProductWithTips(entry.key, entry.value is List ? entry.value : [])),
                ],
              ],
            ),
          ),
          _buildTipsBox(),
        ],
      ),
    );
  }
}