import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/user_box.dart';
import 'package:nekoflow/routes/app_router.dart';
import 'package:nekoflow/screens/onboarding/loading_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  String name = '';
  late UserBox _userBox;
  bool _isLoading = true;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Welcome to ShonenX",
      "description": "Your gateway to endless anime adventures",
      "image": "lib/assets/images/onboarding/logo.png",
    },
    {
      "title": "Discover New Worlds",
      "description": "Explore thousands of anime series and movies",
      "image": "lib/assets/images/onboarding/home.png",
    },
    {
      "title": "Track Your Journey",
      "description":
          "Keep track of your watchlist and continue where you left off",
      "image": "lib/assets/images/onboarding/watchlist.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeBoxAndCheckStatus();
  }

  Future<void> _initializeBoxAndCheckStatus() async {
    try {
      _userBox = UserBox();
      await _userBox.init();

      final user = _userBox.getUser();
      debugPrint(user.name);

      if (user.name != null && mounted) {
        // If onboarding is completed, navigate to AppRouter
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AppRouter(name: user.name ?? ''),
          ),
        );
      } else {
        // If onboarding is not completed, show onboarding screens
        setState(() {
          _isLoading = false;
          if (user.name != null) {
            name = user.name!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    if (name.trim().isEmpty) return;

    try {
      await _userBox.updateUser(name: name.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppRouter(name: name.trim()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save user data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: onboardingData.length + 1,
          itemBuilder: (context, index) {
            if (index < onboardingData.length) {
              return _buildOnboardingPage(index);
            }
            return _buildNameInputPage();
          },
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildOnboardingPage(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              onboardingData[index]['image']!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            onboardingData[index]['title']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            onboardingData[index]['description']!,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildNameInputPage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "What should we call you?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Enter your name to personalize your experience",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            onChanged: (value) => setState(() => name = value),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              hintText: 'Name',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              onboardingData.length + 1,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed:
                name.trim().isNotEmpty || _currentPage < onboardingData.length
                    ? _nextPage
                    : null,
            child: Text(
              _currentPage < onboardingData.length ? 'Next' : 'Get Started',
              style: TextStyle(
                fontSize: 18,
                color: (name.trim().isNotEmpty ||
                        _currentPage < onboardingData.length)
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
