import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'splash_screen.dart';
import 'profile_selection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugPaintLayerBordersEnabled = false;

  runApp(const GlamourApp());
}

class GlamourApp extends StatelessWidget {
  const GlamourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthDirect(), // Use AuthDirect instead of SplashScreen
    );
  }
}

class AuthDirect extends StatefulWidget {
  const AuthDirect({super.key});

  @override
  State<AuthDirect> createState() => _AuthDirectState();
}

class _AuthDirectState extends State<AuthDirect> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isCheckingAuth = true;
  Widget? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationDirect();
  }

  Future<void> _checkAuthenticationDirect() async {
    try {
      print("Direct authentication check...");
      
      // Check if user has a valid token and user ID
      final token = await _secureStorage.read(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      print("📱 Token: ${token != null ? 'Exists' : 'Missing'}");
      print("📱 User ID: ${userId ?? 'Missing'}");

      if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
        // Returning user - DIRECT to Profile Selection (no splash screen)
        print("Returning user, DIRECT to ProfileSelection");
        setState(() {
          _initialRoute = const ProfileSelection();
          _isCheckingAuth = false;
        });
      } else {
        // New user - go to Splash Screen (your existing flow)
        print("New user, going to SplashScreen");
        setState(() {
          _initialRoute = const SplashScreen();
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      print("Error during direct auth check: $e");
      // On error, go to splash screen
      setState(() {
        _initialRoute = const SplashScreen();
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return _buildQuickLoadingScreen();
    }

    return _initialRoute ?? const SplashScreen();
  }

  Widget _buildQuickLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/glam_logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}