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
import 'dart:developer';

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
  GlamVaultScreenState createState() => GlamVaultScreenState();
}

class GlamVaultScreenState extends State<GlamVaultScreen> {
  List<SavedLook> savedLooks = [];
  bool isLoading = true;
  Map<int, Map<String, dynamic>> lookShades = {};
  Map<int, Uint8List?> lookImages = {};
  File? _currentImage;
  String _selectedTag = 'All Looks';
  List<String> _availableTags = ['All'];
  Map<String, List<SavedLook>> _groupedLooks = {};
  Map<int, String?> _lookTags = {};
  bool _showTagDropdown = false;
  Map<int, DateTime> _recentlyAddedLooks = {};
  

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    _loadTagsAndLookTags();
    _fetchSavedLooks();
    _loadRecentlyAddedLooks();
  }

  Future<void> _loadRecentlyAddedLooks() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLooksJson = prefs.getString('recently_added_looks');
    if (recentLooksJson != null) {
      try {
        final Map<String, dynamic> recentLooksMap = json.decode(recentLooksJson);
        _recentlyAddedLooks = recentLooksMap.map((key, value) => 
          MapEntry(int.parse(key), DateTime.parse(value)));
      } catch (e) {
        debugPrint('Error loading recently added looks: $e');
        _recentlyAddedLooks = {};
      }
    }
  }

  Future<void> _loadTagsAndLookTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tags = prefs.getStringList('available_tags') ?? ['All'];
    final lookTagsJson = prefs.getString('look_tags');
    if (lookTagsJson != null) {
      try {
        final Map<String, dynamic> lookTagsMap = json.decode(lookTagsJson);
        _lookTags = lookTagsMap.map((key, value) => MapEntry(int.parse(key), value as String?));
      } catch (e) {
        debugPrint('Error loading look tags: $e');
        _lookTags = {};
      }
    }
    
    final recentLooksJson = prefs.getString('recently_added_looks');
    if (recentLooksJson != null) {
      try {
        final Map<String, dynamic> recentLooksMap = json.decode(recentLooksJson);
        _recentlyAddedLooks = recentLooksMap.map((key, value) => 
          MapEntry(int.parse(key), DateTime.parse(value)));
      } catch (e) {
        debugPrint('Error loading recently added looks: $e');
        _recentlyAddedLooks = {};
      }
    }
    
    setState(() {
      _availableTags = tags;
    });
  }

  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('available_tags', _availableTags);
  }

  Future<void> _saveLookTags() async {
    final prefs = await SharedPreferences.getInstance();
    final lookTagsJson = json.encode(_lookTags.map((key, value) => MapEntry(key.toString(), value)));
    await prefs.setString('look_tags', lookTagsJson);
  }

  Future<void> _saveRecentlyAddedLooks() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLooksJson = json.encode(_recentlyAddedLooks.map((key, value) => 
      MapEntry(key.toString(), value.toIso8601String())));
    await prefs.setString('recently_added_looks', recentLooksJson);
  }

  void _addNewTag(String tagName) {
    if (tagName.isNotEmpty && !_availableTags.contains(tagName)) {
      setState(() {
        _availableTags.add(tagName);
        _saveTags();
      });
    }
  }

  void _markLookAsRecentlyAdded(int lookId) {
    setState(() {
      _recentlyAddedLooks[lookId] = DateTime.now();
      _saveRecentlyAddedLooks();
    });
  }

  void _clearRecentlyAddedFlag(int lookId) {
    setState(() {
      _recentlyAddedLooks.remove(lookId);
      _saveRecentlyAddedLooks();
    });
  }

  void _groupLooksByTag() {
    final grouped = <String, List<SavedLook>>{};
    
    grouped['All Looks'] = []; 
    grouped['Tagged Looks'] = []; 
    
    for (var look in savedLooks) {
      final String? tag = _lookTags[look.savedLookId] ?? look.tag;
      
      if (tag != null && tag.isNotEmpty) {
        if (!grouped.containsKey(tag)) {
          grouped[tag] = [];
        }
        grouped[tag]!.add(look);
        
        grouped['Tagged Looks']!.add(look);
      } else {
        grouped['All Looks']!.add(look);
      }
    }
    
    grouped.forEach((tag, looks) {
      looks.sort((a, b) {
        final bool aIsRecent = _isLookRecentlyAdded(a.savedLookId);
        final bool bIsRecent = _isLookRecentlyAdded(b.savedLookId);
        
        if (aIsRecent && !bIsRecent) {
          return -1;
        } else if (!aIsRecent && bIsRecent) {
          return 1;
        } else if (aIsRecent && bIsRecent) {
          return _recentlyAddedLooks[b.savedLookId]!.compareTo(_recentlyAddedLooks[a.savedLookId]!);
        } else {
          return b.capturedDate.compareTo(a.capturedDate);
        }
      });
    });
    
    setState(() {
      _groupedLooks = grouped;
    });
  }

  bool _isLookRecentlyAdded(int lookId) {
    if (!_recentlyAddedLooks.containsKey(lookId)) return false;
    
    final addedTime = _recentlyAddedLooks[lookId]!;
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    
    return addedTime.isAfter(sevenDaysAgo);
  }

  Future<Map<String, dynamic>> _saveLookToApi({
    required int userId,
    required String lookName,
    required Map<String, List<String>> labeledShades,
    String? imageData,
    String? tag,
  }) async {
    try {
      final url = Uri.parse('https://glamouraika.com/api/save_look');
      
      final requestBody = {
        'user_id': userId.toString(),
        'look_name': lookName,
        'labeled_shades': json.encode(labeledShades),
        'image_data': imageData,
        'tag': tag,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log('Full Response Body: ${response.body}');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Look saved successfully',
          'look_id': responseData['look_id']
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to save look: ${response.statusCode}',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving look: $e',
      };
    }
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

  void _toggleTagDropdown() {
    setState(() {
      _showTagDropdown = !_showTagDropdown;
    });
  }

  Widget _buildDropdownItem(String tag) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTag = tag;
          _showTagDropdown = false;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedTag == tag ? Colors.pinkAccent[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _selectedTag == tag ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: _selectedTag == tag ? Colors.pinkAccent : Colors.grey[400],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: _selectedTag == tag ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagOptionsDialog(SavedLook look) {
    final String? currentTag = _lookTags[look.savedLookId] ?? look.tag;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (currentTag == null || currentTag.isEmpty) {
      _showEditLookTagDialog(look);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.pink[50]!],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Tag Options',
                      style: TextStyle(
                        fontSize: isSmallScreen ? screenWidth * 0.055 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent[700],
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      '"${look.makeupLookName}"',
                      style: TextStyle(
                        fontSize: isSmallScreen ? screenWidth * 0.04 : 18,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pinkAccent[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.pinkAccent, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Current Tag: $currentTag',
                            style: TextStyle(
                              fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.pinkAccent[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditLookTagDialog(look);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'EDIT TAG',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _removeLookTag(look);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'REMOVE TAG',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _removeLookTag(SavedLook look) {
    final String? currentTag = _lookTags[look.savedLookId] ?? look.tag;
    
    setState(() {
      // Remove tag from lookTags map and look object
      _lookTags.remove(look.savedLookId);
      look.tag = null;
      
      // Check if the tag is still being used by other looks
      bool isTagStillUsed = false;
      _lookTags.forEach((lookId, tag) {
        if (tag == currentTag) {
          isTagStillUsed = true;
        }
      });
      
      // If tag is not used by any other look, remove it from available tags
      if (!isTagStillUsed && currentTag != null && currentTag.isNotEmpty) {
        _availableTags.remove(currentTag);
        _saveTags();
      }
      
      _saveLookTags();
      _groupLooksByTag();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tag removed from "${look.makeupLookName}"'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEditLookTagDialog(SavedLook look) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final String? currentTag = _lookTags[look.savedLookId] ?? look.tag;
    final TextEditingController tagController = TextEditingController(
      text: currentTag ?? ''
    );
    final FocusNode tagFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.pink[50]!],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      currentTag == null ? 'Tag Your Look' : 'Edit Tag',
                      style: TextStyle(
                        fontSize: isSmallScreen ? screenWidth * 0.055 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent[700],
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      '"${look.makeupLookName}"',
                      style: TextStyle(
                        fontSize: isSmallScreen ? screenWidth * 0.04 : 18,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    'Enter Tag Name',
                    style: TextStyle(
                      fontSize: isSmallScreen ? screenWidth * 0.04 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.pinkAccent[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: tagController,
                      focusNode: tagFocusNode,
                      decoration: InputDecoration(
                        hintText: 'e.g., Evening, Party, Natural...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pinkAccent[100]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? screenWidth * 0.045 : 18,
                        color: Colors.black87,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _addNewTag(value.trim());
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Your Tags',
                    style: TextStyle(
                      fontSize: isSmallScreen ? screenWidth * 0.04 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.pinkAccent[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_availableTags.where((tag) => tag != 'All').isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No tags yet. Create your first one!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? screenWidth * 0.035 : 16,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags
                          .where((tag) => tag != 'All')
                          .map((tag) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.pinkAccent[100]!,
                                Colors.pink[50]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              GestureDetector(
                                onTap: () {
                                  tagController.text = tag;
                                  tagFocusNode.requestFocus();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? screenWidth * 0.035 : 13,
                                      color: Colors.pinkAccent[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent[200],
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close, size: 14, color: Colors.white),
                                  padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                  onPressed: () {
                                    final String tagToDelete = tag;
                                    _removeTagFromAllLooks(tagToDelete);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final newTag = tagController.text.trim();
                          _updateLookTag(look, newTag.isEmpty ? null : newTag, currentTag);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          currentTag == null ? 'SAVE TAG' : 'UPDATE TAG',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? screenWidth * 0.038 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeTagFromAllLooks(String tagToDelete) {
    setState(() {
      // Remove tag from available tags
      _availableTags.remove(tagToDelete);
      _saveTags();
      
      // Remove this tag from all looks
      _lookTags.forEach((lookId, currentTag) {
        if (currentTag == tagToDelete) {
          _lookTags[lookId] = null;
          try {
            final look = savedLooks.firstWhere((l) => l.savedLookId == lookId);
            look.tag = null;
          } catch (e) {
            debugPrint('Look with id $lookId not found in savedLooks');
          }
        }
      });
      
      _saveLookTags();
      _groupLooksByTag();
    });
    
    if (_selectedTag == tagToDelete) {
      setState(() {
        _selectedTag = 'All Looks';
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tag "$tagToDelete" removed from all looks'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateLookTag(SavedLook look, String? newTag, String? oldTag) {
    setState(() {
      // If changing from one tag to another, handle the old tag cleanup
      if (oldTag != null && oldTag.isNotEmpty && newTag != null && newTag.isNotEmpty && oldTag != newTag) {
        // Check if old tag is still being used by other looks
        bool isOldTagStillUsed = false;
        _lookTags.forEach((lookId, currentTag) {
          if (currentTag == oldTag && lookId != look.savedLookId) {
            isOldTagStillUsed = true;
          }
        });
        
        // If old tag is not used by any other look, remove it from available tags
        if (!isOldTagStillUsed) {
          _availableTags.remove(oldTag);
          _saveTags();
        }
      }
      
      // Update the tag
      if (newTag == null) {
        _lookTags.remove(look.savedLookId);
      } else {
        _lookTags[look.savedLookId] = newTag;
        
        // Add new tag to available tags if it doesn't exist
        if (!_availableTags.contains(newTag)) {
          _availableTags.add(newTag);
          _saveTags();
        }
      }
      
      look.tag = newTag;
      _markLookAsRecentlyAdded(look.savedLookId);
      _saveLookTags();
      _groupLooksByTag();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newTag == null 
          ? 'Tag removed from "${look.makeupLookName}"'
          : 'Tag updated to "$newTag" for "${look.makeupLookName}"'
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildLookCard(SavedLook look, double screenWidth, bool isSmallScreen) {
    final isRecentlyAdded = _isLookRecentlyAdded(look.savedLookId);
    final String? lookTag = _lookTags[look.savedLookId] ?? look.tag;
    
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          elevation: isRecentlyAdded ? 4 : 2,
          color: isRecentlyAdded ? Colors.pink[50] : Colors.white,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(screenWidth * 0.04),
                  ),
                  child: Stack(
                    children: [
                      _buildLookImage(look.savedLookId, screenWidth),
                      if (lookTag != null && lookTag.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lookTag,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? screenWidth * 0.025 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecentlyAdded)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? screenWidth * 0.025 : 10,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    Text(
                      look.makeupLookName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? screenWidth * 0.035 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Text(
                  look.formattedDate,
                  style: TextStyle(
                    fontSize: isSmallScreen ? screenWidth * 0.025 : 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.edit, size: isSmallScreen ? screenWidth * 0.04 : 16),
              onPressed: () => _showTagOptionsDialog(look),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? screenWidth * 0.06 : 24,
                minHeight: isSmallScreen ? screenWidth * 0.06 : 24,
              ),
              iconSize: isSmallScreen ? screenWidth * 0.04 : 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: isSmallScreen ? screenWidth * 0.07 : 28,
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
            height: isSmallScreen ? screenHeight * 0.08 : 60,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: Colors.black,
            size: isSmallScreen ? screenWidth * 0.06 : 24,
            ),
            onPressed: _toggleTagDropdown,
          ),
        ],
      ),
      backgroundColor: Colors.pinkAccent[50],
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_showTagDropdown) {
                setState(() {
                  _showTagDropdown = false;
                });
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    if (_selectedTag != 'All' && _selectedTag != 'All Looks' && _selectedTag != 'Tagged Looks')
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedTag,
                            style: TextStyle(
                              fontSize: isSmallScreen ? screenWidth * 0.07 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoadingAnimationWidget.staggeredDotsWave(
                                    color: Colors.pinkAccent,
                                    size: isSmallScreen ? 50 : 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Please wait a moment...',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? screenWidth * 0.04 : 16,
                                      color: Colors.pinkAccent[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                if (_currentImage != null)
                                  _buildImagePreview(_currentImage!, screenWidth),
                                Expanded(
                                  child: savedLooks.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No looks yet!',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? screenWidth * 0.045 : 18 * scaleFactor
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.025),
                                          child: CustomScrollView(
                                            slivers: _buildLooksDisplay(screenWidth, isSmallScreen),
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
          ),
          
          if (_showTagDropdown)
            Positioned(
              right: 16,
              top: kToolbarHeight - 35,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownItem('All Looks'),
                      Divider(height: 8, color: Colors.grey[200]),
                      _buildDropdownItem('Tagged Looks'),
                      Divider(height: 8, color: Colors.grey[200]),
                      ...(_availableTags.where((tag) => tag != 'All').toList()..sort()).map((tag) => 
                        Column(
                          children: [
                            _buildDropdownItem(tag),
                            if (tag != _availableTags.where((t) => t != 'All').last)
                              Divider(height: 8, color: Colors.grey[200]),
                          ],
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLooksDisplay(double screenWidth, bool isSmallScreen) {
    if (_selectedTag == 'All') {
      return _buildGroupedLooks(screenWidth, isSmallScreen);
    } else {
      return _buildFilteredLooks(screenWidth, isSmallScreen);
    }
  }

  List<Widget> _buildGroupedLooks(double screenWidth, bool isSmallScreen) {
    final List<Widget> slivers = [];
    
    final List<String> sectionOrder = ['All Looks', 'Tagged Looks'];
    
    final customTags = _groupedLooks.keys
        .where((tag) => tag != 'All Looks' && tag != 'Tagged Looks')
        .toList()..sort();
    
    final sortedTags = [...sectionOrder, ...customTags];
    
    for (var tag in sortedTags) {
      final looks = _groupedLooks[tag]!;
      if (looks.isNotEmpty) {
        String sectionTitle;
        if (tag == 'All Looks') {
          sectionTitle = 'All Photos';
        } else if (tag == 'Tagged Looks') {
          sectionTitle = 'Tagged Photos';
        } else {
          sectionTitle = tag;
        }
        
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: screenWidth * 0.04,
                bottom: screenWidth * 0.02,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
              ),
              child: Row(
                children: [
                  Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: isSmallScreen ? screenWidth * 0.05 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 3, 3, 3),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (looks.any((look) => _isLookRecentlyAdded(look.savedLookId)))
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${looks.where((look) => _isLookRecentlyAdded(look.savedLookId)).length} NEW',
                        style: TextStyle(
                          fontSize: isSmallScreen ? screenWidth * 0.025 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        
        slivers.add(
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (screenWidth > 600) ? 3 : 2,
              crossAxisSpacing: screenWidth * 0.02,
              mainAxisSpacing: screenWidth * 0.02,
              childAspectRatio: isSmallScreen ? 0.7 : 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final look = looks[index];
                return GestureDetector(
                  onTap: () => _navigateToLookDetails(look),
                  child: _buildLookCard(look, screenWidth, isSmallScreen),
                );
              },
              childCount: looks.length,
            ),
          ),
        );
      }
    }
    
    return slivers;
  }

  List<Widget> _buildFilteredLooks(double screenWidth, bool isSmallScreen) {
    List<SavedLook> filteredLooks;
    
    if (_selectedTag == 'All') {
      filteredLooks = savedLooks.where((look) {
        final String? lookTag = _lookTags[look.savedLookId] ?? look.tag;
        return lookTag == null || lookTag.isEmpty;
      }).toList();
    } else if (_selectedTag == 'All Looks') {
      filteredLooks = savedLooks.where((look) {
        final String? lookTag = _lookTags[look.savedLookId] ?? look.tag;
        return lookTag == null || lookTag.isEmpty;
      }).toList();
    } else if (_selectedTag == 'Tagged Looks') {
      filteredLooks = savedLooks.where((look) {
        final String? lookTag = _lookTags[look.savedLookId] ?? look.tag;
        return lookTag != null && lookTag.isNotEmpty;
      }).toList();
    } else {
      filteredLooks = savedLooks.where((look) {
        final String? lookTag = _lookTags[look.savedLookId] ?? look.tag;
        return lookTag == _selectedTag;
      }).toList();
    }

    filteredLooks.sort((a, b) {
      final bool aIsRecent = _isLookRecentlyAdded(a.savedLookId);
      final bool bIsRecent = _isLookRecentlyAdded(b.savedLookId);
      
      if (aIsRecent && !bIsRecent) {
        return -1;
      } else if (!aIsRecent && bIsRecent) {
        return 1;
      } else if (aIsRecent && bIsRecent) {
        return _recentlyAddedLooks[b.savedLookId]!.compareTo(_recentlyAddedLooks[a.savedLookId]!);
      } else {
        return b.capturedDate.compareTo(a.capturedDate);
      }
    });

    if (filteredLooks.isEmpty) {
      String emptyMessage;
      if (_selectedTag == 'All Looks') {
        emptyMessage = 'No untagged looks!';
      } else if (_selectedTag == 'Tagged Looks') {
        emptyMessage = 'No tagged looks';
      } else {
        emptyMessage = 'No looks with tag "$_selectedTag"';
      }
      
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                fontSize: isSmallScreen ? screenWidth * 0.045 : 18,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (screenWidth > 600) ? 3 : 2,
          crossAxisSpacing: screenWidth * 0.02,
          mainAxisSpacing: screenWidth * 0.02,
          childAspectRatio: isSmallScreen ? 0.7 : 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final look = filteredLooks[index];
            return GestureDetector(
              onTap: () => _navigateToLookDetails(look),
              child: _buildLookCard(look, screenWidth, isSmallScreen),
            );
          },
          childCount: filteredLooks.length,
        ),
      ),
    ];
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

            await _loadLocalImageForLook(look.savedLookId, prefs);
            await _fetchShadesForLook(look.savedLookId);
          } catch (e) {
            debugPrint('Error processing look ${lookData['saved_look_id']}: $e');
          }
        }

        loadedLooks.sort((a, b) => b.capturedDate.compareTo(a.capturedDate));

        setState(() {
          savedLooks = loadedLooks;
          isLoading = false;
          _groupLooksByTag();
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

  Future<void> _loadLocalImageForLook(int lookId, SharedPreferences prefs) async {
    try {
      final imageKey = 'look_image_$lookId';
      final cachedImage = prefs.getString(imageKey);
      
      if (cachedImage != null) {
        final imageBytes = base64Decode(cachedImage);
        setState(() {
          lookImages[lookId] = imageBytes;
        });
      } else {
        debugPrint('No local image found for look $lookId');
      }
    } catch (e) {
      debugPrint('Error loading local image for look $lookId: $e');
    }
  }

  Future<void> saveCurrentLook({
    required String lookName,
    required Map<String, List<String>> labeledShades,
    Uint8List? imageBytes,
    String? tag,
  }) async {
    try {
      String? imageData;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        imageData = 'data:image/png;base64,${base64Encode(imageBytes)}';
      }

      final response = await _saveLookToApi(
        userId: widget.userId,
        lookName: lookName,
        labeledShades: labeledShades,
        imageData: imageData,
        tag: tag,
      );

      if (response['success']) {
        if (response['look_id'] != null) {
          final lookId = int.parse(response['look_id'].toString());
          _markLookAsRecentlyAdded(lookId);
          
          if (imageBytes != null) {
            await _saveImageToLocalStorage(lookId, imageBytes);
          }
          
          final newLook = SavedLook(
            savedLookId: lookId,
            makeupLookName: lookName,
            capturedDate: DateTime.now(),
            tag: tag,
          );
          
          setState(() {
            savedLooks.insert(0, newLook);
            _groupLooksByTag();
          });

          if (imageBytes != null) {
            setState(() {
              lookImages[lookId] = imageBytes;
            });
          }
          
          await _fetchShadesForLook(lookId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Look saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to save look')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving look: $e')),
      );
    }
  }

  Future<void> _saveImageToLocalStorage(int lookId, Uint8List imageBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageKey = 'look_image_$lookId';
      final base64Image = base64Encode(imageBytes);
      await prefs.setString(imageKey, base64Image);
      
      setState(() {
        lookImages[lookId] = imageBytes;
      });
    } catch (e) {
      debugPrint('Error saving image to local storage: $e');
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
      }
    } catch (e) {
      debugPrint('Error loading shades for look $savedLookId: $e');
    }
  }

  void _navigateToLookDetails(SavedLook look) {
    final shades = lookShades[look.savedLookId] ?? {};
    final imageBytes = lookImages[look.savedLookId];

    _clearRecentlyAddedFlag(look.savedLookId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LookDetailsScreen(
          look: look,
          shades: shades,
          imageBytes: imageBytes,
          userId: widget.userId.toString(),
        ),
      ),
    );
  }

  Widget _buildLookImage(int lookId, double screenWidth) {
    final imageBytes = lookImages[lookId];
    
    if (imageBytes == null || imageBytes.isEmpty) {
      return _buildPlaceholder(screenWidth);
    }

    try {
      if (imageBytes.lengthInBytes < 100) {
        return _buildErrorPlaceholder(screenWidth);
      }
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.pinkAccent,
              size: screenWidth * 0.1,
            ),
            SizedBox(height: 12),
            Text(
              'Please wait a moment...',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.pinkAccent[700],
              ),
            ),
          ],
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
  final DateTime capturedDate;
  String? tag;

  SavedLook({
    required this.savedLookId,
    required this.makeupLookName,
    required this.capturedDate,
    this.tag,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    DateTime parseCapturedDate(dynamic date) {
      if (date == null) return DateTime.now();

      try {
        if (date is String) {
          try {
            return DateTime.parse(date).toLocal();
          } catch (e) {
            try {
              final dateParts = date.split(' ');
              if (dateParts.length >= 5) {
                final parseableDate = '${dateParts[1]} ${dateParts[2]} ${dateParts[3]} ${dateParts[4]}';
                return DateFormat('dd MMM yyyy HH:mm:ss').parse(parseableDate).toLocal();
              } else {
                debugPrint('Unexpected date format: $date');
                return DateTime.now().toLocal();
              }
            } catch (e2) {
              debugPrint('Failed to parse date string: $date');
              return DateTime.now().toLocal();
            }
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
      capturedDate: parseCapturedDate(json['created_at'] ?? json['saved_date'] ?? json['captured_date']),
      tag: json['tag'],
    );
  }

  String get formattedDate {
    return DateFormat('MMMM dd, yyyy').format(capturedDate);
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
    required this.userId,
  });

  @override
  State<LookDetailsScreen> createState() => _LookDetailsScreenState();
}

class _LookDetailsScreenState extends State<LookDetailsScreen> {
  String? _userFaceShape;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  bool _showTipsBox = false;
  String? _currentProductName;
  String? _currentTip;
  bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaceShape();
    // Simulate image loading delay
    if (widget.imageBytes != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isImageLoading = false;
          });
        }
      });
    } else {
      _isImageLoading = false;
    }
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
      _userFaceShape = prefs.getString('face_shape');
    });
  }

  void toggleTipsBox(String productName) {
    final tip = MakeupTipsGenerator.getTip(_userFaceShape!, productName);

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

      return GestureDetector(
        onTap: () => _showShadeVisualization(shade),
        child: Container(
          width: screenWidth * 0.08,
          height: screenWidth * 0.08,
          margin: EdgeInsets.only(right: screenWidth * 0.015),
          decoration: BoxDecoration(
            color: Color(colorValue),
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.black12,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Stack(
            children: [
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
        ),
      );
    } catch (e) {
      debugPrint('Error rendering shade: $e');
      return Container();
    }
  }

  void _showShadeVisualization(dynamic shade) {
    final hexCode = shade['hex_code']?.toString() ?? '';
    final shadeName = shade['shade_name']?.toString() ?? '';
    final shadeType = shade['shade_type']?.toString() ?? '';

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
                            color: _parseHexColor(hexCode),
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
                    
                    if (shadeName.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          shadeName.toUpperCase(),
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
                    ],
                    
                    if (shadeType.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          shadeType,
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

  Color _parseHexColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFFE5D0DA);
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

  List<Widget> _buildProductRows() {
    final productEntries = widget.shades.entries.toList();
    final List<Widget> rows = [];
    
    for (int i = 0; i < productEntries.length; i += 3) {
      final endIndex = i + 3 < productEntries.length ? i + 3 : productEntries.length;
      final rowProducts = productEntries.sublist(i, endIndex);
      
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.03),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowProducts.map((entry) {
              return Expanded(
                child: _buildProductCard(entry.key, entry.value is List ? entry.value : []),
              );
            }).toList(),
          ),
        ),
      );
    }
    
    return rows;
  }

  Widget _buildProductCard(String productName, List<dynamic> shades) {
    final selectedShade = shades.firstWhere(
      (shade) => shade['is_selected'] == true,
      orElse: () => null,
    );
    final isSmallScreen = screenWidth < 600;

    return GestureDetector(
      onTap: () => toggleTipsBox(productName),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? screenWidth * 0.035 : 14,
                fontFamily: 'PlayfairDisplay',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (selectedShade != null)
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.008, top: screenHeight * 0.005),
                child: Text(
                  'Selected: ${selectedShade['shade_name']}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? screenWidth * 0.03 : 12,
                    color: Colors.green[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            SizedBox(
              height: screenWidth * 0.09,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: shades.map((shade) => _buildShadeChip(shade)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final isSmallScreen = screenWidth < 600;
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.pinkAccent,
              size: isSmallScreen ? 40 : 50,
            ),
            SizedBox(height: 12),
            Text(
              'Please wait a moment...',
              style: TextStyle(
                fontSize: isSmallScreen ? screenWidth * 0.035 : 14,
                color: Colors.pinkAccent[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    final isSmallScreen = screenWidth < 600;
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? screenWidth * 0.1 : 40,
            ),
            Text(
              'No local image',
              style: TextStyle(
                color: Colors.red,
                fontSize: isSmallScreen ? screenWidth * 0.035 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage() {
    if (widget.imageBytes == null || widget.imageBytes!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
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

  @override
  Widget build(BuildContext context) {
    final safeScreenWidth =
        screenWidth > 0 ? screenWidth : MediaQuery.of(context).size.width;
    final safeScreenHeight =
        screenHeight > 0 ? screenHeight : MediaQuery.of(context).size.height;
    final scaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);
    final isSmallScreen = safeScreenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: isSmallScreen ? safeScreenWidth * 0.07 : 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: isSmallScreen ? safeScreenHeight * 0.08 : 60,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.lightbulb_outline,
              size: isSmallScreen ? safeScreenWidth * 0.06 : 24,
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
                    fontSize: isSmallScreen ? safeScreenWidth * 0.035 : 14 * scaleFactor,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: safeScreenHeight * 0.015),
                GestureDetector(
                  onTap: _showFullScreenImage,
                  child: SizedBox(
                    height: safeScreenHeight * 0.4,
                    width: double.infinity,
                    child: _isImageLoading
                        ? _buildPlaceholder()
                        : (widget.imageBytes != null
                            ? Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildErrorPlaceholder();
                                },
                              )
                            : _buildPlaceholder()),
                  ),
                ),
                SizedBox(height: safeScreenHeight * 0.025),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Type of makeup Look:',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: isSmallScreen ? safeScreenWidth * 0.04 : 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: safeScreenHeight * 0.005),
                      Text(
                        widget.look.makeupLookName,
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: isSmallScreen ? safeScreenWidth * 0.05 : 20 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: safeScreenHeight * 0.015),
                if (widget.shades.isNotEmpty) ...[
                  Text(
                    'Shades:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? safeScreenWidth * 0.05 : 20 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                  SizedBox(height: safeScreenHeight * 0.02),
                  ..._buildProductRows(),
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