import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../components/card_badges.dart';
import '../components/card_metadata.dart';
import '../components/card_thumbnail.dart';
import '../models/card_config.dart';

class MaterialCard extends StatelessWidget {
  final CardConfig config;

  const MaterialCard({super.key, required this.config});

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
    final imgH = config.height * 0.62;

    return SizedBox(
      width: config.width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: config.width,
        height: config.height,
        decoration: BoxDecoration(
          color: config.isActive
              ? cs.surfaceContainerHighest
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness + 2),
          border: Border.all(
            color: config.isActive
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.35),
            width: config.isActive ? 2.5 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: config.isActive
              ? [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardThumbnail(
                  config: config,
                  width: double.maxFinite,
                  height: imgH,
                  radiusOverride: GlobalUI.uiRoundness - 2,
                ),
                CardBadgeOverlay(config: config, styleName: 'material'),
              ],
            ),
            const SizedBox(height: 10),
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          config.progressText ??
                              '${(config.progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.3),
        border: Border.all(
          color: config.isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: config.isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: config.isActive
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
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
                radiusOverride: GlobalUI.uiRoundness,
              ),
              CardBadgeOverlay(config: config, styleName: 'material'),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          config.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (config.topRightBadge != null) config.topRightBadge!,
                    ],
                  ),
                  if (config.subtitle != null ||
                      config.progress != null ||
                      config.progressText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (config.subtitle != null)
                          Expanded(
                            child: Text(
                              config.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (config.progressText != null ||
                            config.progress != null)
                          Text(
                            config.progressText ??
                                '${(config.progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
