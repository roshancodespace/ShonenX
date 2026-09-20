import 'package:flutter/widgets.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaCard extends ConsumerWidget {
  final UnifiedMedia media;
  final String tag;
  final VoidCallback onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final MediaCardStyle style;
  final Map<String, dynamic>? config;
  final String? subtitle;
  final double? progress;
  final String? progressText;
  final Widget? topLeftBadge;
  final Widget? topRightBadge;
  final Widget? bottomLeftBadge;
  final Widget? bottomRightBadge;
  final bool? forceWideMode;

  const MediaCard({
    super.key,
    required this.media,
    required this.tag,
    this.topLeftBadge,
    this.topRightBadge,
    this.bottomLeftBadge,
    this.bottomRightBadge,
    required this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.style = MediaCardStyle.classic,
    this.config,
    this.subtitle,
    this.progress,
    this.progressText,
    this.forceWideMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideMode =
        (forceWideMode ??
            ref.watch(
              uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
            )) ??
        false;
    final showRatings = ref.watch(
      uiPrefsProvider.select((s) => s.showCardRatings),
    );
    final showYear = ref.watch(uiPrefsProvider.select((s) => s.showCardYear));
    final showGenres = ref.watch(
      uiPrefsProvider.select((s) => s.showCardGenres),
    );
    final scale = ref.watch(themePrefsProvider.select((s) => s.uiScaleFactor));
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: AppFocusHover(
        onTap: onTap,
        onSecondaryTap: onSecondaryTap,
        onLongPress: onLongPress,
        builder: (context, isFocused, isHovered) {
          final isActive = isFocused || isHovered;
          final baseLayout = style.getBaseLayout(isWideMode: isWideMode);
          final child = CardRenderer(
            style: style,
            media: media,
            width: baseLayout.width,
            height: baseLayout.height,
            isActive: isActive,
            isWideMode: isWideMode,
            showRatings: showRatings,
            showYear: showYear,
            showGenres: showGenres,
            subtitle: subtitle,
            progress: progress,
            progressText: progressText,
            heroTag: tag,
            topLeftBadge: topLeftBadge,
            topRightBadge: topRightBadge,
            bottomLeftBadge: bottomLeftBadge,
            bottomRightBadge: bottomRightBadge,
          );

          final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
          final scaleFactor = layout.width / baseLayout.width;
          final normalizedChild = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(currentTextScale / scaleFactor),
            ),
            child: child,
          );

          return RepaintBoundary(
            child: AnimatedScale(
              scale: isActive ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: baseLayout.width,
                  height: baseLayout.height,
                  child: normalizedChild,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
