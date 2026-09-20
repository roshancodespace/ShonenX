import 'package:flutter/material.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class MaterialCard extends StatelessWidget {
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

  const MaterialCard({
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
    final imgH = height * 0.62;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: isActive ? 6 : 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? cs.primary : Colors.transparent,
            width: isActive ? 2 : 0,
          ),
        ),
        color: cs.surfaceContainerLow,
        surfaceTintColor: cs.primary,
        shadowColor: isActive ? cs.shadow : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imgH,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardThumbnail(
                    media: media,
                    isActive: isActive,
                    progress: progress,
                    heroTag: heroTag,
                    width: double.maxFinite,
                    height: imgH,
                    radiusOverride: 0,
                  ),
                  CardBadgeOverlay(
                    media: media,
                    styleName: 'material',
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title.availableTitle,
                      maxLines: progress != null ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                    if (_getSubtitle() != null) ...[
                      const Spacer(),
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

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = width * 0.45;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: isActive ? 6 : 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? cs.primary : Colors.transparent,
            width: isActive ? 2 : 0,
          ),
        ),
        color: cs.surfaceContainerLow,
        surfaceTintColor: cs.primary,
        shadowColor: isActive ? cs.shadow : Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: thumbW,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
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
                    styleName: 'material',
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
