import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

class _Chunk {
  final String label;
  final double? min;
  final double? max;
  _Chunk(this.label, this.min, this.max);
}

class EpisodeListPanel extends ConsumerStatefulWidget {
  final UnifiedMedia media;

  final double? currentEpisodeNumber;
  final double watchedProgress;

  final void Function(UnifiedEpisode episode, SourceInfo sourceInfo)
  onEpisodeTap;

  final List<Widget> Function(
    BuildContext context,
    UnifiedEpisode episode,
    bool isCurrent,
    bool isWatched,
  )?
  episodeActionsBuilder;

  final EpisodeImageFadeDirection imageFadeDirection;
  final List<double>? imageFadeStops;
  final double imageOpacity;
  final double imageBlurSigma;

  const EpisodeListPanel({
    super.key,
    required this.media,
    required this.onEpisodeTap,
    this.currentEpisodeNumber,
    this.watchedProgress = 0,
    this.episodeActionsBuilder,
    this.imageFadeDirection = EpisodeImageFadeDirection.left,
    this.imageFadeStops,
    this.imageOpacity = 0.3,
    this.imageBlurSigma = 0,
  });

  @override
  ConsumerState<EpisodeListPanel> createState() => _EpisodeListPanelState();
}

class _EpisodeListPanelState extends ConsumerState<EpisodeListPanel> {
  bool _descending = false;
  int _chunkIndex = 0;

  @override
  Widget build(BuildContext context) {
    final episodesAsync = widget.media.sourceId != null
        ? ref.watch(
            sourceEpisodesProvider((
              providerId: widget.media.id,
              sourceId: widget.media.sourceId!,
            )),
          )
        : ref.watch(episodesListProvider(widget.media.title.availableTitle));

    return episodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.episodes.isEmpty) {
          return const Center(child: Text('No episodes found.'));
        }

        final nums = state.episodes.map((e) => e.number).toList()..sort();

        final chunks = <_Chunk>[_Chunk('All', null, null)];

        if (nums.length > 100) {
          for (int i = 0; i < nums.length; i += 100) {
            final endIdx = (i + 99 < nums.length) ? i + 99 : nums.length - 1;

            final mn = nums[i];
            final mx = nums[endIdx];

            final mnS = mn % 1 == 0 ? mn.toInt().toString() : mn.toString();

            final mxS = mx % 1 == 0 ? mx.toInt().toString() : mx.toString();

            chunks.add(_Chunk('$mnS – $mxS', mn, mx));
          }
        }

        final safeIdx = _chunkIndex < chunks.length ? _chunkIndex : 0;
        final active = chunks[safeIdx];

        var filtered = state.episodes.where((e) {
          if (active.min == null) return true;

          return e.number >= active.min! && e.number <= active.max!;
        }).toList();

        filtered.sort(
          (a, b) => _descending
              ? b.number.compareTo(a.number)
              : a.number.compareTo(b.number),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Text(
                      '${state.episodes.length} episodes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _descending = !_descending;
                        });
                      },
                      icon: Icon(
                        _descending ? Icons.arrow_downward : Icons.arrow_upward,
                      ),
                      iconSize: 18,
                      tooltip: _descending
                          ? 'Sort Ascending'
                          : 'Sort Descending',
                    ),
                  ],
                ),
              ),
            ),

            if (chunks.length > 1) ...[
              StaggeredFadeIn(
                index: 3,
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: chunks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isSelected = safeIdx == i;
                      final theme = Theme.of(context);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _chunkIndex = i;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceBright,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            chunks[i].label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 6),
            ],

            StaggeredFadeIn(
              index: chunks.length > 1 ? 4 : 3,
              child: const Divider(height: 1),
            ),

            Expanded(
              child: StaggeredFadeIn(
                index: chunks.length > 1 ? 5 : 4,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final episode = filtered[i];

                    final isCurrent =
                        widget.currentEpisodeNumber == episode.number;

                    final isWatched = widget.watchedProgress >= episode.number;

                    return _EpisodePanelTile(
                      episode: episode,
                      isCurrent: isCurrent,
                      isWatched: isWatched,
                      imageFadeDirection: widget.imageFadeDirection,
                      imageFadeStops: widget.imageFadeStops,
                      imageOpacity: widget.imageOpacity,
                      imageBlurSigma: widget.imageBlurSigma,
                      actions:
                          widget.episodeActionsBuilder?.call(
                            context,
                            episode,
                            isCurrent,
                            isWatched,
                          ) ??
                          const [],
                      onTap: () {
                        widget.onEpisodeTap(episode, state.source);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum EpisodeImageFadeDirection {
  horizontal,
  vertical,
  left,
  right,
  top,
  bottom,
}

class _EpisodePanelTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final bool isCurrent;
  final bool isWatched;
  final VoidCallback onTap;

  final EpisodeImageFadeDirection imageFadeDirection;
  final List<double>? imageFadeStops;
  final double imageOpacity;
  final double imageBlurSigma;

  final List<Widget> actions;

  const _EpisodePanelTile({
    required this.episode,
    required this.isCurrent,
    required this.isWatched,
    required this.onTap,
    this.imageFadeDirection = EpisodeImageFadeDirection.left,
    this.imageFadeStops,
    this.imageOpacity = 0.3,
    this.imageBlurSigma = 0,
    this.actions = const [],
  });

  Alignment _beginAlignment() {
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

  Alignment _endAlignment() {
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

    final labelColor = isCurrent
        ? theme.colorScheme.primary
        : isEffectivelyWatched
        ? dimColor
        : theme.colorScheme.primary;

    final titleColor = isCurrent
        ? theme.colorScheme.onSurface
        : isEffectivelyWatched
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
                                begin: _beginAlignment(),
                                end: _endAlignment(),
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
                            isCurrent
                                ? Icons.play_circle_fill_rounded
                                : isEffectivelyWatched
                                ? Icons.check_circle
                                : Icons.play_circle_fill_rounded,
                            size: 28,
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : isEffectivelyWatched
                                ? dimColor
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
                                      color: labelColor,
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
                                    episode.title ?? 'Episode $num',
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
