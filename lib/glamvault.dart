import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'profile_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<int, Uint8List?> lookImages = {}; // Strictly typed map

  @override
  void initState() {
    super.initState();
    _fetchSavedLooks();
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
      // Check if we have a cached version
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
        // Handle data URI format
        final base64String = imageData.split(',').last;
        imageBytes = base64Decode(base64String);
      } else {
        // Assume it's raw base64
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : savedLooks.isEmpty
              ? Center(child: Text('No saved looks yet!'))
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
                            final look = savedLooks[index];
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
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: savedLooks.length,
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

  SavedLook({
    required this.savedLookId,
    required this.makeupLookName,
    this.imageData,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    return SavedLook(
      savedLookId: json['saved_look_id'],
      makeupLookName: json['makeup_look_name'],
      imageData: json['image_data'],
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(look.makeupLookName),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
            if (shades.isNotEmpty) ...[
              Text('Shades:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...shades.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                  : 0xFFCCCCCC; // Default gray if no color
                              
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