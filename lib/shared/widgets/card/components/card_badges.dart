import 'package:flutter/material.dart';
import '../models/card_config.dart';

class CardBadgeOverlay extends StatelessWidget {
  final CardConfig config;
  final String styleName;

  const CardBadgeOverlay({
    super.key,
    required this.config,
    required this.styleName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isHorizontalLayout =
        config.isWideMode || (config.width > config.height * 1.2);
    final hasScore =
        config.score != null && config.score! > 0 && !isHorizontalLayout;
    final showBadgeText = config.badgeText != null;

    if (!showBadgeText && config.topRightBadge == null && !hasScore) {
      return const SizedBox.shrink();
    }

    final formattedScore = config.formattedScore;

    return Positioned(
      top: 5,
      left: 5,
      right: 5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBadgeText)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                config.badgeText!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  fontSize: 9.5,
                ),
              ),
            ),
          const Spacer(),
          if (config.topRightBadge != null)
            config.topRightBadge!
          else if (hasScore && formattedScore != null)
            buildStyleRatingBadge(theme, styleName, formattedScore),
        ],
      ),
    );
  }

  static Widget buildStyleRatingBadge(
    ThemeData theme,
    String styleName,
    String formattedScore,
  ) {
    final cs = theme.colorScheme;

    switch (styleName) {
      case 'expressive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 11, color: cs.onPrimaryContainer),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case 'material':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 11, color: cs.primary),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case 'minimal':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 11,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case 'neon':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cs.primary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 11, color: cs.primary),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case 'editorial':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Text(
            '$formattedScore ★',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 9.5,
              letterSpacing: 0.3,
            ),
          ),
        );

      case 'cinematic':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFFB703).withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 11,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case 'classic':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFFFB703).withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 10,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 2),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );
    }
  }
}
