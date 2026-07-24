import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class ClassicCard extends StatelessWidget {
  final CardConfig config;

  const ClassicCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (config.isWideMode) {
      return _buildWide(theme);
    }
    return _buildPortrait(theme);
  }

  Widget _buildPortrait(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = config.height * (config.progress != null ? 0.65 : 0.74);

    return AnimatedContainer(
      duration: Durations.short4,
      width: config.width,
      height: config.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: config.isActive ? cs.tertiary : Colors.transparent,
          width: config.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CardThumbnail(
                config: config,
                width: config.width,
                height: imgH,
              ),
              CardBadgeOverlay(config: config, styleName: 'classic'),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  maxLines: config.progress != null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                if (config.effectiveSubtitle != null ||
                    config.progress != null ||
                    config.progressText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (config.effectiveSubtitle != null)
                        Expanded(child: PortraitMetadataRow(config: config)),
                      if (config.progressText != null || config.progress != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          config.progressText ??
                              '${(config.progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
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
    final thumbW = config.width * 0.48;

    return AnimatedContainer(
      duration: Durations.short4,
      width: config.width,
      height: config.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: config.isActive ? cs.tertiary : Colors.transparent,
          width: config.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CardThumbnail(
                config: config,
                width: thumbW,
                height: config.height,
              ),
              CardBadgeOverlay(config: config, styleName: 'classic'),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              child: WideMetadataColumn(config: config),
            ),
          ),
        ],
      ),
    );
  }
}
