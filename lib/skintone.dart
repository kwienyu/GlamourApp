import 'package:flutter/material.dart';
import 'package:better_image_shadow/better_image_shadow.dart';


class SkinTone extends StatelessWidget {
  final String userId;
  const SkinTone({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 4, 4, 4)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Image.asset(
            'assets/glam_logo.png',
            height: MediaQuery.of(context).size.height * 0.10, 
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Image.asset(
                'assets/skin_toneicon.png',
                height: MediaQuery.of(context).size.height * 0.05,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SkinToneWidget(),
        ),
      ),
    );
  }
}

class SkinToneWidget extends StatefulWidget {
  const SkinToneWidget({super.key});

  @override
  SkinToneWidgetState createState() => SkinToneWidgetState();
}

class SkinToneWidgetState extends State<SkinToneWidget> {
  Map<String, String>? _selectedShape;
  int? _selectedIndex;
  final PageController _pageController = PageController();

  final skinTones = [
    {
      'icon': 'assets/morena_button.png',
      'image': 'assets/Morena-tone.jpg',
      'name': 'Morena Skin Tone',
      'description': 'Morena skin tones range from dark brown to warm brown. These shades include deep dark brown, medium brown, light brown, and warm brown. The tone is rich, earthy, and radiant, often with a naturally warm and vibrant appearance.'
    },
    {
      'icon': 'assets/mestiza_button.png',
      'image': 'assets/Mestiza-tone.jpg',
      'name': 'Mestiza Skin Tone',
      'description': 'Mestiza skin tones range from golden tan to light tan shades. This includes warm tones like golden, light golden, medium tan, warm tan, and light tan. The overall look is soft, sun-kissed, and naturally glowing with beige or golden undertones.'
    },
    {
      'icon': 'assets/chinita_button.png',
      'image': 'assets/Chinita-tone.jpg',
      'name': 'Chinita Skin Tone',
      'description': 'Chinita skin tones range from soft pink to pale beige. This includes light and delicate shades such as soft pink, light beige, and pale pink. The overall effect is smooth, bright, and fresh, often with cool or neutral undertones.'
    },
  ];

  void _onShapeTap(Map<String, String> shape, int index) {
    setState(() {
      _selectedShape = shape;
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedShape = skinTones[index];
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Dynamic sizing based on screen dimensions
        final bool isSmallScreen = screenWidth < 350;
        final bool isLargeScreen = screenWidth > 600;
        final bool isLandscape = screenWidth > screenHeight;
        
        // Responsive values
        final double basePadding = isSmallScreen ? 8.0 : 12.0;
        final double iconSize = isLandscape 
            ? screenHeight * 0.14
            : isLargeScreen 
                ? screenWidth * 0.14
                : screenWidth * 0.18;
        
        final double displayImageSize = isLandscape
            ? screenHeight * 0.4
            : screenWidth * 0.7;
        
        final double fontSizeTitle = isSmallScreen 
            ? screenWidth * 0.06 
            : screenWidth * 0.065;
        
        final double fontSizeName = isSmallScreen 
            ? screenWidth * 0.045 
            : screenWidth * 0.05;
        
        final double fontSizeDescription = isSmallScreen 
            ? screenWidth * 0.035 
            : screenWidth * 0.04;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Title Section
                Padding(
                  padding: EdgeInsets.all(basePadding * 1.5),
                  child: FadeTransitionWidget(
                    child: Column(
                      children: [
                        Text(
                          'Skin Tone Details',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: basePadding * 0.5),
                        Text(
                          'Swipe or tap the icon to explore different skin tones',
                          style: TextStyle(
                            fontSize: fontSizeDescription * 0.8,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: isLandscape ? screenHeight * 0.28 : screenHeight * 0.22,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: basePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: skinTones.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tone = entry.value;
                          final isSelected = index == _selectedIndex;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: basePadding),
                            child: GestureDetector(
                              onTap: () => _onShapeTap(tone, index),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon Container
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                              )
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              )
                                            ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(basePadding * 0.8),
                                      child: Image.asset(
                                        tone['icon']!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.face, color: Colors.grey);
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: basePadding),
                                  
                                  // Tone Name
                                  SizedBox(
                                    width: iconSize * 1.5,
                                    child: Text(
                                      tone['name']!.replaceAll(' Skin Tone', ''),
                                      style: TextStyle(
                                        fontSize: fontSizeName * 0.8,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.pinkAccent : Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _selectedShape != null
                      ? Column(
                          children: [
                            if (isLargeScreen || isLandscape) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: basePadding),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_selectedIndex! > 0)
                                      IconButton(
                                        icon: Icon(Icons.arrow_back_ios, color: Colors.pinkAccent),
                                        onPressed: () {
                                          _onShapeTap(skinTones[_selectedIndex! - 1], _selectedIndex! - 1);
                                        },
                                      )
                                    else
                                      SizedBox(width: 48),
                                    if (_selectedIndex! < skinTones.length - 1)
                                      IconButton(
                                        icon: Icon(Icons.arrow_forward_ios, color: Colors.pinkAccent),
                                        onPressed: () {
                                          _onShapeTap(skinTones[_selectedIndex! + 1], _selectedIndex! + 1);
                                        },
                                      )
                                    else
                                      SizedBox(width: 48),
                                  ],
                                ),
                              ),
                            ],
                            
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: _onPageChanged,
                                children: skinTones.map((tone) {
                                  return SingleChildScrollView(
                                    padding: EdgeInsets.all(basePadding * 2),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Image
                                        SizedBox(
                                          width: displayImageSize,
                                          height: displayImageSize,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: BetterImage(
                                              image: AssetImage(tone['image']!),
                                              width: displayImageSize,
                                              height: displayImageSize,
                                            ),
                                          ),
                                        ),
                                        
                                        // Reduced spacing between image and text
                                        SizedBox(height: basePadding),
                                        
                                        // Tone Name
                                        Text(
                                          tone['name']!,
                                          style: TextStyle(
                                            fontSize: fontSizeName,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        SizedBox(height: basePadding * 0.3),
                                        
                                        // Description - Now positioned closer to the image
                                        Container(
                                          width: displayImageSize,
                                          padding: EdgeInsets.symmetric(horizontal: basePadding * 0.5),
                                          child: Text(
                                            tone['description']!,
                                            style: TextStyle(
                                              fontSize: fontSizeDescription,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                        
                                        SizedBox(height: basePadding * 2),
                                        
                                        // Mobile Swipe Indicator
                                        if (!isLargeScreen && !isLandscape) 
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.swipe, color: Colors.grey, size: fontSizeDescription * 1.2),
                                              SizedBox(width: basePadding),
                                              Text(
                                                'Swipe to explore',
                                                style: TextStyle(
                                                  fontSize: fontSizeDescription * 0.9,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Padding(
                            padding: EdgeInsets.all(basePadding * 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: basePadding),
                                Text(
                                  'Select a face shape to view details',
                                  style: TextStyle(
                                    fontSize: fontSizeName,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FadeTransitionWidget extends StatefulWidget {
  final Widget child;

  const FadeTransitionWidget({super.key, required this.child});

  @override
  FadeTransitionWidgetState createState() => FadeTransitionWidgetState();
}

class FadeTransitionWidgetState extends State<FadeTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}