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

    if (useNoiseOverlay && noiseOpacity > 0.0) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (useGradients || customBackgroundImagePath != null)
              ? null
              : theme.scaffoldBackgroundColor,
          gradient: useGradients && customBackgroundImagePath == null
              ? LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surfaceContainer,
                  ],
                )
              : null,
        ),
        child: content,
      ),
    );
  }
}
