import 'package:flutter/material.dart';
import 'selection_page.dart';

class UndertoneTutorial extends StatefulWidget {
  const UndertoneTutorial({super.key});

  @override
  _UndertoneTutorialState createState() => _UndertoneTutorialState();
}

class _UndertoneTutorialState extends State<UndertoneTutorial> {
  bool _isLoading = false; // Track loading state

  void _onProceed() {
    setState(() {
      _isLoading = true;
    });

    //effect for navigating
    Future.delayed(const Duration(seconds: 2), (){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectionPage()),
      );
      setState(() {
        _isLoading = false; 
      });
    });
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Undertone Tutorial")) ,
      body: Center(
        child:SingleChildScrollView(
          child: Column (
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left:10, top: 3),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color.fromARGB(255, 74, 194, 238), size: 20),
                    const SizedBox(width: 5),
                    const Text(
                      "Ensure proper lighting for accuracy",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Image.asset('assets/undertone.png', width: 550, height: 550),
                const SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onProceed,
                    style: ElevatedButton.styleFrom(
                       backgroundColor: const Color.fromARGB(255, 239, 134, 169),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                       ),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 237, 156, 190)),
                      )
                    : const Text(
                            'Proceed',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 243, 241, 242),
                          ),
                        ),
                    ),  
                  ),
              ] 
            ), 
          ), 
        ),
      );
    }
  }