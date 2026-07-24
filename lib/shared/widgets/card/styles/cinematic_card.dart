import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class CinematicCard extends StatelessWidget {
  final CardConfig config;

  const CinematicCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbWidth = config.width * 0.44;

    return AnimatedContainer(
      duration: Durations.short4,
      width: config.width,
      height: config.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: config.isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: config.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Row(
          children: [
            Stack(
              children: [
                CardThumbnail(
                  config: config,
                  width: thumbWidth,
                  height: config.height,
                  radiusOverride: GlobalUI.uiRoundness * 0.6,
                ),
                CardBadgeOverlay(config: config, styleName: 'cinematic'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: WideMetadataColumn(config: config),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
