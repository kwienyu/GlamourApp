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
  late Animation<double> _animation;

  final List<String> suffixOptions = ['', 'Jr', 'Sr', 'II', 'III'];
  final List<String> genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
    initialDate: DateTime(now.year - 16, now.month, now.day), // Changed from 12 to 16
    firstDate: DateTime(1985),
    lastDate: DateTime(now.year - 16, now.month, now.day), // Changed from 12 to 16
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
          dob: dobController.text,
          gender: gender,
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

  Widget _buildGenderCheckbox(String genderOption) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: gender == genderOption ? _animation.value : 1.0,
                  child: Checkbox(
                    value: gender == genderOption,
                    onChanged: (bool? selected) {
                      if (selected == true) {
                        _handleGenderSelection(genderOption);
                      }
                    },
                    activeColor: _getGlitterColor(genderOption),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: Colors.grey.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            genderOption,
            style: TextStyle(
              fontSize: 16,
              color: gender == genderOption 
                  ? _getGlitterColor(genderOption)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80), // Reduced from 80 to move content up
                  Image.asset(
                    'assets/glam_logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.only(top: 1), // Moved container up
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 7, 7, 7),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        'Gender',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black.withOpacity(0.6),
        ),
      ),
    ),
    Row(
      children: [
        _buildGenderCheckbox('Male'),
        const SizedBox(width: 20),
        _buildGenderCheckbox('Female'),
        const SizedBox(width: 20),
        _buildGenderCheckbox('other'),
      ],
    ),
  ],
),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 246, 67, 126),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            minimumSize: const Size(double.infinity, 30),
                          ),
                          onPressed: _navigateToNextPage,
                          child: const Text(
                            'Click to create your account',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
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
      case 'other':
        return Colors.purpleAccent;
      default:
        return Colors.pinkAccent;
    }
  }
}