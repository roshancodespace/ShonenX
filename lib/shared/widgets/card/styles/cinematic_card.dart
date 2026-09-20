import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class CinematicCard extends StatelessWidget {
  final UnifiedMedia media;
  final double width;
  final double height;
  final bool isActive;
  final bool isWideMode;
  final bool showRatings;
  final bool showYear;
  final bool showGenres;
  final String? subtitle;
  final double? progress;
  final String? progressText;
  final String? heroTag;
  final Widget? topLeftBadge;
  final Widget? topRightBadge;
  final Widget? bottomLeftBadge;
  final Widget? bottomRightBadge;

  const CinematicCard({
    super.key,
    required this.media,
    required this.width,
    required this.height,
    required this.isActive,
    required this.isWideMode,
    required this.showRatings,
    required this.showYear,
    required this.showGenres,
    this.subtitle,
    this.progress,
    this.progressText,
    this.heroTag,
    this.topLeftBadge,
    this.topRightBadge,
    this.bottomLeftBadge,
    this.bottomRightBadge,
    });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbWidth = width * 0.44;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Row(
          children: [
            Stack(
              children: [
                CardThumbnail(
                  media: media,
                  isActive: isActive,
                  progress: progress,
                  heroTag: heroTag,
                  width: thumbWidth,
                  height: height,
                  radiusOverride: GlobalUI.uiRoundness * 0.6,
                ),
                CardBadgeOverlay(
                  media: media,
                  styleName: 'cinematic',
                  isWideMode: isWideMode,
                  isActive: isActive,
                  showRatings: showRatings,
                  progress: progress,
                  progressText: progressText,
                  topLeftBadge: topLeftBadge,
      topRightBadge: topRightBadge,
      bottomLeftBadge: bottomLeftBadge,
      bottomRightBadge: bottomRightBadge,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: WideMetadataColumn(
                  media: media,
                  showRatings: showRatings,
                  showYear: showYear,
                  showGenres: showGenres,
                  subtitle: subtitle,
                  height: height,
                  progress: progress,
                  progressText: progressText,
                  topRightBadge: topRightBadge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
