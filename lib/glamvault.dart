import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'profile_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add this enum for look types
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
  LookType _selectedLookType = LookType.user; // Track selected tab

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
    }).toList()
    // Sort by date in descending order (newest first)
    ..sort((a, b) => b.savedDate.compareTo(a.savedDate));
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
                prefs
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

      // Process new image data
      Uint8List? imageBytes;
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',').last;
        imageBytes = base64Decode(base64String);
      } else {
        imageBytes = base64Decode(imageData);
      }

      // Cache the image
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
        ),
      ),
    );
  }

  Widget _buildLookImage(Uint8List? imageBytes) {
    if (imageBytes == null) {
      return _buildPlaceholder();
    }

    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image.memory error: $error');
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.photo_library, size: 50, color: Colors.grey),
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
            Icon(Icons.error_outline, color: Colors.red),
            Text('Invalid image', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id') ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileSelection(userId: userId)),
            );
          },
        ),
        title: Transform.translate(
          offset: Offset(-10, 1), 
          child: Image.asset(
            'assets/glam_logo.png',
            height: 60,
          ),
        ),
      ),
      backgroundColor: Colors.pinkAccent[50],
      body: Column(
        children: [
          // Add the tab navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('My Looks'),
                    selected: _selectedLookType == LookType.user,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLookType = LookType.user;
                      });
                    },
                    selectedColor: Colors.pinkAccent,
                    labelStyle: TextStyle(
                      color: _selectedLookType == LookType.user 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Client Looks'),
                    selected: _selectedLookType == LookType.client,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLookType = LookType.client;
                      });
                    },
                    selectedColor: Colors.pinkAccent,
                    labelStyle: TextStyle(
                      color: _selectedLookType == LookType.client 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredLooks.isEmpty
                    ? Center(child: Text('No ${_selectedLookType == LookType.user ? 'user' : 'client'} looks yet!'))
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: CustomScrollView(
                          slivers: [
                            SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.7,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final look = _filteredLooks[index];
                                  return GestureDetector(
                                    onTap: () => _navigateToLookDetails(look),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              child: _buildLookImage(lookImages[look.savedLookId]),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              look.makeupLookName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              look.formattedDate,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          if (look.isClientLook)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: Text(
                                                'Client Look',
                                                style: TextStyle(
                                                  fontSize: 12,
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
    );
  }
}

class SavedLook {
  final int savedLookId;
  final String makeupLookName;
  final String? imageData;
  final bool isClientLook;
  final DateTime savedDate; // Added for date tracking

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
          : DateTime.now(), // Default to now if not provided
    );
  }

  // Getter for formatted date
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/glam_logo.png',
          height: screenHeight * 0.07, // 7% of screen height
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Moved date and time above the image
            Text(
              'Saved on: ${look.formattedDate}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            
            // Image section
            SizedBox(
              height: 300,
              width: double.infinity,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorPlaceholder();
                      },
                    )
                  : _buildPlaceholder(),
            ),
            SizedBox(height: 20),
            
            // Centered makeup look type and name
            Center(
              child: Column(
                children: [
                  Text(
                    'Type of makeup Look:',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    look.makeupLookName,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            
            // Client look indicator (if applicable)
            if (look.isClientLook)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Client Look',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            // Shades section
            if (shades.isNotEmpty) ...[
              Text('Shades:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif',)),
              ...shades.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Serif',),
                      ),
                      SizedBox(height: 8),
                      if (entry.value is List)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (entry.value as List).map((shade) {
                            try {
                              final hexCode = shade['hex_code']?.toString() ?? '';
                              final colorValue = hexCode.isNotEmpty
                                  ? int.parse(
                                      hexCode.startsWith('#')
                                          ? hexCode.substring(1, 7)
                                          : hexCode,
                                      radix: 16) + 0xFF000000
                                  : 0xFFCCCCCC; 
                              
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(colorValue),
                                  borderRadius: BorderRadius.circular(25),
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
                              return Container(); // Empty container if error occurs
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
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.photo_library, size: 50, color: Colors.grey),
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
            Icon(Icons.error_outline, color: Colors.red),
            Text('Invalid image', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
