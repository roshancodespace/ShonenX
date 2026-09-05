import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class EditorialCard extends StatelessWidget {
  final CardConfig config;

  const EditorialCard({super.key, required this.config});

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
    final imgH = config.height * (config.progress != null ? 0.68 : 0.76);

    return AnimatedContainer(
      duration: Durations.short4,
      width: config.width,
      height: config.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: config.isActive ? cs.primary : Colors.transparent,
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
                radiusOverride: GlobalUI.uiRoundness,
              ),
              CardBadgeOverlay(config: config, styleName: 'editorial'),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.badgeText != null)
                  Text(
                    config.badgeText!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                Text(
                  config.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                if (config.effectiveSubtitle != null) ...[
                  const SizedBox(height: 2),
                  PortraitMetadataRow(config: config),
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
          color: config.isActive ? cs.primary : Colors.transparent,
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
                radiusOverride: GlobalUI.uiRoundness,
              ),
              CardBadgeOverlay(config: config, styleName: 'editorial'),
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
