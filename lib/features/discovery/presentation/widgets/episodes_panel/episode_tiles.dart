import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

enum EpisodeViewMode {
  classic("Classic"),
  grid("Grid"),
  box("Box"),
  compact("Compact"),
  cover("Cover");

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

abstract class BaseEpisodeTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final MediaType mediaType;
  final bool isCurrent;
  final bool isWatched;
  final bool isFiller;
  final VoidCallback onTap;
  final List<Widget> actions;
  final String? fallbackThumbnailUrl;
  final EpisodeImageFadeDirection imageFadeDirection;
  final List<double>? imageFadeStops;
  final double imageOpacity;
  final double imageBlurSigma;

  const BaseEpisodeTile({
    super.key,
    required this.episode,
    this.mediaType = MediaType.ANIME,
    required this.isCurrent,
    required this.isWatched,
    this.isFiller = false,
    required this.onTap,
    this.actions = const [],
    this.fallbackThumbnailUrl,
    this.imageFadeDirection = EpisodeImageFadeDirection.left,
    this.imageFadeStops,
    this.imageOpacity = 0.3,
    this.imageBlurSigma = 0,
  });

  String? get resolvedThumbnailUrl {
    if (episode.thumbnailUrl != null && episode.thumbnailUrl!.isNotEmpty) {
      return episode.thumbnailUrl;
    }
    if (fallbackThumbnailUrl != null && fallbackThumbnailUrl!.isNotEmpty) {
      return fallbackThumbnailUrl;
    }
    return null;
  }

  String? get imageUrl => resolvedThumbnailUrl?.split('#').first;

  Map<String, String> get imageHeaders => resolvedThumbnailUrl != null
      ? decodeUrlHeaders(resolvedThumbnailUrl!)
      : {};

  String? get displayDate =>
      formatDateString(episode.uploadDate ?? episode.airDate);

  void triggerMenuAction() {
    for (final action in actions.reversed) {
      if (action is IconButton && action.onPressed != null) {
        action.onPressed!();
        return;
      }
    }
  }
}

class EpisodeClassicTile extends BaseEpisodeTile {
  const EpisodeClassicTile({
    super.key,
    required super.episode,
    super.mediaType = MediaType.ANIME,
    required super.isCurrent,
    required super.isWatched,
    required super.onTap,
    super.isFiller = false,
    super.imageFadeDirection = EpisodeImageFadeDirection.left,
    super.imageFadeStops,
    super.imageOpacity = 0.3,
    super.imageBlurSigma = 0,
    super.actions = const [],
    super.fallbackThumbnailUrl,
  });

  @override
  String? get resolvedThumbnailUrl {
    if (episode.thumbnailUrl != null && episode.thumbnailUrl!.isNotEmpty) {
      return episode.thumbnailUrl;
    }
    return null;
  }

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
    final num = formatEpisodeNumber(episode.number);

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : null,
          ),
          child: Stack(
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
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
                                imageUrl!,
                                headers: imageHeaders.isEmpty
                                    ? null
                                    : imageHeaders,
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
                                    '${mediaType == MediaType.ANIME ? 'EPISODE' : 'CHAPTER'} $num',
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
                            if (displayDate != null &&
                                displayDate!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: dimColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayDate!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: dimColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (episode.scanlator != null &&
                                      episode.scanlator!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: dimColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        episode.scanlator!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: dimColor,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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

class EpisodeGridTile extends BaseEpisodeTile {
  const EpisodeGridTile({
    super.key,
    required super.episode,
    super.mediaType = MediaType.ANIME,
    required super.isCurrent,
    required super.isWatched,
    required super.onTap,
    super.isFiller = false,
    super.actions = const [],
    super.fallbackThumbnailUrl,
    super.imageFadeDirection = EpisodeImageFadeDirection.left,
    super.imageFadeStops,
    super.imageOpacity = 0.3,
    super.imageBlurSigma = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final num = formatEpisodeNumber(episode.number);

    final isEffectivelyWatched = isWatched && !isCurrent;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.45);

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: isEffectivelyWatched ? 0.6 : 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Image(
                      image: CachedNetworkImageProvider(
                        imageUrl!,
                        headers: imageHeaders.isEmpty ? null : imageHeaders,
                      ),
                      fit: BoxFit.cover,
                    )
                  else
                    ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 24,
                        ),
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
                          stops: const [0.0, 0.55, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.92),
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(7, 14, 7, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              num ?? '',
                              style: TextStyle(
                                color: isFiller
                                    ? Colors.amber.shade300
                                    : isCurrent
                                    ? cs.primary
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                height: 1.0,
                                shadows: const [
                                  Shadow(blurRadius: 4, color: Colors.black),
                                ],
                              ),
                            ),
                            if (episode.title != null &&
                                episode.title!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                episode.title!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (displayDate != null &&
                                displayDate!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                displayDate!,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (isFiller)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: Colors.amber.shade600),
                    ),

                  if (isCurrent)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: cs.onPrimary,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'NOW',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (isEffectivelyWatched)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: dimColor,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),

            if (actions.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      iconTheme: const IconThemeData(
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EpisodeBoxTile extends BaseEpisodeTile {
  const EpisodeBoxTile({
    super.key,
    required super.episode,
    super.mediaType = MediaType.ANIME,
    required super.isCurrent,
    required super.isWatched,
    required super.onTap,
    super.isFiller = false,
    super.actions = const [],
    super.fallbackThumbnailUrl,
    super.imageFadeDirection = EpisodeImageFadeDirection.left,
    super.imageFadeStops,
    super.imageOpacity = 0.3,
    super.imageBlurSigma = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final num = formatEpisodeNumber(episode.number);

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

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      num ?? '',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: fgColor,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    if (displayDate != null && displayDate!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          displayDate!,
                          style: TextStyle(
                            color: fgColor.withValues(alpha: 0.75),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
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
      ),
    );
  }
}

class EpisodeCompactTile extends BaseEpisodeTile {
  const EpisodeCompactTile({
    super.key,
    required super.episode,
    super.mediaType = MediaType.ANIME,
    required super.isCurrent,
    required super.isWatched,
    required super.onTap,
    super.isFiller = false,
    super.actions = const [],
    super.fallbackThumbnailUrl,
    super.imageFadeDirection = EpisodeImageFadeDirection.left,
    super.imageFadeStops,
    super.imageOpacity = 0.3,
    super.imageBlurSigma = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final epNumText = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();
    final epLabel = mediaType == MediaType.ANIME
        ? 'Ep $epNumText'
        : 'Ch $epNumText';
    final title = episode.title ?? epLabel;

    final isEffectivelyWatched = isWatched && !isCurrent;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      onLongPress: triggerMenuAction,
      onSecondaryTap: triggerMenuAction,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (isCurrent)
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            SizedBox(
              width: 38,
              child: Text(
                epNumText,
                style: textTheme.titleMedium?.copyWith(
                  color: isCurrent
                      ? cs.primary
                      : isEffectivelyWatched
                      ? dimColor
                      : cs.onSurface,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isCurrent
                          ? cs.primary
                          : isEffectivelyWatched
                          ? dimColor
                          : cs.onSurface,
                      height: 1.15,
                    ),
                  ),
                  if ((displayDate != null && displayDate!.isNotEmpty) ||
                      isFiller) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isFiller) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FILLER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (displayDate != null && displayDate!.isNotEmpty)
                          Text(
                            displayDate!,
                            style: textTheme.labelSmall?.copyWith(
                              color: dimColor,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isEffectivelyWatched) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 18, color: dimColor),
            ] else if (isCurrent) ...[
              const SizedBox(width: 8),
              Icon(Icons.play_circle_fill_rounded, size: 20, color: cs.primary),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 6),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class EpisodeCoverTile extends BaseEpisodeTile {
  const EpisodeCoverTile({
    super.key,
    required super.episode,
    super.mediaType = MediaType.ANIME,
    required super.isCurrent,
    required super.isWatched,
    required super.onTap,
    super.isFiller = false,
    super.actions = const [],
    super.fallbackThumbnailUrl,
    super.imageFadeDirection = EpisodeImageFadeDirection.left,
    super.imageFadeStops,
    super.imageOpacity = 0.3,
    super.imageBlurSigma = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final epNumText = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();
    final epLabel = mediaType == MediaType.ANIME
        ? 'Episode $epNumText'
        : 'Chapter $epNumText';
    final title = episode.title ?? epLabel;

    final isEffectivelyWatched = isWatched && !isCurrent;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: isEffectivelyWatched ? 0.6 : 1.0,
                child:
                    resolvedThumbnailUrl != null &&
                        resolvedThumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolvedThumbnailUrl!,
                        fit: BoxFit.cover,
                        httpHeaders: imageHeaders.isEmpty ? null : imageHeaders,
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.tv_rounded,
                            size: 32,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.tv_rounded,
                          size: 32,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
            if (isEffectivelyWatched)
              const Positioned.fill(child: ColoredBox(color: Colors.black26)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.6, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.90),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? cs.primary
                          : Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isCurrent
                          ? Icons.play_arrow_rounded
                          : isEffectivelyWatched
                          ? Icons.check_rounded
                          : Icons.play_arrow_rounded,
                      color: isCurrent ? cs.onPrimary : Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              epLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: isCurrent ? cs.primary : Colors.white70,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                            if (isFiller) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FILLER',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: isEffectivelyWatched
                                ? Colors.white60
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (displayDate != null && displayDate!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            displayDate!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      iconTheme: const IconThemeData(
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
