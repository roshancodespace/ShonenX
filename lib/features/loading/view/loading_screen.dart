import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/loading/view_model/initialization_notifier.dart';
import 'package:shonenx/shared/providers/update_provider.dart';
import 'package:shonenx/utils/updater.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  // Quote rotation.
  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;

  bool _hasError = false;

  // Simple anime quotes
  static const List<String> _quotes = [
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

  @override
  void initState() {
    super.initState();
    AppLogger.d('Initializing LoadingScreen UI');

    _initializeAnimations();
    _startQuoteRotation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initializationProvider.notifier).initialize();
      if (!kDebugMode && ref.read(automaticUpdatesProvider)) {
        checkForUpdates(context);
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  void _startQuoteRotation() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_hasError) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    AppLogger.d('Disposing LoadingScreen');
    _quoteTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state
    final initState = ref.watch(initializationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Animate the progress bar to the current progress from the provider
    _progressController.animateTo(
      initState.progress,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    // Stop quotes on error
    if (initState.hasError && _quoteTimer?.isActive == true) {
      _quoteTimer?.cancel();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          _buildContent(colorScheme, size, theme, initState.status,
              initState.error.toString()),
          if (initState.hasError)
            _buildErrorOverlay(colorScheme, theme, initState.error.toString()),
        ],
      ),
    );
  }

  /// Builds the main content with enhanced visual design.
  Widget _buildContent(ColorScheme colorScheme, Size size, ThemeData theme,
      InitializationStatus status, String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundElements(colorScheme, size),
          _buildMainContent(colorScheme, size, theme, status),
          if (_hasError) _buildErrorOverlay(colorScheme, theme, message),
        ],
      ),
    );
  }

  /// Creates subtle background design elements.
  Widget _buildBackgroundElements(ColorScheme colorScheme, Size size) {
    return Stack(
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
    );
  }

  /// Creates a decorative accent circle with enhanced gradient.
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

  /// Builds the centered content with enhanced animations.
  Widget _buildMainContent(ColorScheme colorScheme, Size size, ThemeData theme,
      InitializationStatus status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEnhancedLogo(colorScheme),
            const SizedBox(height: 48),
            _buildAppInfo(colorScheme),
            const SizedBox(height: 24),
            _buildSimpleQuote(colorScheme),
            const SizedBox(height: 48),
            _buildProgressSection(colorScheme, size, status),
            const SizedBox(height: 32),
            _buildDebugInfo(colorScheme),
          ],
        ),
      ),
    );
  }

  /// Enhanced logo with better visual effects.
  Widget _buildEnhancedLogo(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icons/app_icon-modified-2.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.play_circle_filled,
                      size: 90,
                      color: colorScheme.primaryContainer,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// App name and tagline with better typography.
  Widget _buildAppInfo(ColorScheme colorScheme) {
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

  /// Simple anime quote display.
  Widget _buildSimpleQuote(ColorScheme colorScheme) {
    if (_hasError) return const SizedBox.shrink();

    return Text(
      _quotes[_currentQuoteIndex],
      style: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.8),
        fontSize: 14,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressSection(
      ColorScheme colorScheme, Size size, InitializationStatus status) {
    final initState =
        ref.watch(initializationProvider); // Get state for error check
    return SizedBox(
      width: size.width * 0.7,
      child: Column(
        children: [
          _buildProgressBar(colorScheme, size),
          const SizedBox(height: 20),
          Text(
            status == InitializationStatus.loadingHomepage
                ? 'Fetching anime data...'
                : status == InitializationStatus.applyingSettings
                    ? 'Applying settings...'
                    : status == InitializationStatus.success
                        ? 'Ready!'
                        : 'Initializing...',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: initState.hasError
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Enhanced progress bar with gradient.
  Widget _buildProgressBar(ColorScheme colorScheme, Size size) {
    return Container(
      height: 6,
      width: size.width * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                height: 6,
                width: size.width * 0.7 * _progressController.value,
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
      ),
    );
  }

  /// Debug information for development.
  Widget _buildDebugInfo(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Text(
          '${(_progressController.value * 100).toInt()}%',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        );
      },
    );
  }

  /// Error overlay with retry option.
  Widget _buildErrorOverlay(
      ColorScheme colorScheme, ThemeData theme, String errorMessage) {
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
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
                    child: const Text('Exit App'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _currentQuoteIndex = 0;
                      });
                      _progressController.reset();
                      _startQuoteRotation();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
