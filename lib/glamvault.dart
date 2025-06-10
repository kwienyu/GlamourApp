import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'profile_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

enum LookType { user, client }

class GlamVaultScreen extends StatefulWidget {
  final int userId;

  const GlamVaultScreen({super.key, required this.userId});

  @override
  _GlamVaultScreenState createState() => _GlamVaultScreenState();
}

class _GlamVaultScreenState extends State<GlamVaultScreen> {
  List<SavedLook> savedLooks = [];
  bool isLoading = true;
  Map<int, Map<String, dynamic>> lookShades = {};
  Map<int, Uint8List?> lookImages = {};
  LookType _selectedLookType = LookType.user;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchSavedLooks();
  }

  // Getter to filter looks based on selected tab
  List<SavedLook> get _filteredLooks {
    return savedLooks.where((look) {
      if (_selectedLookType == LookType.user) {
        return !look.isClientLook;
      } else {
        return look.isClientLook;
      }
    }).toList()..sort((a, b) => b.savedDate.compareTo(a.savedDate));
  }

  Future<bool> _saveLook({
    required String lookName,
    required Map<String, List<String>> labeledShades,
    required String? imageBase64,
    bool isClientLook = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://glamouraika.com/api/saved_looks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'makeup_look': lookName,
          'shades': labeledShades,
          'image_data': imageBase64,
          'is_client_look': isClientLook,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Look saved successfully!')),
        );
        await _fetchSavedLooks(); // Refresh the list
        return true;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Unknown error');
      } else {
        throw Exception('Failed to save look: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving look: $e')),
      );
      return false;
    }
  }

  Future<void> _fetchSavedLooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/user/${widget.userId}/saved_looks'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<SavedLook> loadedLooks = [];

        for (var lookData in data['saved_looks']) {
          try {
            final look = SavedLook.fromJson(lookData);
            loadedLooks.add(look);

            // Process image data
            if (look.imageData != null) {
              final processedImage = await _processAndCacheImage(
                look.savedLookId,
                look.imageData!,
                prefs,
              );

              lookImages[look.savedLookId] = processedImage;
            }
            // Fetch shades for each look
            await _fetchShadesForLook(look.savedLookId);
            if (!mounted) return;
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
    SharedPreferences prefs,
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

      // Process new image data
      Uint8List? imageBytes;
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',').last;
        imageBytes = base64Decode(base64String);
      } else {
        imageBytes = base64Decode(imageData);
      }

      await prefs.setString(cachedKey, base64Encode(imageBytes));

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

        // Process image if included in shades response
        if (data['image_data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final imageBytes = await _processAndCacheImage(
            savedLookId,
            data['image_data'],
            prefs,
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

    void _showSaveLookDialog() {
      final screenWidth = MediaQuery.of(context).size.width;
      String lookName = '';
      bool isClientLook = false;
      String? imageBase64;
      Map<String, List<String>> labeledShades = {
        'Foundation': [],
        'Eyeshadow': [],
        'Lipstick': [],
      };

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Save New Look', style: TextStyle(fontSize: screenWidth * 0.045)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Look Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => lookName = value,
                      ),
                      SizedBox(height: 20),
                      CheckboxListTile(
                        title: Text('Client Look'),
                        value: isClientLook,
                        onChanged: (value) => setState(() => isClientLook = value ?? false),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setState(() {
                              imageBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        child: Text('Select Image'),
                      ),
                      SizedBox(height: 20),
                      Text('Select Shades:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...labeledShades.keys.map((shadeType) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shadeType),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter hex codes separated by commas',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                labeledShades[shadeType] = value
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                              },
                            ),
                            SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (lookName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a look name')),
                        );
                        return;
                      }
                      
                      final success = await _saveLook(
                        lookName: lookName,
                        labeledShades: labeledShades,
                        imageBase64: imageBase64,
                        isClientLook: isClientLook,
                      );
                      
                      if (success) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
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
        ),
      ),
    );
  }

  Widget _buildLookImage(Uint8List? imageBytes, double screenWidth) {
    if (imageBytes == null) {
      return _buildPlaceholder(screenWidth);
    }

    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image.memory error: $error');
        return _buildErrorPlaceholder(screenWidth);
      },
    );
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
              MaterialPageRoute(builder: (context) => ProfileSelection(userId: userId)),
            );
          },
        ),
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: screenHeight * 0.08,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.pinkAccent[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: () => _showSaveLookDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
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
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLooks.isEmpty
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
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: (screenWidth > 600) ? 3 : 2,
                                    crossAxisSpacing: screenWidth * 0.02,
                                    mainAxisSpacing: screenWidth * 0.02,
                                    childAspectRatio: 0.7,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final look = _filteredLooks[index];
                                      return GestureDetector(
                                        onTap: () => _navigateToLookDetails(look),
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(screenWidth * 0.04),
                                                  ),
                                                  child: _buildLookImage(lookImages[look.savedLookId], screenWidth),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(screenWidth * 0.02),
                                                child: Text(
                                                  look.makeupLookName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: screenWidth * 0.035,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                                child: Text(
                                                  look.formattedDate,
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.025,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              if (look.isClientLook)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: screenWidth * 0.01),
                                                  child: Text(
                                                    'Client Look',
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.03,
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
          );
        },
      ),
    );
  }
}

class SavedLook {
  final int savedLookId;
  final String makeupLookName;
  final String? imageData;
  final bool isClientLook;
  final DateTime savedDate;

  SavedLook({
    required this.savedLookId,
    required this.makeupLookName,
    this.imageData,
    this.isClientLook = false,
    required this.savedDate,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    return SavedLook(
      savedLookId: json['saved_look_id'],
      makeupLookName: json['makeup_look_name'],
      imageData: json['image_data'],
      isClientLook: json['is_client_look'] ?? false,
      savedDate: json['saved_date'] != null
          ? DateTime.parse(json['saved_date'])
          : DateTime.now(),
    );
  }

  String get formattedDate {
    return '${savedDate.month}/${savedDate.day}/${savedDate.year} ${savedDate.hour}:${savedDate.minute.toString().padLeft(2, '0')}';
  }
}

class LookDetailsScreen extends StatelessWidget {
  final SavedLook look;
  final Map<String, dynamic> shades;
  final Uint8List? imageBytes;

  const LookDetailsScreen({
    super.key,
    required this.look,
    required this.shades,
    this.imageBytes,
  });

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: screenHeight * 0.08,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved on: ${look.formattedDate}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  height: screenHeight * 0.4,
                  width: double.infinity,
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildErrorPlaceholder(screenWidth);
                          },
                        )
                      : _buildPlaceholder(screenWidth),
                ),
                SizedBox(height: screenHeight * 0.025),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Type of makeup Look:',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        look.makeupLookName,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: screenWidth * 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                if (look.isClientLook)
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                    child: Text(
                      'Client Look',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (shades.isNotEmpty) ...[
                  Text(
                    'Shades:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                  ...shades.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.02),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.04,
                              fontFamily: 'Serif',
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          if (entry.value is List)
                            Wrap(
                              spacing: screenWidth * 0.02,
                              runSpacing: screenWidth * 0.02,
                              children: (entry.value as List).map((shade) {
                                try {
                                  final hexCode = shade['hex_code']?.toString() ?? '';
                                  final colorValue = hexCode.isNotEmpty
                                      ? int.parse(
                                          hexCode.startsWith('#')
                                              ? hexCode.substring(1, 7)
                                              : hexCode,
                                          radix: 16) +
                                          0xFF000000
                                      : 0xFFCCCCCC;

                                  return Container(
                                    width: screenWidth * 0.12,
                                    height: screenWidth * 0.12,
                                    decoration: BoxDecoration(
                                      color: Color(colorValue),
                                      borderRadius: BorderRadius.circular(screenWidth * 0.06),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: shade['shade_name'] != null
                                        ? Tooltip(
                                            message: shade['shade_name'].toString(),
                                            child: Container(),
                                          )
                                        : null,
                                  );
                                } catch (e) {
                                  debugPrint('Error rendering shade: $e');
                                  return Container();
                                }
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
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