import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class NeonCard extends StatelessWidget {
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

  const NeonCard({
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
    final isDark = theme.brightness == Brightness.dark;
    final imgH = height * 0.64;

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0E14) : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
          border: Border.all(
          color: isActive ? cs.primary : cs.outlineVariant.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(
                alpha: isActive ? 0.48 : 0.22,
              ),
              blurRadius: isActive ? 20 : 10,
              spreadRadius: isActive ? 1 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardThumbnail(media: media, isActive: isActive, progress: progress, heroTag: heroTag, width: double.maxFinite, height: imgH, radiusOverride: GlobalUI.uiRoundness * 0.8),
                CardBadgeOverlay(media: media, styleName: 'neon', isWideMode: isWideMode, isActive: isActive, showRatings: showRatings, progress: progress, progressText: progressText, topLeftBadge: topLeftBadge, topRightBadge: topRightBadge, bottomLeftBadge: bottomLeftBadge, bottomRightBadge: bottomRightBadge,),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                media.title.availableTitle,
                maxLines: progress != null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (_getSubtitle() != null) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PortraitMetadataRow(media: media, showRatings: showRatings, showYear: showYear, showGenres: showGenres, subtitle: subtitle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final thumbW = width * 0.48;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0E14) : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.primary : cs.outlineVariant.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: isActive ? 0.48 : 0.22),
            blurRadius: isActive ? 20 : 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Stack(
            children: [
              CardThumbnail(media: media, isActive: isActive, progress: progress, heroTag: heroTag, width: thumbW, height: height, radiusOverride: GlobalUI.uiRoundness * 0.8),
              CardBadgeOverlay(media: media, styleName: 'neon', isWideMode: isWideMode, isActive: isActive, showRatings: showRatings, progress: progress, progressText: progressText, topLeftBadge: topLeftBadge, topRightBadge: topRightBadge, bottomLeftBadge: bottomLeftBadge, bottomRightBadge: bottomRightBadge,),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: WideMetadataColumn(media: media, showRatings: showRatings, showYear: showYear, showGenres: showGenres, subtitle: subtitle, textColor: isDark ? Colors.white : cs.onSurface, height: height, progress: progress, progressText: progressText, topRightBadge: topRightBadge),
            ),
          ),
        ],
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