import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class MinimalCard extends StatelessWidget {
  final CardContent content;

  const MinimalCard({super.key, required this.content});

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardMediaStack(
              content: content,
              styleName: 'minimal',
              thumbWidth: content.width,
              thumbHeight: content.height,
              radiusOverride: GlobalUI.uiRoundness,
              fit: StackFit.expand,
              overlayBeforeBadges: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      cs.scrim.withValues(alpha: UiAlpha.strong),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content.media.title.getPreferedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (content.resolvedSubtitle != null ||
                      content.progress != null ||
                      content.progressText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (content.resolvedSubtitle != null)
                          Expanded(
                            child: PortraitMetadataRow(
                              media: content.media,
                              showRatings: content.showRatings,
                              showYear: content.showYear,
                              showGenres: content.showGenres,
                              subtitle: content.subtitle,
                            ),
                          ),
                        if (content.progressText != null ||
                            content.progress != null)
                          Text(
                            content.progressText ??
                                '${(content.progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardMediaStack(
              content: content,
              styleName: 'minimal',
              thumbWidth: content.width,
              thumbHeight: content.height,
              radiusOverride: GlobalUI.uiRoundness,
              fit: StackFit.expand,
              overlayBeforeBadges: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.6, 1.0],
                    colors: [
                      cs.scrim.withValues(alpha: UiAlpha.solidHigh),
                      cs.scrim.withValues(alpha: UiAlpha.scrimSoft),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 6,
              top: 6,
              child: WideMetadataColumn(
                media: content.media,
                showRatings: content.showRatings,
                showYear: content.showYear,
                showGenres: content.showGenres,
                subtitle: content.subtitle,
                textColor: Colors.white,
                height: content.height,
                progress: content.progress,
                progressText: content.progressText,
                topRightBadge: content.topRightBadge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
