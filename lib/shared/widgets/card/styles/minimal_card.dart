import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class MinimalCard extends StatelessWidget {
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

  const MinimalCard({
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

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.primary
              : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardThumbnail(media: media, isActive: isActive, progress: progress, heroTag: heroTag, width: width, height: height, radiusOverride: GlobalUI.uiRoundness),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                  colors: [
                    Colors.transparent,
                    cs.scrim.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
            CardBadgeOverlay(media: media, styleName: 'minimal', isWideMode: isWideMode, isActive: isActive, showRatings: showRatings, progress: progress, progressText: progressText, topLeftBadge: topLeftBadge, topRightBadge: topRightBadge, bottomLeftBadge: bottomLeftBadge, bottomRightBadge: bottomRightBadge,),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    media.title.availableTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (_getSubtitle() != null ||
                      progress != null ||
                      progressText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_getSubtitle() != null)
                          Expanded(child: PortraitMetadataRow(media: media, showRatings: showRatings, showYear: showYear, showGenres: showGenres, subtitle: subtitle)),
                        if (progressText != null ||
                            progress != null)
                          Text(
                            progressText ??
                                '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.primary
              : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardThumbnail(media: media, isActive: isActive, progress: progress, heroTag: heroTag, width: width, height: height, radiusOverride: GlobalUI.uiRoundness),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.6, 1.0],
                  colors: [
                    cs.scrim.withValues(alpha: 0.9),
                    cs.scrim.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CardBadgeOverlay(media: media, styleName: 'minimal', isWideMode: isWideMode, isActive: isActive, showRatings: showRatings, progress: progress, progressText: progressText, topLeftBadge: topLeftBadge, topRightBadge: topRightBadge, bottomLeftBadge: bottomLeftBadge, bottomRightBadge: bottomRightBadge,),
            Positioned(
              left: 12,
              right: 12,
              bottom: 6,
              top: 6,
              child: WideMetadataColumn(media: media, showRatings: showRatings, showYear: showYear, showGenres: showGenres, subtitle: subtitle, textColor: Colors.white, height: height, progress: progress, progressText: progressText, topRightBadge: topRightBadge),
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
    if (media.status != null && media.status!.isNotEmpty) items.add(media.status!);
    if (showGenres && media.genres != null && media.genres!.isNotEmpty) items.add(media.genres!.first);
    if (items.isEmpty) return null;
    return items.join(' • ');
  }
}