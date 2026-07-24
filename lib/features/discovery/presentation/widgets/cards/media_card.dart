import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';
import 'package:shonenx/shared/widgets/card/models/card_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaCard extends ConsumerWidget {
  final String title;
  final String tag;
  final String? format;
  final Widget? badge;
  final String imageUrl;
  final VoidCallback onTap;
  final MediaCardStyle style;
  final Map<String, dynamic>? config;
  final double? score;
  final String? subtitle;
  final String? year;
  final String? status;
  final List<String>? genres;

  const MediaCard({
    super.key,
    required this.title,
    required this.tag,
    this.format,
    this.badge,
    required this.imageUrl,
    required this.onTap,
    this.style = MediaCardStyle.classic,
    this.config,
    this.score,
    this.subtitle,
    this.year,
    this.status,
    this.genres,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiPrefsProvider);
    final isWideMode = uiState.isMediaCardWide(style.name);
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);

    return FocusHoverDetector(
      onTap: onTap,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      builder: (context, isFocused, isHovered) {
        final isActive = isFocused || isHovered;
        final baseLayout = style.getBaseLayout(isWideMode: isWideMode);
        final child = CardRenderer(
          style: style,
          config: CardConfig(
            width: baseLayout.width,
            height: baseLayout.height,
            isActive: isActive,
            isWideMode: isWideMode,
            title: title,
            imageUrl: imageUrl,
            heroTag: tag,
            badgeText: format,
            topRightBadge: badge,
            score: uiState.showCardRatings ? score : null,
            subtitle: subtitle,
            year: uiState.showCardYear ? year : null,
            status: status,
            genres: uiState.showCardGenres ? genres : null,
          ),
        );

        final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
        final scaleFactor = layout.width / baseLayout.width;
        final normalizedChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(currentTextScale / scaleFactor),
          ),
          child: child,
        );

        return SizedBox(
          width: layout.width,
          height: layout.height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: baseLayout.width,
              height: baseLayout.height,
              child: normalizedChild,
            ),
          ),
        );
      },
    );
  }
}
