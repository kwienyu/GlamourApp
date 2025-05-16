import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _fetchSavedLooks();
  }

  Future<void> _fetchSavedLooks() async {
    try {
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/user/${widget.userId}/saved_looks'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          savedLooks = (data['saved_looks'] as List)
              .map((look) => SavedLook.fromJson(look))
              .toList();
          isLoading = false;
        });

        // Fetch shades for each look
        for (var look in savedLooks) {
          _fetchShadesForLook(look.savedLookId);
        }
      } else {
        throw Exception('Failed to load saved looks');
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

  Future<void> _fetchShadesForLook(int savedLookId) async {
    try {
      final response = await http.get(
        Uri.parse('https://glamouraika.com/api/saved_looks/$savedLookId/shades'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          lookShades[savedLookId] = data['shades'];
        });
      }
    } catch (e) {
      // Handle error quietly since this is secondary data
      debugPrint('Error loading shades for look $savedLookId: $e');
    }
  }

  void _navigateToLookDetails(SavedLook look) {
    final shades = lookShades[look.savedLookId] ?? {};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LookDetailsScreen(
          look: look,
          shades: shades,
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
          onPressed: () async {  // Marked this as async
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
                                        child: Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(Icons.photo_library,
                                                size: 50, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        look.makeupLookName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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

  SavedLook({
    required this.savedLookId,
    required this.makeupLookName,
  });

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    return SavedLook(
      savedLookId: json['saved_look_id'],
      makeupLookName: json['makeup_look_name'],
    );
  }
}

class LookDetailsScreen extends StatelessWidget {
  final SavedLook look;
  final Map<String, dynamic> shades;

  const LookDetailsScreen({
    super.key,
    required this.look,
    required this.shades,
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
            // Placeholder for look image - you might want to add this to your API
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.photo_library, size: 50),
              ),
            ),
            SizedBox(height: 20),
            Text('Shades:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...shades.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (entry.value as List).map((shade) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(int.parse(shade['hex_code'].substring(1, 7), radix: 16) + 0xFF000000),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.black12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}