import 'package:material_ui/material_ui.dart';
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => CardMediaStack(
                content: content,
                styleName: 'editorial',
                thumbWidth: constraints.maxWidth,
                thumbHeight: constraints.maxHeight,
                radiusOverride: GlobalUI.uiRoundness,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.media.title.getPreferedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                    color: cs.onSurface,
                    height: 1.16,
                  ),
                ),
                if (content.resolvedSubtitle != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    width: 22,
                    height: 2,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 5),
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
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = content.width * 0.42;

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
            CardMediaStack(
              content: content,
              styleName: 'editorial',
              thumbWidth: thumbW,
              thumbHeight: content.height,
              borderRadiusOverride: BorderRadius.horizontal(
                left: Radius.circular(GlobalUI.uiRoundness),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content.media.title.getPreferedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        color: cs.onSurface,
                        height: 1.16,
                      ),
                    ),
                    if (content.resolvedSubtitle != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: 22,
                        height: 2,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 5),
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
