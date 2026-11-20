import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import '../components/card_metadata.dart';
import '../components/card_content.dart';

class WideBannerCard extends StatelessWidget {
  final CardContent content;

  const WideBannerCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badgeContent = content.copyWith(progress: null, progressText: null);

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
            SizedBox(
              width: content.width * 0.40,
              height: content.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardMediaStack(
                    content: badgeContent,
                    styleName: 'wideBanner',
                    thumbWidth: content.width * 0.40,
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
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: WideMetadataColumn(
                        media: content.media,
                        showRatings: content.showRatings,
                        showYear: content.showYear,
                        showGenres: content.showGenres,
                        subtitle: content.subtitle,
                        height: content.height,
                        progress: null,
                        progressText: null,
                        topRightBadge: null,
                      ),
                    ),
                    if (content.progress != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: content.progress!.clamp(0.0, 1.0),
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(UiRadius.sm),
                              minHeight: 6,
                            ),
                          ),
                          if (content.progressText != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              content.progressText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
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
