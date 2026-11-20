import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class EditorialCard extends StatelessWidget {
  final CardContent content;

  const EditorialCard({super.key, required this.content});

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
    final imgH = content.height * (content.progress != null ? 0.58 : 0.65);

    return AnimatedContainer(
      duration: Durations.short4,
      width: content.width,
      height: content.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: content.isActive ? cs.primary : Colors.transparent,
          width: content.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CardMediaStack(
                content: content,
                styleName: 'editorial',
                thumbWidth: content.width,
                thumbHeight: imgH,
                radiusOverride: GlobalUI.uiRoundness,
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
                  content.media.title.getPreferedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                if (content.resolvedSubtitle != null) ...[
                  const SizedBox(height: 6),
                  Container(width: 24, height: 1.5, color: cs.primary),
                  const SizedBox(height: 6),
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
        ],
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = content.width * 0.45;

    return AnimatedContainer(
      duration: Durations.short4,
      width: content.width,
      height: content.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: UiAlpha.half),
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: content.isActive ? cs.primary : Colors.transparent,
          width: content.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Row(
          children: [
            Stack(
              children: [
                CardMediaStack(
                  content: content,
                  styleName: 'editorial',
                  thumbWidth: thumbW,
                  thumbHeight: content.height,
                  radiusOverride: 0,
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
                      content.media.title.getPreferedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        height: 1.15,
                      ),
                    ),
                    if (content.resolvedSubtitle != null) ...[
                      const SizedBox(height: 6),
                      Container(width: 24, height: 1.5, color: cs.primary),
                      const SizedBox(height: 6),
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
}
