import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class EditorialCard extends StatelessWidget {
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

  const EditorialCard({
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
    final imgH = height * (progress != null ? 0.58 : 0.65);

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.primary : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
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
                radiusOverride: GlobalUI.uiRoundness,
              ),
              CardBadgeOverlay(
                media: media,
                styleName: 'editorial',
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title.getPreferedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                if (_getSubtitle() != null) ...[
                  const SizedBox(height: 6),
                  Container(width: 24, height: 1.5, color: cs.primary),
                  const SizedBox(height: 6),
                  PortraitMetadataRow(
                    media: media,
                    showRatings: showRatings,
                    showYear: showYear,
                    showGenres: showGenres,
                    subtitle: subtitle,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = width * 0.45;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.primary : Colors.transparent,
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
                  width: thumbW,
                  height: height,
                  radiusOverride: 0,
                ),
                CardBadgeOverlay(
                  media: media,
                  styleName: 'editorial',
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title.getPreferedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        height: 1.15,
                      ),
                    ),
                    if (_getSubtitle() != null) ...[
                      const SizedBox(height: 6),
                      Container(width: 24, height: 1.5, color: cs.primary),
                      const SizedBox(height: 6),
                      PortraitMetadataRow(
                        media: media,
                        showRatings: showRatings,
                        showYear: showYear,
                        showGenres: showGenres,
                        subtitle: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getSubtitle() {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle;
    final items = <String>[];
    if (showYear && media.year != null) items.add(media.year.toString());
    if (media.status != null && media.status!.isNotEmpty) {
      items.add(media.status!);
    }
    if (showGenres && media.genres != null && media.genres!.isNotEmpty) {
      items.add(media.genres!.first);
    }
    if (items.isEmpty) return null;
    return items.join(' • ');
  }
}
