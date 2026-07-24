import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class WideBannerCard extends StatelessWidget {
  final CardConfig config;

  const WideBannerCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardThumbnail(
              config: config,
              width: config.width,
              height: config.height,
              radiusOverride: GlobalUI.uiRoundness,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.1, 0.65, 1.0],
                  colors: [
                    cs.surface.withValues(alpha: 0.95),
                    cs.surface.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CardBadgeOverlay(config: config, styleName: 'wideBanner'),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: WideMetadataColumn(config: config)),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
