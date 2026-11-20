import 'dart:ui';

import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
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
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
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
    this.onSecondaryTap,
    this.onLongPress,
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

  Widget buildImage({
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (resolvedThumbnailUrl == null || resolvedThumbnailUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SmartImage(
      imageUrl: resolvedThumbnailUrl!,
      fit: fit,
      errorWidget: errorBuilder != null
          ? (context, url, error) => errorBuilder(context, error, null)
          : null,
    );
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

  Color getDimColor(ThemeData theme) =>
      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

  Color getLabelColor(ThemeData theme) =>
      isWatched ? getDimColor(theme) : theme.colorScheme.primary;

  Color getTitleColor(ThemeData theme) =>
      isWatched ? getDimColor(theme) : theme.colorScheme.onSurface;

  double getResolvedOpacity() {
    if (isCurrent) return imageOpacity * 0.65;
    if (isWatched) return imageOpacity * 0.5;
    return imageOpacity;
  }

  Widget buildFadedImage(ThemeData theme) {
    if (imageUrl == null || imageUrl!.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRect(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: _begin(),
              end: _end(),
              stops: imageFadeStops ?? const [0, 0.4, 1],
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcOver,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: imageBlurSigma,
              sigmaY: imageBlurSigma,
            ),
            child: Opacity(
              opacity: getResolvedOpacity(),
              child: buildImage(fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
          height: 1,
          letterSpacing: 0.5,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final num = formatEpisodeNumber(episode.number);

    final dimColor = getDimColor(theme);
    final labelColor = getLabelColor(theme);
    final titleColor = getTitleColor(theme);
    final lineColor = isWatched
        ? dimColor.withValues(alpha: 0.5)
        : cs.primary.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? cs.primaryContainer.withValues(alpha: 0.22)
                : null,
          ),
          child: Stack(
            children: [
              buildFadedImage(theme),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 2, height: 14, color: lineColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            isWatched
                                ? Icons.check_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 28,
                            color: isWatched
                                ? dimColor
                                : isFiller
                                ? Colors.amber.shade700
                                : cs.primary,
                          ),
                        ),
                        Container(width: 2, height: 14, color: lineColor),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${mediaType == MediaType.ANIME ? 'EPISODE' : 'CHAPTER'} $num',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isFiller
                                      ? Colors.amber.shade700
                                      : labelColor,
                                  height: 1,
                                ),
                              ),
                              if (isFiller) ...[
                                const SizedBox(width: 6),
                                _StatusPill(
                                  label: 'FILLER',
                                  backgroundColor: Colors.amber.shade700
                                      .withValues(alpha: 0.18),
                                  foregroundColor: Colors.amber.shade700,
                                ),
                              ],
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                _StatusPill(
                                  label: isWatched
                                      ? (mediaType == MediaType.ANIME
                                            ? 'WATCHED'
                                            : 'READ')
                                      : 'IN PROGRESS',
                                  backgroundColor: isWatched
                                      ? cs.secondaryContainer
                                      : cs.primaryContainer,
                                  foregroundColor: isWatched
                                      ? cs.onSecondaryContainer
                                      : cs.onPrimaryContainer,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (episode.title == null ||
                                    episode.title!.trim().isEmpty)
                                ? '${mediaType == MediaType.ANIME ? 'Episode' : 'Chapter'} $num'
                                : episode.title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: titleColor,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((displayDate != null &&
                                  displayDate!.isNotEmpty) ||
                              (episode.scanlator != null &&
                                  episode.scanlator!.isNotEmpty)) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (displayDate != null &&
                                    displayDate!.isNotEmpty) ...[
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
                                ],
                                if (episode.scanlator != null &&
                                    episode.scanlator!.isNotEmpty) ...[
                                  if (displayDate != null &&
                                      displayDate!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: dimColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
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
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ],
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
    super.onSecondaryTap,
    super.onLongPress,
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
    final radius = BorderRadius.circular(GlobalUI.uiRoundness);

    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isCurrent
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? triggerMenuAction,
        onSecondaryTap: onSecondaryTap ?? triggerMenuAction,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: isWatched ? 0.58 : 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    buildImage(fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: cs.surfaceContainerHigh,
                      child: Center(
                        child: Icon(
                          mediaType == MediaType.ANIME
                              ? Icons.movie_outlined
                              : Icons.menu_book_rounded,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                          size: 24,
                        ),
                      ),
                    ),
                  if (isWatched) const ColoredBox(color: Colors.black26),
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
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black.withValues(alpha: 0.48),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(9, 18, 9, 8),
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
                                    ? cs.primaryContainer
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: -0.5,
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
                                  fontWeight: FontWeight.w600,
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
                                  fontWeight: FontWeight.w500,
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
                ],
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
                top: 7,
                left: 7,
                child: _StatusPill(
                  label: isWatched
                      ? (mediaType == MediaType.ANIME ? 'WATCHED' : 'READ')
                      : 'IN PROGRESS',
                  backgroundColor: isWatched
                      ? cs.secondaryContainer
                      : cs.primary,
                  foregroundColor: isWatched
                      ? cs.onSecondaryContainer
                      : cs.onPrimary,
                ),
              )
            else if (isWatched)
              Positioned(
                top: 7,
                left: 7,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
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
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
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
    final radius = BorderRadius.circular(GlobalUI.uiRoundness);

    final bgColor = isCurrent
        ? cs.primary
        : isWatched
        ? cs.surfaceContainerHighest.withValues(alpha: 0.65)
        : cs.surfaceContainerLow;

    final fgColor = isCurrent
        ? cs.onPrimary
        : isWatched
        ? cs.onSurfaceVariant.withValues(alpha: 0.55)
        : cs.onSurface;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isCurrent
            ? BorderSide.none
            : isFiller
            ? BorderSide(
                color: Colors.amber.shade600.withValues(alpha: 0.7),
                width: 1.25,
              )
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      num ?? '',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fgColor,
                        fontWeight: isCurrent
                            ? FontWeight.w900
                            : FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    if (displayDate != null && displayDate!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          displayDate!,
                          style: TextStyle(
                            color: fgColor.withValues(alpha: 0.7),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
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
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? cs.onPrimary : Colors.amber.shade600,
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
    final radius = BorderRadius.circular(GlobalUI.uiRoundness);

    final epNumText = episode.number % 1 == 0
        ? episode.number.toInt().toString()
        : episode.number.toString();
    final epLabel = mediaType == MediaType.ANIME
        ? 'Ep $epNumText'
        : 'Ch $epNumText';
    final title = (episode.title == null || episode.title!.trim().isEmpty)
        ? epLabel
        : episode.title!;

    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.55);

    final bgColor = isCurrent
        ? cs.primaryContainer.withValues(alpha: 0.35)
        : isWatched
        ? cs.surfaceContainerLowest
        : cs.surfaceContainerLow;

    final numBg = isCurrent
        ? cs.primary
        : isWatched
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerHighest;

    final numFg = isCurrent
        ? cs.onPrimary
        : isWatched
        ? dimColor
        : cs.onSurface;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isCurrent
            ? BorderSide(color: cs.primary.withValues(alpha: 0.6), width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: triggerMenuAction,
        onSecondaryTap: triggerMenuAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 38),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: numBg,
                  borderRadius: BorderRadius.circular(
                    (GlobalUI.uiRoundness * 0.7).clamp(8.0, 12.0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  epNumText,
                  style: textTheme.labelLarge?.copyWith(
                    color: numFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? cs.primary
                            : isWatched
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
                            _StatusPill(
                              label: 'FILLER',
                              backgroundColor: Colors.amber.shade700.withValues(
                                alpha: 0.18,
                              ),
                              foregroundColor: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (displayDate != null && displayDate!.isNotEmpty)
                            Text(
                              displayDate!,
                              style: textTheme.labelSmall?.copyWith(
                                color: dimColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isWatched) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, size: 18, color: dimColor),
              ] else if (isCurrent) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 4),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
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
    super.onSecondaryTap,
    super.onLongPress,
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
    final radius = BorderRadius.circular(GlobalUI.uiRoundness);

    final num = formatEpisodeNumber(episode.number);
    final epLabel = mediaType == MediaType.ANIME
        ? 'EPISODE $num'
        : 'CHAPTER $num';
    final title = (episode.title == null || episode.title!.trim().isEmpty)
        ? (mediaType == MediaType.ANIME ? 'Episode $num' : 'Chapter $num')
        : episode.title!.trim();

    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.55);

    return Material(
      color: isCurrent
          ? cs.primaryContainer.withValues(alpha: 0.28)
          : isWatched
          ? cs.surfaceContainerLowest
          : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isCurrent
            ? BorderSide(color: cs.primary.withValues(alpha: 0.65), width: 1.5)
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? triggerMenuAction,
        onSecondaryTap: onSecondaryTap ?? triggerMenuAction,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 126,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (GlobalUI.uiRoundness * 0.75).clamp(8.0, 14.0),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null && imageUrl!.isNotEmpty)
                          buildImage(
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: cs.surfaceContainerHigh,
                              child: Center(
                                child: Icon(
                                  mediaType == MediaType.ANIME
                                      ? Icons.movie_outlined
                                      : Icons.menu_book_rounded,
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        else
                          ColoredBox(
                            color: cs.surfaceContainerHigh,
                            child: Center(
                              child: Icon(
                                mediaType == MediaType.ANIME
                                    ? Icons.movie_outlined
                                    : Icons.menu_book_rounded,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                                size: 24,
                              ),
                            ),
                          ),
                        if (isWatched) ...[
                          const ColoredBox(color: Colors.black45),
                          Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ] else if (isCurrent) ...[
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: cs.onPrimary,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                        if (isFiller)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: _StatusPill(
                              label: 'FILLER',
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                            color: isCurrent
                                ? cs.primary
                                : (isWatched
                                      ? dimColor
                                      : cs.primary.withValues(alpha: 0.9)),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          _StatusPill(
                            label: isWatched
                                ? (mediaType == MediaType.ANIME
                                      ? 'WATCHED'
                                      : 'READ')
                                : 'PLAYING',
                            backgroundColor: isWatched
                                ? cs.secondaryContainer
                                : cs.primary,
                            foregroundColor: isWatched
                                ? cs.onSecondaryContainer
                                : cs.onPrimary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: isWatched ? dimColor : cs.onSurface,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    if ((displayDate != null && displayDate!.isNotEmpty) ||
                        (episode.scanlator != null &&
                            episode.scanlator!.isNotEmpty) ||
                        (episode.description != null &&
                            episode.description!.trim().isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (displayDate != null &&
                              displayDate!.isNotEmpty) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: dimColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayDate!,
                              style: TextStyle(
                                color: dimColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (episode.scanlator != null &&
                              episode.scanlator!.isNotEmpty) ...[
                            if (displayDate != null && displayDate!.isNotEmpty)
                              Text(
                                '  •  ',
                                style: TextStyle(color: dimColor, fontSize: 10),
                              ),
                            Flexible(
                              child: Text(
                                episode.scanlator!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: dimColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if ((displayDate == null || displayDate!.isEmpty) &&
                              episode.description != null &&
                              episode.description!.trim().isNotEmpty)
                            Flexible(
                              child: Text(
                                episode.description!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: dimColor,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 4),
                Theme(
                  data: theme.copyWith(
                    iconTheme: IconThemeData(
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
