import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/screens/settings/appearance/theme_screen.dart';
import 'package:shonenx/screens/settings/appearance/ui_screen.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'dart:async';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  bool _visible = true;
  double _opacity = 0.0;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

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

    // Initialize after delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithDelay();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWithDelay() async {
    try {
      // Initialize with a forced 5-second delay
      await Future.wait([
        // Actual initialization
        ref.read(themeSettingsProvider.notifier).initializeSettings(),
        ref.read(uiSettingsProvider.notifier).initializeSettings(),
        ref.read(playerSettingsProvider.notifier).initializeSettings(),
        AnimeWatchProgressBox().init(),

        // Force minimum 5 second delay
        Future.delayed(const Duration(seconds: 3)),
      ]);
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Text(
              'ShonenX',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
