import 'package:flutter/material.dart';
import 'SignUpPage2.dart';

class SignUpPage1 extends StatefulWidget {
  const SignUpPage1({super.key});

  @override
  _SignUpPage1State createState() => _SignUpPage1State();
}

class _SignUpPage1State extends State<SignUpPage1> with SingleTickerProviderStateMixin {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  String? suffix;
  String? gender;

  late AnimationController _animationController;
  late Animation<double> animation;

  final List<String> suffixOptions = ['', 'Jr', 'Sr', 'II', 'III'];
  final List<String> genderOptions = ['Male', 'Female', 'Other']; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 16, now.month, now.day),
      firstDate: DateTime(1985),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 246, 67, 126),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  String _getApiDobFormat() {
    if (dobController.text.isEmpty) return '';
    final parts = dobController.text.split('/');
    if (parts.length != 3) return '';
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  String? _getApiGenderValue() {
    if (gender == null) return null;
    if (gender == 'Male') return 'male';
    if (gender == 'Female') return 'female';
    if (gender == 'Other') return 'other';
    return null;
  }

  void _navigateToNextPage() {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        dobController.text.isEmpty ||
        gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpPage2(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          suffix: suffix,
          dob: _getApiDobFormat(),
          gender: _getApiGenderValue(),
        ),
      ),
    );
  }

  void _handleGenderSelection(String selectedGender) {
    setState(() {
      gender = selectedGender;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildGenderOption(String genderOption) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            _handleGenderSelection(genderOption);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: gender == genderOption 
                ? _getGlitterColor(genderOption).withOpacity(0.1)
                : Colors.transparent,
            foregroundColor: gender == genderOption 
                ? _getGlitterColor(genderOption)
                : Colors.black,
            side: BorderSide(
              color: gender == genderOption 
                  ? _getGlitterColor(genderOption)
                  : Colors.grey.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            genderOption,
            style: TextStyle(
              fontSize: 14,
              fontWeight: gender == genderOption ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/frame3.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
                vertical: isSmallScreen ? 20.0 : screenHeight * 0.05,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isSmallScreen ? 40.0 : screenHeight * 0.05),
                  Image.asset(
                    'assets/glam_logo.png',
                    height: isSmallScreen ? 80.0 : screenHeight * 0.15,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20.0 : 30.0),
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Please fill to register',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20.0 : 24.0,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 7, 7, 7),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                        TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.person, color: Colors.pinkAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                        TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.person, color: Colors.pinkAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                        DropdownButtonFormField<String>(
                          value: suffix,
                          decoration: InputDecoration(
                            labelText: 'Suffix (Optional)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: suffixOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value.isEmpty ? null : value,
                              child: Text(value.isEmpty ? 'None' : value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              suffix = newValue;
                            });
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: Text(
                                'Gender *',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGenderOption('Male'),
                                const SizedBox(width: 8),
                                _buildGenderOption('Female'),
                                const SizedBox(width: 8),
                                _buildGenderOption('Other'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                        TextField(
                          controller: dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        SizedBox(height: isSmallScreen ? 32.0 : 40.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 246, 67, 126),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 16.0 : 20.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            minimumSize: const Size(double.infinity, 30),
                          ),
                          onPressed: _navigateToNextPage,
                          child: Text(
                            'Click to create your account',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isSmallScreen ? 16.0 : 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Color _getGlitterColor(String label) {
    switch (label) {
      case 'Male':
        return Colors.blueAccent;
      case 'Female':
        return Colors.pinkAccent;
      case 'Other':
        return Colors.purpleAccent;
      default:
        return Colors.pinkAccent;
    }
  }
}