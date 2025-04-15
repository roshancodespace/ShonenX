// Enhanced Tag Component
import 'package:flutter/material.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool hasShadow;

  const Tag({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Anime Title Component
class AnimeTitle extends StatelessWidget {
  final Media? anime;
  final int maxLines;
  final bool minimal;
  final bool enhanced;

  const AnimeTitle({
    required this.anime,
    required this.maxLines,
    this.minimal = false,
    this.enhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = anime?.title?.english ??
        anime?.title?.romaji ??
        anime?.title?.native ??
        'Unknown Title';

    if (minimal) {
      return Text(
        title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    if (enhanced) {
      return Text(
        title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );
    }

    // Original style
    return Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
