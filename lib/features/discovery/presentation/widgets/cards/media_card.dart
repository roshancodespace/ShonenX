import 'package:flutter/widgets.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
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
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
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
    this.onSecondaryTap,
    this.onLongPress,
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
    final isWideMode = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
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
              score: showRatings ? score : null,
              subtitle: subtitle,
              year: showYear ? year : null,
              status: status,
              genres: showGenres ? genres : null,
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
