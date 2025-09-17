import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MakeupArtistForm extends StatefulWidget {
  final int userId;
  const MakeupArtistForm({super.key, required this.userId});
  
  @override
  _MakeupArtistFormState createState() => _MakeupArtistFormState();
}

class _MakeupArtistFormState extends State<MakeupArtistForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _certificationDetailsController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  XFile? _certificationFile;
  XFile? _workSample1;
  XFile? _workSample2;
  XFile? _workSample3;
  XFile? _faceImage;
  XFile? _idImage;
  
  bool _isIdVerified = false;
  bool _isVerifying = false;
  bool _isSubmitting = false;
  bool _isLoadingUserData = true;

  final String _baseUrl = 'https://glamouraika.com/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  try {
    setState(() {
      _isLoadingUserData = true;
    });

    final response = await http.get(
      Uri.parse('$_baseUrl/get_user_personal_info/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final userInfo = data['user_info'];
        setState(() {
          _firstNameController.text = userInfo['name'] ?? '';
          _lastNameController.text = userInfo['last_name'] ?? '';
          _aliasController.text = userInfo['alias'] ?? '';
          _suffixController.text = userInfo['suffix'] ?? '';
          _dobController.text = userInfo['dob'] != null 
              ? _formatDateFromApi(userInfo['dob']) 
              : '';
          _emailController.text = userInfo['email'] ?? '';
          _isLoadingUserData = false;
        });
      } else {
        setState(() {
          _isLoadingUserData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load user data')));
      }
    } else {
      setState(() {
        _isLoadingUserData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: ${response.statusCode}')));
    }
  } catch (e) {
    setState(() {
      _isLoadingUserData = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading user data: $e')));
    print('Error loading user data: $e');
  }
}

  String _formatDateFromApi(String apiDate) {
  try {
    if (apiDate.contains('-')) {
      final date = DateTime.parse(apiDate);
      return "${date.day}/${date.month}/${date.year}";
    }
    else if (apiDate.contains('/')) {
      return apiDate;
    }
    return apiDate;
  } catch (e) {
    return apiDate;
  }
}

 @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (_isLoadingUserData) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Center(
            child: Image.asset(
              'assets/glam_logo.png',
              height: screenHeight * 0.09,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: Image.asset(
              'assets/facscan_icon.gif',
              height: screenHeight * 0.05,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.pinkAccent,
        ),
      ),
    );
  }
  
  return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 10, 10, 10)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Center(
            child: Image.asset(
              'assets/glam_logo.png',
              height: screenHeight * 0.10,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: Image.asset(
              'assets/facscan_icon.gif',
              height: screenHeight * 0.05,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Text
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'If you want to apply as a Makeup Artist fill up this form',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              
              // Personal Information
              _buildSectionHeader('Personal Information', screenWidth),
              SizedBox(height: screenHeight * 0.02),
              
              // First Name
              _buildTextField(_firstNameController, 'First Name', screenWidth, isRequired: true),
              
              // Last Name and Suffix in a row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(_lastNameController, 'Last Name', screenWidth, isRequired: true),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_suffixController, 'Suffix (Optional)', screenWidth),
                  ),
                ],
              ),
              
              // Alias field
              _buildTextField(_aliasController, 'Alias (Professional Name)', screenWidth),
              
              // Date of Birth
              _buildDateField(_dobController, 'Date of Birth', screenWidth),
              
              SizedBox(height: screenHeight * 0.03),

              // Professional Information
              _buildSectionHeader('Professional Information', screenWidth),
              SizedBox(height: screenHeight * 0.02),
              _buildUploadField(
                'Upload Certifications',
                _certificationFile,
                () => _pickImage(ImageSource.gallery).then((file) {
                  setState(() => _certificationFile = file);
                }),
                screenWidth,
              ),
              _buildTextField(_certificationDetailsController, 'Certification Details (Optional)', screenWidth, maxLines: 2),
              
              SizedBox(height: screenHeight * 0.03),

              // Work Samples
              _buildSectionHeader('Work Samples', screenWidth),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Upload photos to prove you\'re a makeup artist',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildWorkSampleField('Work Sample 1', _workSample1, (file) {
                setState(() => _workSample1 = file);
              }, screenWidth),
              _buildWorkSampleField('Work Sample 2', _workSample2, (file) {
                setState(() => _workSample2 = file);
              }, screenWidth),
              _buildWorkSampleField('Work Sample 3', _workSample3, (file) {
                setState(() => _workSample3 = file);
              }, screenWidth),
              
              SizedBox(height: screenHeight * 0.03),

              // Contact Information
              _buildSectionHeader('Contact Information', screenWidth),
              SizedBox(height: screenHeight * 0.02),
              _buildTextField(_emailController, 'Email', screenWidth, 
                isRequired: true, keyboardType: TextInputType.emailAddress),
              _buildTextField(_socialMediaController, 'Social Media Account Name', screenWidth),
              
              SizedBox(height: screenHeight * 0.03),

              // ID Verification
_buildSectionHeader('ID Verification', screenWidth),
SizedBox(height: screenHeight * 0.02),
Center(
  child: Container(
    width: screenWidth * 0.9, // Expanded width
    padding: EdgeInsets.all(screenWidth * 0.04),
    decoration: BoxDecoration(
      color: Colors.pink[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.pinkAccent, width: 2), // Added pink border
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
      crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
      children: [
        Text(
          'Take two photos for ID verification:',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center, // Center text
        ),
        SizedBox(height: screenHeight * 0.02),
        
        // Face Photo
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '1. Take a photo of your face',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            if (_faceImage != null)
              Column(
                children: [
                  Stack(
                    children: [
                      Image.file(
                        File(_faceImage!.path),
                        height: screenHeight * 0.15,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _faceImage = null;
                              _isIdVerified = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _takePhoto(isFace: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(Icons.face, color: Colors.white, size: screenWidth * 0.04),
                label: Text(
                  _faceImage == null ? 'Take Face Photo' : 'Retake Face',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        // ID Photo
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '2. Take a photo of your valid ID',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            if (_idImage != null)
              Column(
                children: [
                  Stack(
                    children: [
                      Image.file(
                        File(_idImage!.path),
                        height: screenHeight * 0.15,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _idImage = null;
                              _isIdVerified = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _takePhoto(isFace: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(Icons.credit_card, color: Colors.white, size: screenWidth * 0.04),
                label: Text(
                  _idImage == null ? 'Take ID Photo' : 'Retake ID',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        // Verify Button
        if (_faceImage != null && _idImage != null && !_isIdVerified)
          Center(
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _verifyIdentity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: _isVerifying 
                  ? SizedBox(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(Icons.verified, color: Colors.white),
              label: Text(
                _isVerifying ? 'Verifying...' : 'Verify Identity',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        SizedBox(height: screenHeight * 0.01),
        
        // Verification Status
        if (_isIdVerified)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'ID verified successfully!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Submit Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIdVerified ? Colors.pinkAccent : Colors.grey,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isIdVerified && !_isSubmitting ? _submitForm : null,
                  child: _isSubmitting
                      ? SizedBox(
                          width: screenWidth * 0.04,
                          height: screenWidth * 0.04,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'SUBMIT APPLICATION',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double screenWidth) {
    return Text(
      title,
      style: TextStyle(
        fontSize: screenWidth * 0.05,
        fontWeight: FontWeight.bold,
        color: Colors.pink[800],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    double screenWidth, {
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pinkAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
          ),
          labelStyle: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: screenWidth * 0.04),
        validator: isRequired 
            ? (value) => value == null || value.isEmpty ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pinkAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
          ),
          suffixIcon: Icon(Icons.calendar_today, size: screenWidth * 0.05, color: Colors.pinkAccent),
          labelStyle: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        readOnly: true,
        style: TextStyle(fontSize: screenWidth * 0.04),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.pinkAccent,
                    onPrimary: Colors.white,
                    onSurface: Colors.pinkAccent,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          }
        },
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildUploadField(String label, XFile? file, VoidCallback onPressed, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.pink[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.pinkAccent),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    'Attach File',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (file != null) 
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.02),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      file.name,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _certificationFile = null;
                      });
                    },
                    child: Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkSampleField(String label, XFile? file, Function(XFile?) onFilePicked, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery).then((pickedFile) {
              if (pickedFile != null) {
                onFilePicked(pickedFile);
              }
            }),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink[300]!, width: 1),
                borderRadius: BorderRadius.circular(8),
                color: Colors.pink[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.add_a_photo, color: Colors.pinkAccent, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    file == null ? 'Upload Photo' : 'Change Photo',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (file != null) 
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.02),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      file.name,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  GestureDetector(
                    onTap: () {
                      if (label == 'Work Sample 1') {
                        setState(() => _workSample1 = null);
                      } else if (label == 'Work Sample 2') {
                        setState(() => _workSample2 = null);
                      } else if (label == 'Work Sample 3') {
                        setState(() => _workSample3 = null);
                      }
                    },
                    child: Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      return pickedFile;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')));
      return null;
    }
  }

  Future<void> _takePhoto({required bool isFace}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          if (isFace) {
            _faceImage = pickedFile;
          } else {
            _idImage = pickedFile;
          }
          _isIdVerified = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')));
    }
  }

   Future<void> _verifyIdentity() async {
    if (_faceImage == null || _idImage == null) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final faceImageBytes = await _faceImage!.readAsBytes();
      final idImageBytes = await _idImage!.readAsBytes();
      
      final faceBase64 = base64Encode(faceImageBytes);
      final idBase64 = base64Encode(idImageBytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/verify_identity'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_image': idBase64,
          'selfie_image': faceBase64,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _isVerifying = false;
          _isIdVerified = data['verified'] ?? false;
        });

        if (_isIdVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID verification successful!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Identity verification failed. Faces do not match.')));
        }
      } else {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Verification failed')));
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> certificates = [];
      List<String> works = [];

      if (_certificationFile != null) {
        final certBytes = await _certificationFile!.readAsBytes();
        certificates.add(base64Encode(certBytes));
      }

      if (_workSample1 != null) {
        final workBytes = await _workSample1!.readAsBytes();
        works.add(base64Encode(workBytes));
      }

      if (_workSample2 != null) {
        final workBytes = await _workSample2!.readAsBytes();
        works.add(base64Encode(workBytes));
      }

      if (_workSample3 != null) {
        final workBytes = await _workSample3!.readAsBytes();
        works.add(base64Encode(workBytes));
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/apply_makeup_artist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'known_as': _aliasController.text.isNotEmpty ? _aliasController.text : '${_firstNameController.text} ${_lastNameController.text}',
          'alias': _aliasController.text,
          'name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'suffix': _suffixController.text,
          'dob': _formatDateForApi(_dobController.text),
          'certificates': certificates,
          'works': works,
        }),
      );

      final data = json.decode(response.body);

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application submitted successfully!')));
        
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Submission failed')));
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: $e')));
    }
  }

  String _formatDateForApi(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
      return date;
    } catch (e) {
      return date;
    }
  }
}