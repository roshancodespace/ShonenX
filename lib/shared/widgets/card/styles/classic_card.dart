import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class ClassicCard extends StatelessWidget {
  final CardContent content;

  const ClassicCard({super.key, required this.content});

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
    final imgH = content.height * (content.progress != null ? 0.65 : 0.74);

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
                styleName: 'classic',
                thumbWidth: content.width,
                thumbHeight: imgH,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.media.title.getPreferedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                if (content.resolvedSubtitle != null) ...[
                  const SizedBox(height: 2),
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
    final thumbW = content.width * 0.48;

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
      child: Row(
        children: [
          Stack(
            children: [
              CardMediaStack(
                content: content,
                styleName: 'classic',
                thumbWidth: thumbW,
                thumbHeight: content.height,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: UiSpace.sm,
                horizontal: UiSpace.xs,
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
    );
  }
}
