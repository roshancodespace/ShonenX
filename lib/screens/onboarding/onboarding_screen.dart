import 'package:flutter/material.dart';
import 'package:nekoflow/routes/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  String _userName = '';
  final _nameController = TextEditingController();

  // List of onboarding steps
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Welcome to ShonenX!",
      "description": "Dive into the ultimate anime streaming experience.",
      "image": "lib/assets/images/onboarding/logo.png",
    },
    {
      "title": "Track Your Progress",
      "description": "Keep tabs on your favorite shows and episodes.",
      "image": "lib/assets/images/onboarding/luffy.png",
    },
  ];

  // Method to go to the next page
  void _nextPage() {
    if (_currentPage < onboardingData.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // After the last page, navigate to the AppRouter (Home screen) with the user's name
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(userName: _userName ),
        ),
      );
    }
  }

  // Method to go to the previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState((){
            _currentPage = index;
          });
        },
        itemCount: onboardingData.length + 1, // Add 1 for the name input page
        itemBuilder: (context, index) {
          if (index < onboardingData.length) {
            return OnboardingPage(
              title: onboardingData[index]['title']!,
              description: onboardingData[index]['description']!,
              image: onboardingData[index]['image']!,
            );
          } else {
            return NameInputPage(
              onUserNameChanged: (value) {
                setState(() {
                  _userName = value;
                });
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _currentPage > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, size: 40, color: Colors.white),
                    onPressed: _previousPage,
                  )
                : const SizedBox(width: 40),
            Row(
              children: List.generate(onboardingData.length + 1, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            _currentPage < onboardingData.length
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 40, color: Colors.white),
                    onPressed: _nextPage,
                  )
                : TextButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              image,
              // width: 300,
              // height: 200,
              // fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class NameInputPage extends StatefulWidget {
  final ValueChanged<String> onUserNameChanged;

  const NameInputPage({required this.onUserNameChanged});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Text(
            'Enter your name',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            onChanged: widget.onUserNameChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Your Name',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}