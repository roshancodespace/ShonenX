import 'package:material_ui/material_ui.dart';
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => CardMediaStack(
                content: content,
                styleName: 'neon',
                thumbWidth: constraints.maxWidth,
                thumbHeight: constraints.maxHeight,
                radiusOverride: (GlobalUI.uiRoundness - 2).clamp(2.0, 24.0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.media.title.getPreferedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.15,
                    color: isDark ? Colors.white : cs.onSurface,
                    height: 1.18,
                  ),
                ),
                if (content.resolvedSubtitle != null) ...[
                  const SizedBox(height: 4),
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
    final isDark = theme.brightness == Brightness.dark;
    final thumbW = content.width * 0.43;

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
