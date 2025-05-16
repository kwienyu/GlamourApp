import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_selection.dart';
import 'signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // Added state for loading effect
  bool _obscurePassword = true; // State for password visibility toggle

  Future<void> loginUser(BuildContext context) async {
    setState(() {
      isLoading = true; // Show loading effect
    });

    String apiUrl = 'https://glamouraika.com/api/login';

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      ScaffoldMessenger.of(context).clearSnackBars();
      print('Raw response: ${response.body}');

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') == true) {
          var responseData = jsonDecode(response.body);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', responseData['user_id'].toString());
          await prefs.setString('user_email', responseData['email']);
          print("✅ Saved user_id: ${responseData['user_id']}, email: ${responseData['email']}");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: const Color.fromARGB(255, 238, 148, 195),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate after slight delay
          Future.delayed(const Duration(seconds: 1), () async {  // Added async here
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id') ?? '';
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileSelection(userId: userId)),
            );
          });
        } else {
          // Handle non-JSON successful response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server error: Unexpected response format.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading effect
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/glam_logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.4),
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.4),
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 246, 67, 126).withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isLoading ? null : () => loginUser(context),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Log in',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Color.fromARGB(255, 241, 125, 158),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
