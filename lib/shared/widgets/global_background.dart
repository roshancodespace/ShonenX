import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/static_noise_overlay.dart';

class GlobalBackground extends StatelessWidget {
  final Widget child;

  const GlobalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _GlobalBackgroundSurface()),
          child,
        ],
      ),
    );
  }
}

class _GlobalBackgroundSurface extends ConsumerWidget {
  const _GlobalBackgroundSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final useGradients = themePrefs.useGradients;
    final useAmoled = themePrefs.useAmoled;
    final customBackgroundImagePath = themePrefs.customBackgroundImagePath;
    final processedWallpaperPath = themePrefs.wallpaperSettings?.processedPath;
    final backgroundImageOpacity = themePrefs.backgroundImageOpacity;
    final useNoiseOverlay = themePrefs.useNoiseOverlay;
    final noiseOpacity = themePrefs.noiseOpacity;

    final isAmoledActive =
        isDark && useAmoled && customBackgroundImagePath == null;

    final gradient =
        (!isAmoledActive && useGradients && customBackgroundImagePath == null)
        ? _buildBackgroundGradient(
            theme: theme,
            style: themePrefs.gradientStyle,
            direction: themePrefs.gradientDirection,
            colorPair: themePrefs.gradientColorPair,
            intensity: themePrefs.gradientIntensity,
          )
        : null;

    final backgroundColor = isAmoledActive
        ? const Color(0xFF000000)
        : (gradient != null || customBackgroundImagePath != null
              ? null
              : theme.scaffoldBackgroundColor);

    final imagePathToRender =
        processedWallpaperPath ?? customBackgroundImagePath;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor, gradient: gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePathToRender != null && imagePathToRender.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: backgroundImageOpacity.clamp(0.0, 1.0),
                  child: _WallpaperImage(imagePath: imagePathToRender),
                ),
              ),
            if (useNoiseOverlay && noiseOpacity > 0.0 && !isAmoledActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: StaticNoiseOverlay(
                    color: theme.colorScheme.onSurface,
                    opacity: noiseOpacity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Gradient? _buildBackgroundGradient({
    required ThemeData theme,
    required BackgroundGradientStyle style,
    required BackgroundGradientDirection direction,
    required BackgroundGradientColorPair colorPair,
    required double intensity,
  }) {
    final cs = theme.colorScheme;
    final base = theme.scaffoldBackgroundColor;
    final alpha = intensity.clamp(0.05, 1.0);

    final primaryBlend = Color.alphaBlend(
      cs.primary.withValues(alpha: alpha),
      base,
    );
    final secondaryBlend = Color.alphaBlend(
      cs.secondary.withValues(alpha: alpha),
      base,
    );
    final tertiaryBlend = Color.alphaBlend(
      cs.tertiary.withValues(alpha: alpha * 0.8),
      base,
    );
    final surfaceBlend = Color.alphaBlend(
      cs.surfaceContainerHighest.withValues(alpha: alpha),
      base,
    );

    final List<Color> colors;
    switch (colorPair) {
      case BackgroundGradientColorPair.primaryInfused:
        colors = [base, primaryBlend];
      case BackgroundGradientColorPair.secondaryInfused:
        colors = [base, secondaryBlend];
      case BackgroundGradientColorPair.vibrantMix:
        colors = [base, primaryBlend, tertiaryBlend];
      case BackgroundGradientColorPair.surfaceContainer:
        colors = [base, surfaceBlend];
    }

    switch (style) {
      case BackgroundGradientStyle.radial:
        return RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: colors.reversed.toList(),
        );
      case BackgroundGradientStyle.topGlow:
        return RadialGradient(
          center: const Alignment(0.0, -1.3),
          radius: 1.5,
          colors: colors.reversed.toList(),
        );
      case BackgroundGradientStyle.sweep:
        return SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 6.28318530718,
          colors: [colors.first, ...colors.skip(1), colors.first],
        );
      case BackgroundGradientStyle.linear:
        final Alignment begin;
        final Alignment end;
        switch (direction) {
          case BackgroundGradientDirection.diagonalDown:
            begin = Alignment.topLeft;
            end = Alignment.bottomRight;
          case BackgroundGradientDirection.vertical:
            begin = Alignment.topCenter;
            end = Alignment.bottomCenter;
          case BackgroundGradientDirection.horizontal:
            begin = Alignment.centerLeft;
            end = Alignment.centerRight;
          case BackgroundGradientDirection.diagonalUp:
            begin = Alignment.bottomLeft;
            end = Alignment.topRight;
        }
        return LinearGradient(begin: begin, end: end, colors: colors);
    }
  }
}

class _WallpaperImage extends StatelessWidget {
  final String imagePath;

  const _WallpaperImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        key: ValueKey(imagePath),
        imageUrl: imagePath,
        fit: BoxFit.cover,
        memCacheWidth: 1080,
        maxWidthDiskCache: 1920,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return Image.file(
      File(imagePath),
      key: ValueKey(imagePath),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
