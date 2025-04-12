import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/providers/homepage_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/screens/settings/appearance/theme_screen.dart';
import 'package:shonenx/screens/settings/appearance/ui_screen.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'dart:async';
import 'dart:developer' as dev;

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  double _loadingProgress = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle pulse animation for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);

    // Start with 0% progress
    _loadingProgress = 0.0;

    // Simulate loading progress up to 95%
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          if (_loadingProgress < 0.95) {
            _loadingProgress += 0.05;
          } else {
            timer.cancel();
          }
        });
      }
    });

    // Initialize app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      dev.log('Starting app initialization', name: 'LoadingScreen');

      // Get the selected provider key and custom API URL
      final selectedProviderState = ref.read(selectedProviderKeyProvider);
      final customApiUrl = selectedProviderState.customApiUrl;

      dev.log(
          'Selected provider: ${selectedProviderState.selectedProviderKey}, API URL: $customApiUrl',
          name: 'LoadingScreen');

      // Initialize with all required services
      await Future.wait([
        // Initialize anime source registry
        ref.read(animeSourceRegistryProvider.notifier).initialize(customApiUrl),

        // Initialize all settings
        ref.read(themeSettingsProvider.notifier).initializeSettings(),
        ref.read(uiSettingsProvider.notifier).initializeSettings(),
        ref.read(playerSettingsProvider.notifier).initializeSettings(),

        // Initialize homepage and watch progress
        ref.read(homePageProvider.future),
        AnimeWatchProgressBox().init(),

        // Force minimum delay for better UX
        Future.delayed(const Duration(seconds: 2)),
      ]);

      // Verify that the registry was initialized successfully
      final registryState = ref.read(animeSourceRegistryProvider);
      if (!registryState.registry.isInitialized) {
        throw Exception(
            'Failed to initialize anime source registry: ${registryState.error}');
      }

      dev.log('App initialization completed successfully',
          name: 'LoadingScreen');

      // Set progress to 100% when everything is loaded
      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
        });

        // Small delay to show the completed progress
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final uiSettings = ref.read(uiSettingsProvider).uiSettings;
      if (uiSettings.immersiveMode) {
        // Hide the status bar and navigation bar for immersive mode
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }

      // Navigate to the appropriate screen
      if (mounted) {
        final route = {
              'Home': '/',
              'Watchlist': '/watchlist',
              'Browse': '/browse',
            }[uiSettings.defaultTab] ??
            '/'; // Default to home if no match
        context.go(route);
      }
    } catch (e, stackTrace) {
      dev.log('Error during initialization: $e',
          name: 'LoadingScreen', error: e, stackTrace: stackTrace);
      if (mounted) {
        context.go('/error', extra: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle accent circles
            Positioned(
              top: -size.width * 0.2,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.05),
                      colorScheme.primary.withOpacity(0.0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.25,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withOpacity(0.05),
                      colorScheme.secondary.withOpacity(0.0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with subtle pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.12),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/app_icon-modified-2.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name
                  Text(
                    'ShonenX',
                    style: TextStyle(
                      color: colorScheme.onBackground,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Premium Anime Experience',
                    style: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Clean, minimal progress indicator
                  SizedBox(
                    width: size.width * 0.6,
                    child: Column(
                      children: [
                        // Progress bar
                        Stack(
                          children: [
                            // Background track
                            Container(
                              height: 4,
                              width: size.width * 0.6,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Animated progress
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              width: size.width * 0.6 * _loadingProgress,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Loading text with status
                        Text(
                          _loadingProgress < 1.0 ? 'Loading...' : 'Ready',
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
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
