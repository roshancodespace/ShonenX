import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class ExpressiveCard extends StatelessWidget {
  final CardConfig config;

  const ExpressiveCard({super.key, required this.config});

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
    final imgH = config.height * 0.64;

    return SizedBox(
      width: config.width,
      child: AnimatedContainer(
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
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardThumbnail(
                  config: config,
                  width: double.maxFinite,
                  height: imgH,
                  radiusOverride: GlobalUI.uiRoundness * 0.8,
                ),
                CardBadgeOverlay(config: config, styleName: 'expressive'),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                config.title,
                maxLines: config.progress != null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (config.effectiveSubtitle != null ||
                config.progress != null ||
                config.progressText != null) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (config.effectiveSubtitle != null)
                      Expanded(child: PortraitMetadataRow(config: config)),
                    if (config.progressText != null || config.progress != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          config.progressText ??
                              '${(config.progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.5),
        border: Border.all(
          color: config.isActive ? cs.primary : Colors.transparent,
          width: config.isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Stack(
            children: [
              CardThumbnail(
                config: config,
                width: thumbW,
                height: config.height,
                radiusOverride: GlobalUI.uiRoundness * 1.2,
              ),
              CardBadgeOverlay(config: config, styleName: 'expressive'),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: WideMetadataColumn(config: config),
            ),
          ),
        ],
      ),
    );
  }
}
