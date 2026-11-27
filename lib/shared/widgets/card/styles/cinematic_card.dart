import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class CinematicCard extends StatelessWidget {
  final CardContent content;

  const CinematicCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbWidth = content.width * 0.41;

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
              : cs.outlineVariant.withValues(alpha: UiAlpha.outline),
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
              styleName: 'cinematic',
              thumbWidth: thumbWidth,
              thumbHeight: content.height,
              borderRadiusOverride: BorderRadius.horizontal(
                left: Radius.circular(GlobalUI.uiRoundness),
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
