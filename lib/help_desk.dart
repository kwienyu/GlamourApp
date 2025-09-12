import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class HelpDeskScreen extends StatefulWidget {
  const HelpDeskScreen({super.key});

  @override
  _HelpDeskScreenState createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen> {
  final TextEditingController _messageController = TextEditingController();
  File? _screenshot;
  bool _isSubmitting = false;
  String? _userId;
  String? _authToken;
  String? _cookies;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _authToken = prefs.getString('auth_token');
      _cookies = prefs.getString('cookies');
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _screenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final authToken = prefs.getString('auth_token');
      final cookies = prefs.getString('cookies');

      if (userId == null && authToken == null && cookies == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit a report')),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://glamouraika.com/api/submit-report'),
      );

      // Add form fields
      request.fields['message'] = _messageController.text;
      
      // Add user ID if available
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      // Add screenshot if selected
      if (_screenshot != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'screenshot',
            _screenshot!.path,
          ),
        );
      }

      // Add authorization header if using token-based auth
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Send cookies for session (if needed)
      if (cookies != null) {
        request.headers['Cookie'] = cookies;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        _messageController.clear();
        setState(() {
          _screenshot = null;
        });
      } else {
        try {
          final errorData = json.decode(responseBody);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Failed to submit report. Status: ${response.statusCode}')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}. Response: $responseBody')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color.fromARGB(255, 9, 9, 9),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white, // Changed from gradient to solid white
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.pink.shade200, // Changed from gradient to solid color
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 253, 89, 176).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent, 
                      size: 40, 
                      color: Colors.white
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your issue and we\'ll get back to you as soon as possible.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message Input
              const Text(
                'Describe your issue',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color.fromARGB(255, 9, 9, 9)
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Please provide details about the problem you\'re experiencing...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Screenshot Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attach a screenshot (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color.fromARGB(255, 9, 9, 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 9, 9, 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Color.fromARGB(255, 252, 100, 163), width: 1),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 18),
                        SizedBox(width: 6),
                        Text('Add File'),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_screenshot != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image, color: const Color.fromARGB(255, 249, 132, 186)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _screenshot!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.pink.shade200,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.pink.shade200),
                        onPressed: () {
                          setState(() {
                            _screenshot = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (_userId == null && _authToken == null && _cookies == null)) 
                    ? null 
                    : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade200.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.pink.shade200.withOpacity(0.9),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              if (_userId == null && _authToken == null && _cookies == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: Text(
                      'Please log in to submit a report',
                      style: TextStyle(
                        color: Colors.deepOrange.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // FAQ Section
              const Center(
                child: Text(
                  'FAQ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 253, 90, 180),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // FAQ Items
              _buildFAQItem(
                'What are the requirements for face scanning?',
                'For accurate analysis, please ensure:\n\n• No face accessories (glasses, masks, hats)\n• Face is bare with no heavy makeup\n• Well-lit environment\n• Face properly aligned within the frame\n• Head held straight and stable',
              ),
              _buildFAQItem(
                'How do I position my face for scanning?',
                'Align your face within the oblong-shaped frame on screen. Keep your head straight and centered. The color indicator will guide you:\n\n• White: No face detected\n• Red: Face too far or out of frame\n• Orange: Face detected but moving\n• Green: Perfect position - ready to capture',
              ),
              _buildFAQItem(
                'What face shapes does the system recognize?',
                'Our AI model identifies five face shapes:\n\n• Oval\n• Round\n• Square\n• Heart\n• Oblong\n\nYour results will be stored in your profile for future reference.',
              ),
              _buildFAQItem(
                'What skin tone categories are supported?',
                'We currently support three skin tone categories tailored for Filipino audiences:\n\n• Morena\n• Chinita\n• Mestiza\n\nYour skin tone analysis will be saved to your user profile.',
              ),
              _buildFAQItem(
                'Why is good lighting important?',
                'Proper lighting ensures accurate face shape and skin tone analysis. Poor lighting can cause:\n\n• Incorrect face shape detection\n• Inaccurate skin tone assessment\n• Failed image processing\n\nUse natural daylight or well-lit indoor spaces for best results.',
              ),
              _buildFAQItem(
                'What if the scanning fails repeatedly?',
                'If you experience repeated scanning failures:\n\n1. Check your lighting conditions\n2. Ensure no accessories are blocking your face\n3. Hold your device steady\n4. Follow the visual guide precisely\n5. If issues persist, submit a report with details using this help desk.',
              ),
              _buildFAQItem(
                'How is my data stored and used?',
                'Your face shape and skin tone analysis results are stored securely in your user profile. This data is used solely to provide personalized makeup recommendations and improve your experience. We do not share your facial data with third parties.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}