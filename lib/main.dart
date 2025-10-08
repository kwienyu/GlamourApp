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
      home: AuthDirect(), 
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

      final token = await _secureStorage.read(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
        setState(() {
          _initialRoute = const ProfileSelection();
          _isCheckingAuth = false;
        });
      } else {
        setState(() {
          _initialRoute = const SplashScreen();
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
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