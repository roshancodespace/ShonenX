import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
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

    final Widget backgroundContent;
    if (customBackgroundImagePath != null) {
      final img = Image.file(
        File(customBackgroundImagePath),
        fit: BoxFit.cover,
        color: theme.scaffoldBackgroundColor.withValues(
          alpha: (1.0 - backgroundImageOpacity).clamp(0.0, 1.0),
        ),
        colorBlendMode: BlendMode.srcOver,
      );

     if (backgroundBlur > 0.0) {
        backgroundContent = RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: backgroundBlur,
              sigmaY: backgroundBlur,
            ),
            child: img,
          ),
        );
      } else {
        backgroundContent = RepaintBoundary(child: img);
      }
    } else {
      backgroundContent = const SizedBox.shrink();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        decoration: BoxDecoration(
          color: (useGradients || customBackgroundImagePath != null)
              ? null
              : theme.scaffoldBackgroundColor,
          gradient: useGradients
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                )
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: backgroundContent),
            child,
            Positioned.fill(
              child: useNoiseOverlay
                  ? IgnorePointer(
                      child: StaticNoiseOverlay(
                        color: theme.colorScheme.onSurface,
                        opacity: noiseOpacity,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
