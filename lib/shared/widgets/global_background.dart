import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/static_noise_overlay.dart';

class GlobalBackground extends ConsumerWidget {
  final Widget child;

  const GlobalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useGradients = ref.watch(
      themePrefsProvider.select((p) => p.useGradients),
    );
    final useAmoled = ref.watch(themePrefsProvider.select((p) => p.useAmoled));
    final customBackgroundImagePath = ref.watch(
      themePrefsProvider.select((p) => p.customBackgroundImagePath),
    );
    final useNoiseOverlay = ref.watch(
      themePrefsProvider.select((p) => p.useNoiseOverlay),
    );
    final noiseOpacity = ref.watch(
      themePrefsProvider.select((p) => p.noiseOpacity),
    );
    final backgroundBlur = ref.watch(
      themePrefsProvider.select((p) => p.backgroundBlur),
    );
    final backgroundImageOpacity = ref.watch(
      themePrefsProvider.select((p) => p.backgroundImageOpacity),
    );

    final gradientStyle = ref.watch(
      themePrefsProvider.select((p) => p.gradientStyle),
    );
    final gradientDirection = ref.watch(
      themePrefsProvider.select((p) => p.gradientDirection),
    );
    final gradientColorPair = ref.watch(
      themePrefsProvider.select((p) => p.gradientColorPair),
    );
    final gradientIntensity = ref.watch(
      themePrefsProvider.select((p) => p.gradientIntensity),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    final List<Widget> backgroundLayers = [];

    if (customBackgroundImagePath != null) {
      final img = Image.file(
        File(customBackgroundImagePath),
        fit: BoxFit.cover,
        color: theme.scaffoldBackgroundColor.withValues(
          alpha: (1.0 - backgroundImageOpacity).clamp(0.0, 1.0),
        ),
        colorBlendMode: BlendMode.srcOver,
      );

      final Widget bgImg = backgroundBlur > 0.0
          ? RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: backgroundBlur,
                  sigmaY: backgroundBlur,
                ),
                child: img,
              ),
            )
          : RepaintBoundary(child: img);

      backgroundLayers.add(Positioned.fill(child: bgImg));
    }

    if (useNoiseOverlay && noiseOpacity > 0.0 && !(isDark && useAmoled)) {
      backgroundLayers.add(
        Positioned.fill(
          child: IgnorePointer(
            child: StaticNoiseOverlay(
              color: theme.colorScheme.onSurface,
              opacity: noiseOpacity,
            ),
          ),
        ),
      );
    }

    final Widget content = backgroundLayers.isEmpty
        ? child
        : Stack(children: [...backgroundLayers, child]);

    final isAmoledActive =
        isDark && useAmoled && customBackgroundImagePath == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isAmoledActive
              ? const Color(0xFF000000)
              : ((useGradients || customBackgroundImagePath != null)
                    ? null
                    : theme.scaffoldBackgroundColor),
          gradient:
              (!isAmoledActive &&
                  useGradients &&
                  customBackgroundImagePath == null)
              ? _buildBackgroundGradient(
                  theme: theme,
                  style: gradientStyle,
                  direction: gradientDirection,
                  colorPair: gradientColorPair,
                  intensity: gradientIntensity,
                )
              : null,
        ),
        child: content,
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
      default:
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
          default:
            begin = Alignment.bottomLeft;
            end = Alignment.topRight;
        }
        return LinearGradient(begin: begin, end: end, colors: colors);
    }
  }
}
