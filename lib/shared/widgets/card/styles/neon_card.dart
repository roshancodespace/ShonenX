import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class NeonCard extends StatelessWidget {
  final CardContent content;

  const NeonCard({super.key, required this.content});

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
    final isDark = theme.brightness == Brightness.dark;
    final imgH = content.height * 0.64;

    return SizedBox(
      width: content.width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: content.width,
        height: content.height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0E14) : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
          border: Border.all(
            color: content.isActive
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: UiAlpha.faint),
            width: content.isActive ? 1.5 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(
                alpha: content.isActive ? UiAlpha.glow : UiAlpha.subtle,
              ),
              blurRadius: content.isActive
                  ? UiBlur.glowActive
                  : UiBlur.glowWide,
              spreadRadius: content.isActive ? 1 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardMediaStack(
                  content: content,
                  styleName: 'neon',
                  thumbWidth: double.maxFinite,
                  thumbHeight: imgH,
                  radiusOverride: GlobalUI.uiRoundness * 0.8,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                content.media.title.getPreferedTitle,
                maxLines: content.progress != null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (content.resolvedSubtitle != null) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PortraitMetadataRow(
                  media: content.media,
                  showRatings: content.showRatings,
                  showYear: content.showYear,
                  showGenres: content.showGenres,
                  subtitle: content.subtitle,
                ),
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
    final thumbW = content.width * 0.48;

    return AnimatedContainer(
      duration: Durations.short4,
      width: content.width,
      height: content.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0E14) : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: content.isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: UiAlpha.faint),
          width: content.isActive ? 1.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(
              alpha: content.isActive ? UiAlpha.glow : UiAlpha.subtle,
            ),
            blurRadius: content.isActive ? UiBlur.glowActive : UiBlur.glowWide,
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Stack(
            children: [
              CardMediaStack(
                content: content,
                styleName: 'neon',
                thumbWidth: thumbW,
                thumbHeight: content.height,
                radiusOverride: GlobalUI.uiRoundness * 0.8,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: WideMetadataColumn(
                media: content.media,
                showRatings: content.showRatings,
                showYear: content.showYear,
                showGenres: content.showGenres,
                subtitle: content.subtitle,
                textColor: isDark ? Colors.white : cs.onSurface,
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
