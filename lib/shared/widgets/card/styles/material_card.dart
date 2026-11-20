import 'package:flutter/material.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class MaterialCard extends StatelessWidget {
  final CardContent content;

  const MaterialCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (content.isWideMode) {
      return _buildWide(theme);
    }
    return _buildPortrait(theme);
  }

  Widget _buildPortrait(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = content.height * 0.62;

    return SizedBox(
      width: content.width,
      height: content.height,
      child: Card(
        elevation: content.isActive ? UiElevation.active : UiElevation.resting,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.card),
          side: BorderSide(
            color: content.isActive ? cs.primary : Colors.transparent,
            width: content.isActive ? 2 : 0,
          ),
        ),
        color: cs.surfaceContainerLow,
        surfaceTintColor: cs.primary,
        shadowColor: content.isActive ? cs.shadow : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imgH,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardMediaStack(
                    content: content,
                    styleName: 'material',
                    thumbWidth: double.maxFinite,
                    thumbHeight: imgH,
                    radiusOverride: 0,
                    fit: StackFit.expand,
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
                      content.media.title.getPreferedTitle,
                      maxLines: content.progress != null ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                    if (content.resolvedSubtitle != null) ...[
                      const Spacer(),
                      PortraitMetadataRow(
                        media: content.media,
                        showRatings: content.showRatings,
                        showYear: content.showYear,
                        showGenres: content.showGenres,
                        subtitle: content.subtitle,
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
    final thumbW = content.width * 0.45;

    return SizedBox(
      width: content.width,
      height: content.height,
      child: Card(
        elevation: content.isActive ? UiElevation.active : UiElevation.resting,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.card),
          side: BorderSide(
            color: content.isActive ? cs.primary : Colors.transparent,
            width: content.isActive ? 2 : 0,
          ),
        ),
        color: cs.surfaceContainerLow,
        surfaceTintColor: cs.primary,
        shadowColor: content.isActive ? cs.shadow : Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: thumbW,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardMediaStack(
                    content: content,
                    styleName: 'material',
                    thumbWidth: thumbW,
                    thumbHeight: content.height,
                    radiusOverride: 0,
                    fit: StackFit.expand,
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
                  media: content.media,
                  showRatings: content.showRatings,
                  showYear: content.showYear,
                  showGenres: content.showGenres,
                  subtitle: content.subtitle,
                  height: content.height,
                  progress: content.progress,
                  progressText: content.progressText,
                  topRightBadge: content.topRightBadge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
