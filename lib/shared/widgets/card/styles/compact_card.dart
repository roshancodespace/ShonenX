import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class CompactCard extends StatelessWidget {
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

  const CompactCard({
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
    if (isWideMode) {
      return _buildWide(theme);
    }
    return _buildPortrait(theme);
  }

  Widget _buildPortrait(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * 0.75;

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
              : cs.outlineVariant.withValues(alpha: 0.15),
          width: isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CardThumbnail(
                media: media,
                isActive: isActive,
                progress: progress,
                heroTag: heroTag,
                width: width,
                height: imgH,
                radiusOverride: GlobalUI.uiRoundness * 0.7,
              ),
              CardBadgeOverlay(
                media: media,
                styleName: 'compact',
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
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                media.title.getPreferedTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = height * 1.0;

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
              : cs.outlineVariant.withValues(alpha: 0.15),
          width: isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Stack(
            children: [
              CardThumbnail(
                media: media,
                isActive: isActive,
                progress: progress,
                heroTag: heroTag,
                width: thumbW,
                height: height,
                radiusOverride: GlobalUI.uiRoundness * 0.7,
              ),
              CardBadgeOverlay(
                media: media,
                styleName: 'compact',
                isWideMode: isWideMode,
                isActive: isActive,
                showRatings: false,
                progress: progress,
                progressText: progressText,
                topLeftBadge: topLeftBadge,
                topRightBadge: topRightBadge,
                bottomLeftBadge: bottomLeftBadge,
                bottomRightBadge: bottomRightBadge,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRect(
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
    );
  }
}
