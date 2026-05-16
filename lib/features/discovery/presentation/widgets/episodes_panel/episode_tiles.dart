import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_episode.dart';

enum EpisodeViewMode {
  classic("Classic"),
  grid("Grid"),
  box("Box");

  final String displayName;
  const EpisodeViewMode(this.displayName);
}

enum EpisodeImageFadeDirection {
  horizontal,
  vertical,
  left,
  right,
  top,
  bottom,
}

class EpisodeClassicTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final bool isCurrent;
  final bool isWatched;
  final bool isFiller;
  final VoidCallback onTap;
  final EpisodeImageFadeDirection imageFadeDirection;
  final List<double>? imageFadeStops;
  final double imageOpacity;
  final double imageBlurSigma;
  final List<Widget> actions;

  const EpisodeClassicTile({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.isWatched,
    required this.onTap,
    this.isFiller = false,
    this.imageFadeDirection = EpisodeImageFadeDirection.left,
    this.imageFadeStops,
    this.imageOpacity = 0.3,
    this.imageBlurSigma = 0,
    this.actions = const [],
  });

  Alignment _begin() {
    switch (imageFadeDirection) {
      case EpisodeImageFadeDirection.horizontal:
      case EpisodeImageFadeDirection.left:
        return Alignment.centerLeft;
      case EpisodeImageFadeDirection.right:
        return Alignment.centerRight;
      case EpisodeImageFadeDirection.vertical:
      case EpisodeImageFadeDirection.top:
        return Alignment.topCenter;
      case EpisodeImageFadeDirection.bottom:
        return Alignment.bottomCenter;
    }
  }

  Alignment _end() {
    switch (imageFadeDirection) {
      case EpisodeImageFadeDirection.horizontal:
        return Alignment.centerRight;
      case EpisodeImageFadeDirection.vertical:
        return Alignment.bottomCenter;
      case EpisodeImageFadeDirection.left:
        return Alignment.centerRight;
      case EpisodeImageFadeDirection.right:
        return Alignment.centerLeft;
      case EpisodeImageFadeDirection.top:
        return Alignment.bottomCenter;
      case EpisodeImageFadeDirection.bottom:
        return Alignment.topCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final num = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();

    final dimColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final isEffectivelyWatched = isWatched && !isCurrent;

    final labelColor = isEffectivelyWatched
        ? dimColor
        : theme.colorScheme.primary;
    final titleColor = isEffectivelyWatched
        ? dimColor
        : theme.colorScheme.onSurface;
    final resolvedOpacity = isCurrent
        ? imageOpacity * 0.65
        : isEffectivelyWatched
        ? imageOpacity * 0.5
        : imageOpacity;

    final imageUrl = episode.thumbnailUrl?.split('#').first;
    final referer = episode.thumbnailUrl?.split('#').last;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : null,
          ),
          child: Stack(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Positioned.fill(
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: imageBlurSigma,
                              sigmaY: imageBlurSigma,
                            ),
                            child: Image(
                              image: CachedNetworkImageProvider(
                                imageUrl,
                                headers: referer != null
                                    ? {'Referer': referer}
                                    : {},
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              opacity: AlwaysStoppedAnimation(resolvedOpacity),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: _begin(),
                                end: _end(),
                                stops: imageFadeStops ?? const [0, 0.4, 1],
                                colors: [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.surface.withValues(
                                    alpha: 0.4,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 14,
                          color: isEffectivelyWatched
                              ? dimColor
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            isEffectivelyWatched
                                ? Icons.check_circle
                                : Icons.play_circle_fill_rounded,
                            size: 28,
                            color: isEffectivelyWatched
                                ? dimColor
                                : isFiller
                                ? Colors.amber.shade700
                                : theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 14,
                          color: isEffectivelyWatched
                              ? dimColor
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'EPISODE $num',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isFiller
                                          ? Colors.amber.shade700
                                          : labelColor,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                if (actions.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: actions,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    (episode.title == null ||
                                            episode.title!.trim().isEmpty)
                                        ? 'Episode $num'
                                        : episode.title!,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: isCurrent
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: titleColor,
                                          height: 1.1,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Now Playing',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onPrimary,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodeGridTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final bool isCurrent;
  final bool isWatched;
  final bool isFiller;
  final VoidCallback onTap;
  final List<Widget> actions;

  const EpisodeGridTile({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.isWatched,
    required this.onTap,
    this.isFiller = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final num = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();

    final isEffectivelyWatched = isWatched && !isCurrent;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.4);

    final imageUrl = episode.thumbnailUrl?.split('#').first;
    final referer = episode.thumbnailUrl?.split('#').last;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: isFiller
                ? Border.all(color: Colors.amber.shade700, width: 5)
                : null,
            shape: BoxShape.circle,
          ),
          child: Opacity(
            opacity: isEffectivelyWatched ? 0.55 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail or placeholder
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Image(
                          image: CachedNetworkImageProvider(
                            imageUrl,
                            headers: referer != null
                                ? {'Referer': referer}
                                : {},
                          ),
                          fit: BoxFit.cover,
                        )
                      else
                        ColoredBox(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            color: cs.onSurfaceVariant,
                            size: 28,
                          ),
                        ),

                      if (isEffectivelyWatched)
                        const ColoredBox(color: Colors.black26),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black,
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 10, 6, 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: num,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                            height: 0.5,
                                          ),
                                        ),
                                        if (episode.title != null &&
                                            episode.title!.isNotEmpty)
                                          TextSpan(
                                            text: '   :   ${episode.title}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.italic,
                                              height: 1.15,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Current badge
                      if (isCurrent)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '▶',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 9,
                                height: 1,
                              ),
                            ),
                          ),
                        ),

                      // Watched check
                      if (isEffectivelyWatched)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: dimColor,
                            size: 16,
                          ),
                        ),

                      // Action buttons overlay (top-right)
                      if (actions.isNotEmpty)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EpisodeBoxTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final bool isCurrent;
  final bool isWatched;
  final bool isFiller;
  final VoidCallback onTap;

  const EpisodeBoxTile({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.isWatched,
    required this.onTap,
    this.isFiller = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final num = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();

    final isEffectivelyWatched = isWatched && !isCurrent;

    final bgColor = isCurrent
        ? cs.primary
        : isEffectivelyWatched
        ? cs.surfaceContainerHighest
        : cs.surfaceContainerLow;

    final fgColor = isCurrent
        ? cs.onPrimary
        : isEffectivelyWatched
        ? cs.onSurfaceVariant.withValues(alpha: 0.6)
        : cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                num,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fgColor,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
          if (isFiller)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
