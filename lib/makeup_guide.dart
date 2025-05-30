import 'package:flutter/material.dart';
import 'profile_selection.dart';

class MakeupGuide extends StatefulWidget {
  final String userId;
  const MakeupGuide({super.key, required this.userId});

  @override
  _MakeupGuideState createState() => _MakeupGuideState();
}

class _MakeupGuideState extends State<MakeupGuide> {
  void _onProceed() {
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileSelection(userId: widget.userId)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Makeup Guide")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              Image.asset('assets/makeup_faceshapes.jpg', width: 550, height: 550),
              const SizedBox(height: 5),
              Image.asset('assets/eyeshadow.jpg', width: 550, height: 550),
              const SizedBox(height: 5),
              Image.asset('assets/guide_lips.jpg', width: 550, height: 550),

              // Move the button up
              Padding(
                padding: const EdgeInsets.only(top: 2), 
                child: SizedBox(
                  width: 130,
                  height: 45,
                  child: Material(
                    color: const Color.fromARGB(255, 239, 134, 169),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white.withOpacity(0.3),
                      onTap: _onProceed,
                      child: const Center(
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 243, 241, 242),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

