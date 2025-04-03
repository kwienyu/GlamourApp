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
  bool isLoading = false;

  Future<void> loginUser(BuildContext context) async {
  setState(() {
    isLoading = true; // Show loading effect
  });

  String apiUrl = 'https://glam.ivancarl.com/api/login';

  // Ensure email is in a standard format (trim + lowercase)
  String email = emailController.text.trim().toLowerCase();
  String password = passwordController.text.trim();

  try {
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    // Print response for debugging
    print("Response: ${response.statusCode} - ${response.body}");

    ScaffoldMessenger.of(context).clearSnackBars();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Ensure the response contains expected fields
      if (data.containsKey('user_id') && data.containsKey('email')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', data['email']);
        await prefs.setString('user_name', data['name']);
        await prefs.setInt('user_id', data['user_id']);

        print("✅ User ID: ${data['user_id']}, Name: ${data['name']}, Email: ${data['email']}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${data["name"]}!'),
            backgroundColor: const Color.fromARGB(255, 238, 148, 195),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSelection()),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected API response format.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      var errorMsg = jsonDecode(response.body)['message'] ?? 'Invalid email or password';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network Error: $e'),
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/glam_logo.png', height: 100),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
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
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 243, 133, 168),
                minimumSize: const Size(double.infinity, 50),
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
                      color: Color.fromARGB(255, 244, 156, 183),
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
