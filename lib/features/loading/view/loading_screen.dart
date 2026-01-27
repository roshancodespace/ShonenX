import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/loading/view_model/initialization_notifier.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/shared/providers/update_provider.dart';
import 'package:shonenx/utils/updater.dart';

const List<String> _kAnimeQuotes = [
  '"Believe in yourself!" - Gurren Lagann',
  '"Hard work beats talent!" - Rock Lee',
  '"Never give up!" - Naruto',
  '"The future is now!" - One Piece',
  '"Dreams come true!" - Fairy Tail',
  '"The only limit is the one you set yourself." - My Hero Academia',
  '"Sometimes you have to do what you fear most." - Attack on Titan',
  '"Strive to be the best version of yourself!" - Demon Slayer',
  '"In our darkest hour, we find the strength to shine." - Bleach',
  '"Fight for what is right, no matter the cost." - Fullmetal Alchemist',
];

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.d('Initializing LoadingScreen UI');

    // Post-frame callback ensures context is available for checks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initializationProvider.notifier).initialize();

      if (!kDebugMode && ref.read(automaticUpdatesProvider)) {
        final useTest = ref.read(experimentalProvider).useTestReleases;
        checkForUpdates(context, useTestReleases: useTest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(initializationProvider, (previous, next) {
      // if (next.status == InitializationStatus.success) {
      // }
    });

    final initState = ref.watch(initializationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          const _BackgroundDecoration(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _PulsingLogo(),
                  const SizedBox(height: 48),
                  _AppTitle(colorScheme: colorScheme),
                  const SizedBox(height: 24),
                  if (!initState.hasError)
                    _QuoteRotator(colorScheme: colorScheme),
                  const SizedBox(height: 48),
                  _AnimatedProgressBar(
                    progress: initState.progress,
                    status: initState.status,
                    hasError: initState.hasError,
                  ),
                ],
              ),
            ),
          ),
          if (initState.hasError)
            _ErrorOverlay(
              errorMessage: initState.error.toString(),
              onRetry: () {
                ref.read(initializationProvider.notifier).initialize();
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-WIDGETS
// ---------------------------------------------------------------------------
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primaryContainer.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child, // Using the pre-built child for performance
          ),
        );
      },
      // The image is static, pass it as 'child' so it isn't rebuilt every frame
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icons/app_icon-modified-2.png',
            width: 90,
            height: 90,
            errorBuilder: (_, __, ___) => Icon(
              Icons.play_circle_filled,
              size: 90,
              color: colorScheme.primaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rotates quotes internally.
class _QuoteRotator extends StatefulWidget {
  final ColorScheme colorScheme;
  const _QuoteRotator({required this.colorScheme});

  @override
  State<_QuoteRotator> createState() => _QuoteRotatorState();
}

class _QuoteRotatorState extends State<_QuoteRotator> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % _kAnimeQuotes.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _kAnimeQuotes[_index],
        key: ValueKey<int>(_index),
        style: TextStyle(
          color: widget.colorScheme.onSurface.withOpacity(0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Handles progress bar animation implicitly.
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final InitializationStatus status;
  final bool hasError;

  const _AnimatedProgressBar({
    required this.progress,
    required this.status,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: hasError
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(InitializationStatus status) {
    switch (status) {
      case InitializationStatus.loadingHomepage:
        return 'Fetching anime data...';
      case InitializationStatus.applyingSettings:
        return 'Applying settings...';
      case InitializationStatus.success:
        return 'Ready!';
      default:
        return 'Initializing...';
    }
  }
}

// ---------------------------------------------------------------------------
// STATIC DECORATIONS (CONST)
// ---------------------------------------------------------------------------
class _AppTitle extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AppTitle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ShonenX',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Premium Anime Experience',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Totally static background.
/// Extracted to ensure it is only built once and never repainted during updates.
class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context); // Faster than MediaQuery.of

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerLowest],
        ),
      ),
      child: Stack(
        children: [
          _buildAccentCircle(
            top: -size.width * 0.15,
            right: -size.width * 0.15,
            color: colorScheme.primaryContainer,
            size: size.width * 0.4,
          ),
          _buildAccentCircle(
            bottom: -size.width * 0.2,
            left: -size.width * 0.1,
            color: colorScheme.secondary,
            size: size.width * 0.35,
          ),
          _buildAccentCircle(
            top: size.height * 0.3,
            right: -size.width * 0.3,
            color: colorScheme.tertiary,
            size: size.width * 0.25,
          ),
        ],
      ),
    );
  }

  Widget _buildAccentCircle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.03),
              color.withOpacity(0.0),
            ],
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorOverlay({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text('Exit'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
