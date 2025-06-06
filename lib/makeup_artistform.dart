import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MakeupArtistForm extends StatefulWidget {
  final int userId;
  const MakeupArtistForm({super.key, required this.userId});
  
  @override
  _MakeupArtistFormState createState() => _MakeupArtistFormState();
}

class _MakeupArtistFormState extends State<MakeupArtistForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationsController = TextEditingController();
  final TextEditingController _certificationsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  XFile? _idImage;
  XFile? _certificateImage;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Center(
          child: Image.asset(
            'assets/glam_logo.png',
            height: screenHeight * 0.10,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true, // Ensures title is centered
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information
                  _buildSectionHeader('Personal Information', screenWidth),
                  _buildTextField(_fullNameController, 'Full Name', screenWidth, isRequired: true),
                  _buildDateField(_dobController, 'Date of Birth', screenWidth),
                  
                  // ID Verification
                  _buildUploadField(
                    'Upload Valid Government ID',
                    _idImage,
                    () => _pickImage(ImageSource.gallery).then((file) {
                      setState(() => _idImage = file);
                    }),
                    screenWidth,
                  ),

                  // Professional Information
                  _buildSectionHeader('Professional Information', screenWidth),
                  _buildTextField(_experienceController, 'Years of Experience', screenWidth, keyboardType: TextInputType.number),
                  _buildTextField(_specializationsController, 'Specializations (e.g., bridal, editorial)', screenWidth),
                    
                  _buildUploadField(
                    'Upload Certifications',
                    _certificateImage,
                    () => _pickImage(ImageSource.gallery).then((file) {
                      setState(() => _certificateImage = file);
                    }),
                    screenWidth,
                  ),
                  
                  _buildTextField(_certificationsController, 'Certification Details', screenWidth),

                  // Contact Information
                  _buildSectionHeader('Contact Information', screenWidth),
                  _buildTextField(_phoneController, 'Phone Number', screenWidth, isRequired: true, keyboardType: TextInputType.phone),
                  _buildTextField(_emailController, 'Email Address', screenWidth, isRequired: true, keyboardType: TextInputType.emailAddress),
                  _buildTextField(_socialMediaController, 'Social Media Links (optional)', screenWidth),

                  // Submit Button
                  SizedBox(height: screenHeight * 0.04), // 4% of screen height
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1, // 10% of screen width
                          vertical: screenHeight * 0.02, // 2% of screen height
                        ),
                      ),
                      onPressed: _submitForm,
                      child: Text(
                        'SUBMIT APPLICATION',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045, // 4.5% of screen width
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04), // 4% of screen height
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04), // 4% of screen width
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.045, // 4.5% of screen width
          fontWeight: FontWeight.bold,
          color: Colors.pinkAccent,
        ),
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
      padding: EdgeInsets.only(bottom: screenWidth * 0.04), // 4% of screen width
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
        validator: isRequired 
            ? (value) => value == null || value.isEmpty ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04), // 4% of screen width
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, size: screenWidth * 0.05), // 5% of screen width
          labelStyle: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
        ),
        readOnly: true,
        style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
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
      padding: EdgeInsets.only(bottom: screenWidth * 0.04), // 4% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
          ),
          SizedBox(height: screenWidth * 0.02), // 2% of screen width
          OutlinedButton(
            onPressed: onPressed,
            child: Text(
              'Select File',
              style: TextStyle(fontSize: screenWidth * 0.035), // 3.5% of screen width
            ),
          ),
          if (file != null) 
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.02), // 2% of screen width
              child: Text(
                file.name,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: screenWidth * 0.035, // 3.5% of screen width
                ),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form submitted successfully!')));
      
      // Collect all form data
      Map<String, dynamic> formData = {
        'fullName': _fullNameController.text,
        'dob': _dobController.text,
        'professionalInfo': {
          'experience': _experienceController.text,
          'specializations': _specializationsController.text,
          'certifications': _certificationsController.text,
        },
        'contactInfo': {
          'phone': _phoneController.text,
          'email': _emailController.text,
          'socialMedia': _socialMediaController.text,
        },
      };
      
      print(formData); // For debugging
    }
  }
}