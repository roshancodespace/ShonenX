import 'package:material_ui/material_ui.dart';
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
            color: content.isActive
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: UiAlpha.faint),
            width: content.isActive ? 2 : 0.8,
          ),
        ),
        color: cs.surfaceContainerLow,
        surfaceTintColor: cs.primary,
        shadowColor: content.isActive ? cs.shadow : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => CardMediaStack(
                  content: content,
                  styleName: 'material',
                  thumbWidth: constraints.maxWidth,
                  thumbHeight: constraints.maxHeight,
                  borderRadiusOverride: BorderRadius.vertical(
                    top: Radius.circular(UiRadius.card),
                  ),
                  fit: StackFit.expand,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content.media.title.getPreferedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        color: cs.onSurface,
                        height: 1.2,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = content.width * 0.42;

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
                    borderRadiusOverride: BorderRadius.horizontal(
                      left: Radius.circular(UiRadius.card),
                    ),
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
