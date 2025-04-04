import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/providers/homepage_provider.dart';
import 'package:shonenx/screens/settings/appearance/theme_screen.dart';
import 'package:shonenx/screens/settings/appearance/ui_screen.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'dart:async';
import 'dart:math' as math;

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  double _opacity = 0.0;
  double _loadingProgress = 0.0;
  Timer? _blinkTimer;
  Timer? _progressTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Animation controller for continuous animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start with fade in animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Create blinking effect for text
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          _visible = !_visible;
        });
      }
    });

    // Simulate loading progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (mounted) {
        setState(() {
          // Increase loading progress but cap at 95% until actual loading completes
          _loadingProgress = math.min(0.95, _loadingProgress + 0.05);
        });
      }
    });

    // Initialize after delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithDelay();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _progressTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWithDelay() async {
    try {
      // Initialize with a forced 10-second delay
      await Future.wait([
        // Actual initialization
        ref.read(themeSettingsProvider.notifier).initializeSettings(),
        ref.read(uiSettingsProvider.notifier).initializeSettings(),
        ref.read(playerSettingsProvider.notifier).initializeSettings(),
        ref.read(homePageProvider.future),
        AnimeWatchProgressBox().init(),

        // Force minimum 10 second delay
        // Future.delayed(const Duration(seconds: 20000)),
      ]);

      // Set progress to 100% when everything is loaded
      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
        });

        // Small delay to show the completed progress bar
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final uiSettings = ref.read(uiSettingsProvider).uiSettings;
      if (uiSettings.immersiveMode) {
        // Hide the status bar and navigation bar for immersive mode
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }

      // Fade out before navigation
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });

        // Wait for fade out animation
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          final route = {
                'Home': '/',
                'Watchlist': '/watchlist',
                'Browse': '/browse',
              }[uiSettings.defaultTab] ??
              '/'; // Default to home if no match
          context.go(route);
        }
      }
    } catch (e) {
      if (mounted) {
        context.go('/error', extra: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.3,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * math.pi,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(size.width * 0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -size.width * 0.4,
              left: -size.width * 0.2,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_animationController.value * 2 * math.pi,
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                            theme.colorScheme.secondary.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(size.width * 0.8),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 200),
                        child:
                            Image.asset('assets/icons/app_icon-modified-2.png'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App name
                  AnimatedOpacity(
                    opacity: _visible ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'ShonenX',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Your Anime, Your Way',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress indicator
                  SizedBox(
                    width: size.width * 0.7,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _loadingProgress,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading your anime world...',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
