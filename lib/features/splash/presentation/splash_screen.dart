import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/app_init.dart';
import 'package:shonenx/features/onboarding/providers/onboarding_provider.dart';
import 'package:shonenx/features/splash/presentation/splash_quotes.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Setting up runtime environment...';
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late SplashQuote _currentQuote;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _currentQuote = SplashQuotes.getRandomQuote();
    _scheduleNextQuote();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();
    _initializeApp();
  }

  int _calculateReadingTime(String quote) {
    final msPerChar = quote.length * 40;
    return msPerChar.clamp(2800, 7000);
  }

  void _scheduleNextQuote() {
    _quoteTimer?.cancel();
    final durationMs = _calculateReadingTime(_currentQuote.quote);

    _quoteTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _currentQuote = SplashQuotes.getRandomQuote(_currentQuote);
        });
        _scheduleNextQuote();
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    final requiredReadingTime = _calculateReadingTime(_currentQuote.quote);

    try {
      await AppInit.setupBridge(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize bridge: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final remainingMs = requiredReadingTime - elapsedMs;

      if (remainingMs > 0) {
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      if (mounted) {
        setState(() {
          _status = 'Ready';
        });

        final pendingLink = AppInit.pendingDeepLink;
        if (pendingLink != null) {
          AppInit.pendingDeepLink = null;
          context.go(pendingLink);
        } else {
          final onboardingComplete = ref.read(onboardingProvider);
          if (onboardingComplete) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: SvgIcon(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 344 621" width="344" height="621"><g stroke-width="2" fill="none" stroke-linecap="butt"/><path d="M 159.2 515.84Q 166.12 520.83 167.49 521.49C 172.06 523.67 180.09 528.8 184.78 531.41Q 219.92 550.94 256.51 573.47A 1.26 1.25 -65 0 1 257.04 574.94C 255.87 578.46 254.22 582.5 252.75 585.21Q 244.45 600.59 237.19 614.43A 1.33 1.33 31.71 0 1 235.24 614.89C 227.06 608.94 218.45 604.55 210.01 599.29C 193.4 588.93 176.06 579.32 155.06 567.44Q 147.18 562.98 109.83 540.2C 97.04 532.4 86.29 526.57 73.9 519.4C 67.14 515.48 59.22 509.59 54.8 506.16Q 54.63 506.03 53.92 505.17A 0.91 0.91 67.15 0 1 54.52 503.69C 60.1 503.08 64.95 502.84 71.02 501.17Q 72.33 500.81 89.35 496.55Q 101.66 493.46 119.05 486.77Q 137.28 479.76 159.61 468.85Q 169.97 463.78 194.14 448.57Q 198.69 445.7 203.85 441.87C 219.98 429.89 235.19 416.97 246.26 404Q 250.1 399.5 260.39 386.16Q 280.24 360.41 289.24 329.69C 290.71 324.68 291.56 318.79 293.35 313.14A 0.5 0.49 88.01 0 0 292.7 312.53Q 290.93 313.24 289.53 314.32Q 275.18 325.41 259.57 331.8Q 253.98 334.09 246.22 336.73Q 239.58 339 232.5 340.59Q 212.63 345.05 192.01 345.14C 163.09 345.26 137.23 342.19 111.5 345.5Q 101.69 346.76 85.79 351.67C 80.44 353.33 73.16 356.98 69.08 359.11Q 63.45 362.04 54.21 367.96C 38.89 377.77 24.21 389.7 11.41 401.64A 0.81 0.8 -24.97 0 1 10.06 401.15Q 9.21 394.22 7.25 384.01C 5.72 376.06 5.82 365.35 5.83 356.96C 5.86 341.18 8.01 324.22 11.39 308.04Q 14.69 292.21 19.24 279.7C 22.19 271.57 25.72 262.08 29.61 254.31Q 32.87 247.81 35.45 242.42Q 39.76 233.38 50.97 216.26C 53.81 211.94 56.73 208.45 61.34 202.34Q 76.35 182.46 86.83 172.09Q 96.85 162.16 116.13 146.15Q 131.98 132.99 154.15 121.9Q 162.54 117.71 167.51 115.15Q 175.65 110.95 184.9 107.93A 0.32 0.32 54.25 0 0 184.99 107.37Q 182.33 105.39 178.73 103.35C 172.05 99.55 165.01 94.17 157.69 90.11Q 146.18 83.73 135.21 77.62Q 111.34 64.32 87.3 50.43Q 84.4 48.75 81.78 46.31A 0.63 0.62 -53.26 0 1 81.67 45.54Q 85.61 38.72 86.2 37.41Q 87.74 33.95 99.41 6.47A 1.75 1.74 27.99 0 1 101.97 5.69C 114.9 14.13 130.42 22.13 141.64 29.15C 151.11 35.08 168.97 44.59 182.1 52.6Q 190.98 58.01 199.78 62.68C 210.79 68.52 220.93 75.29 231.78 81.46Q 252.65 93.31 277 108.02Q 284.11 112.32 290.07 118.21A 0.91 0.91 47.25 0 1 290.02 119.55C 287.31 121.87 284.93 122.89 280.88 123.51Q 247.19 128.65 215.87 140.86Q 212.75 142.08 201.12 147.24C 181.62 155.89 163.5 166.89 146.05 179.81C 138.72 185.24 130.26 192.64 122.61 200.38C 114.38 208.71 105.26 217.66 97.8 227.79Q 83.36 247.43 73.61 265.09Q 64.38 281.83 59.62 297.32Q 54.45 314.15 54.24 315.49Q 53.81 318.24 53.72 319.52A 0.38 0.38 77.97 0 0 54.27 319.88Q 63.41 315.06 73.47 310.47Q 81.63 306.75 89.01 305.29Q 97.8 303.54 98.69 303.33Q 104.48 301.98 108.42 301.7C 113.46 301.34 123.39 299.54 130.57 299.45Q 149.37 299.21 168.51 300.3Q 184.06 301.19 199.89 300.28Q 217.38 299.27 230.8 295.3Q 255.83 287.87 275.41 273.42Q 297.99 256.74 317.97 233.19C 320.97 229.66 323.49 227 326.37 223.13Q 327.87 221.12 331.33 217.94A 0.78 0.78 40.63 0 1 332.29 217.87Q 333.59 218.76 334.03 220.38Q 337.96 234.72 338.76 240.26C 339.88 248.14 341.36 254.57 341.61 261.32Q 342.17 276.24 341.73 293.34Q 341.55 300.31 340.36 307.22Q 340.27 307.75 338.3 321.06Q 337.3 327.8 333.27 342.67Q 330.48 353.01 326 363.61Q 316.75 385.56 308.39 399.67Q 304.94 405.5 298.25 415.44Q 293.4 422.66 286.92 430.38Q 266.06 455.23 239.53 474.52Q 238.21 475.47 228.14 482.31C 214.59 491.51 200.62 498.95 184.69 505.92Q 176.14 509.67 169.38 511.59C 165.34 512.74 162.76 514.23 159.29 515.31A 0.3 0.3 -35.58 0 0 159.2 515.84Z" fill="#ff0000"/></svg>',
                        size: 140,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            color: cs.primary,
                            backgroundColor: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 4,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _status,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 440,
                          minHeight: 80,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey<String>(_currentQuote.quote),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '“${_currentQuote.quote}”',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurface.withOpacity(0.88),
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                      letterSpacing: 0.2,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '— ${_currentQuote.formattedAuthor}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: cs.primary.withOpacity(0.95),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
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
        ),
      ),
    );
  }
}
