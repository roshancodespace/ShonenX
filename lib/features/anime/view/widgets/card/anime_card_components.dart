import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';

class EpisodesInfo extends StatelessWidget {
  final Media? anime;
  final bool compact;

  const EpisodesInfo({
    super.key,
    required this.anime,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (anime?.episodes == null || anime!.episodes == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          Iconsax.play_circle,
          size: 14,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 4),
        Text(
          compact ? '${anime!.episodes}ep' : '${anime!.episodes} episodes',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool hasShadow;

  const Tag({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.icon,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = color ?? colorScheme.primaryContainer;
    final txtColor = textColor ?? colorScheme.onPrimaryContainer;
    final iconColor = textColor ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: txtColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimeTitle extends StatelessWidget {
  final Media? anime;
  final int maxLines;
  final bool minimal;
  final bool enhanced;
  final TextStyle? style;

  const AnimeTitle({
    super.key,
    required this.anime,
    required this.maxLines,
    this.minimal = false,
    this.enhanced = false,
    this.style,
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
        style: style ??
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.7),
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
      style: style ??
          theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
    );
  }
}

class AnimeImage extends StatelessWidget {
  final Media? anime;
  final String tag;
  final double height;

  const AnimeImage({
    super.key,
    required this.anime,
    required this.tag,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Hero(
      tag: tag,
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl:
                anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            memCacheHeight: 400,
            placeholder: (_, __) => AnimeCardShimmer(height: height),
            errorWidget: (_, __, ___) => AnimeCardShimmer(height: height),
            filterQuality: FilterQuality.medium,
            useOldImageOnUrlChange: true,
          ),
        ),
      ),
    );
  }
}

class AnimeCardShimmer extends StatelessWidget {
  final double height;
  final double? width;

  const AnimeCardShimmer({
    super.key,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: width,
      color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
    );
  }
}
