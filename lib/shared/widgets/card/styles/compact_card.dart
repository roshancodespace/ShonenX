import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class CompactCard extends StatelessWidget {
  final CardContent content;

  const CompactCard({super.key, required this.content});

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
    final imgH = content.height * 0.75;

    return AnimatedContainer(
      duration: Durations.short4,
      width: content.width,
      height: content.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: content.isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: UiAlpha.faint),
          width: content.isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CardMediaStack(
                content: content,
                styleName: 'compact',
                thumbWidth: content.width,
                thumbHeight: imgH,
                radiusOverride: GlobalUI.uiRoundness * 0.7,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                content.media.title.getPreferedTitle,
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
    final thumbW = content.height * 1.0;

    return AnimatedContainer(
      duration: Durations.short4,
      width: content.width,
      height: content.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: content.isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: UiAlpha.faint),
          width: content.isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Stack(
            children: [
              CardMediaStack(
                content: content.copyWith(showRatings: false),
                styleName: 'compact',
                thumbWidth: thumbW,
                thumbHeight: content.height,
                radiusOverride: GlobalUI.uiRoundness * 0.7,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRect(
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
    );
  }
}
