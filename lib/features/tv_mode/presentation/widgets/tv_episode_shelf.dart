import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_source_dialog.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

class _EpisodeChunk {
  final String label;
  final num? min;
  final num? max;
  const _EpisodeChunk(this.label, this.min, this.max);
}

class TvEpisodeShelf extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final VoidCallback? onOpenSourceSelector;

  const TvEpisodeShelf({
    super.key,
    required this.media,
    this.onOpenSourceSelector,
  });

  @override
  ConsumerState<TvEpisodeShelf> createState() => _TvEpisodeShelfState();
}

class _TvEpisodeShelfState extends ConsumerState<TvEpisodeShelf> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedSeason;
  int _chunkIndex = 0;
  bool _descending = false;
  bool _hasAutoScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;
    final mediaArgs = MediaArgs.fromMedia(widget.media);
    final episodesState = ref.watch(episodesListProvider(mediaArgs));

    final watchHistory =
        ref.watch(historyEpisodesProvider(widget.media.id)).value ?? [];
    final readHistory =
        ref.watch(historyChaptersProvider(widget.media.id)).value ?? [];

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, widget.media)),
    );
    final trackedProgress = trackingState.value?.progress.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        episodesState.when(
          loading: () => _buildLoadingState(cs),
          error: (err, _) => _buildErrorState(context, err, mediaArgs, radius),
          data: (state) {
            if (state.episodes.isEmpty) {
              return _buildEmptyState(context, mediaArgs, radius);
            }

            final uniqueSeasons =
                state.episodes.map((e) => e.season).toSet().toList()
                  ..sort((a, b) {
                    if (a == null) return -1;
                    if (b == null) return 1;
                    return a.compareTo(b);
                  });

            final currentSeason = _selectedSeason ?? uniqueSeasons.firstOrNull;
            final seasonEpisodes = currentSeason != null
                ? state.episodes
                      .where((e) => e.season == currentSeason)
                      .toList()
                : state.episodes;

            final uniqueNums =
                seasonEpisodes.map((e) => e.number).toSet().toList()..sort();

            final chunks = <_EpisodeChunk>[
              const _EpisodeChunk('All', null, null),
            ];

            if (uniqueNums.length > 50) {
              String fmt(num n) =>
                  n % 1 == 0 ? n.toInt().toString() : n.toString();
              final rawChunks = <_EpisodeChunk>[];
              for (int i = 0; i < uniqueNums.length; i += 50) {
                final min = uniqueNums[i];
                final max =
                    uniqueNums[(i + 49).clamp(0, uniqueNums.length - 1)];
                rawChunks.add(
                  _EpisodeChunk('${fmt(min)} – ${fmt(max)}', min, max),
                );
              }
              if (_descending) {
                chunks.addAll(rawChunks.reversed);
              } else {
                chunks.addAll(rawChunks);
              }
            }

            final safeChunkIdx = _chunkIndex < chunks.length ? _chunkIndex : 0;
            final activeChunk = chunks[safeChunkIdx];
            final prefScanlator = ref.read(
              preferredScanlatorProvider(widget.media.id),
            );

            final dedupedMap = <double, UnifiedEpisode>{};
            for (final ep in seasonEpisodes) {
              if (activeChunk.min != null &&
                  (ep.number < activeChunk.min! ||
                      ep.number > activeChunk.max!)) {
                continue;
              }
              if (!dedupedMap.containsKey(ep.number) ||
                  ep.scanlator == prefScanlator) {
                dedupedMap[ep.number] = ep;
              }
            }

            final finalEpisodes = dedupedMap.values.toList()
              ..sort(
                (a, b) => _descending
                    ? b.number.compareTo(a.number)
                    : a.number.compareTo(b.number),
              );

            final isManga =
                widget.media.type == MediaType.MANGA ||
                widget.media.type == MediaType.NOVEL;

            int activeIndex = -1;
            if (isManga) {
              final latestRead = readHistory.firstOrNull;
              if (latestRead != null) {
                activeIndex = finalEpisodes.indexWhere(
                  (e) => (e.number - latestRead.chapterNumber).abs() < 0.01,
                );
              }
            } else {
              final latestWatch = watchHistory.firstOrNull;
              if (latestWatch != null) {
                activeIndex = finalEpisodes.indexWhere(
                  (e) => (e.number - latestWatch.episodeNumber).abs() < 0.01,
                );
              }
            }
            if (activeIndex == -1 && trackedProgress > 0) {
              activeIndex = finalEpisodes.indexWhere(
                (e) => e.number > trackedProgress,
              );
            }

            if (!_hasAutoScrolled && activeIndex > 0) {
              _hasAutoScrolled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  final targetOffset = (activeIndex * 256.0).clamp(
                    0.0,
                    _scrollController.position.maxScrollExtent,
                  );
                  _scrollController.animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                }
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Text(
                              isManga ? 'Chapters' : 'Episodes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${finalEpisodes.length})',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        if (uniqueSeasons.length > 1) ...[
                          ...uniqueSeasons.map((season) {
                            final isSelected = season == currentSeason;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TvFocusable(
                                onTap: () => setState(() {
                                  _selectedSeason = season;
                                  _chunkIndex = 0;
                                  _hasAutoScrolled = false;
                                }),
                                builder: (context, isFocused, isHovered) {
                                  final active = isFocused || isHovered;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : isSelected
                                          ? cs.primary.withValues(alpha: 0.2)
                                          : Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        radius,
                                      ),
                                    ),
                                    child: Text(
                                      season == null
                                          ? 'Default Season'
                                          : 'Season $season',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.black
                                            : isSelected
                                            ? cs.primary
                                            : Colors.white70,
                                        fontWeight: isSelected || active
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                        ],
                        if (chunks.length > 1) ...[
                          ...chunks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final chunk = entry.value;
                            final isSelected = idx == safeChunkIdx;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TvFocusable(
                                onTap: () => setState(() {
                                  _chunkIndex = idx;
                                  _hasAutoScrolled = false;
                                }),
                                builder: (context, isFocused, isHovered) {
                                  final active = isFocused || isHovered;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : isSelected
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        radius,
                                      ),
                                    ),
                                    child: Text(
                                      chunk.label,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.black
                                            : isSelected
                                            ? Colors.white
                                            : Colors.white60,
                                        fontWeight: isSelected || active
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                        ],
                        TvFocusable(
                          onTap: () => setState(() {
                            _descending = !_descending;
                            _hasAutoScrolled = false;
                          }),
                          builder: (context, isFocused, isHovered) {
                            final active = isFocused || isHovered;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _descending
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 13,
                                    color: active
                                        ? Colors.black
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _descending ? 'Newest' : 'Oldest',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.black
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        TvFocusable(
                          onTap: () {
                            if (widget.onOpenSourceSelector != null) {
                              widget.onOpenSourceSelector!();
                            } else {
                              TvSourceDialog.show(
                                context,
                                media: widget.media,
                                currentSource: state.source,
                              );
                            }
                          },
                          builder: (context, isFocused, isHovered) {
                            final active = isFocused || isHovered;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : cs.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 13,
                                    color: active ? Colors.black : cs.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    state.source.name,
                                    style: TextStyle(
                                      color: active ? Colors.black : cs.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView.separated(
                      key: ValueKey('tv_shelf_${state.source.id}_$_chunkIndex'),
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 6),
                      itemCount: finalEpisodes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final episode = finalEpisodes[index];

                        double progressPercent = 0.0;
                        bool isCompleted = false;

                        if (isManga) {
                          final historyEntry = readHistory
                              .where(
                                (e) =>
                                    (e.chapterNumber - episode.number).abs() <
                                    0.01,
                              )
                              .firstOrNull;
                          if (historyEntry != null &&
                              historyEntry.totalPages > 0) {
                            progressPercent =
                                (historyEntry.positionPage /
                                        historyEntry.totalPages)
                                    .clamp(0.0, 1.0);
                            isCompleted =
                                historyEntry.positionPage >=
                                historyEntry.totalPages;
                          } else if (trackedProgress >= episode.number) {
                            progressPercent = 1.0;
                            isCompleted = true;
                          }
                        } else {
                          final historyEntry = watchHistory
                              .where(
                                (e) =>
                                    (e.episodeNumber - episode.number).abs() <
                                    0.01,
                              )
                              .firstOrNull;
                          if (historyEntry != null &&
                              historyEntry.durationInMilliseconds > 0) {
                            progressPercent =
                                (historyEntry.positionInMilliseconds /
                                        historyEntry.durationInMilliseconds)
                                    .clamp(0.0, 1.0);
                            isCompleted =
                                historyEntry.positionInMilliseconds >=
                                historyEntry.durationInMilliseconds * 0.9;
                          } else if (trackedProgress >= episode.number) {
                            progressPercent = 1.0;
                            isCompleted = true;
                          }
                        }

                        return _TvEpisodeCard(
                          episode: episode,
                          media: widget.media,
                          source: state.source,
                          progressPercent: progressPercent,
                          isCompleted: isCompleted,
                          radius: radius,
                          onTap: () => _handleEpisodeTap(
                            context,
                            episode,
                            state.source,
                            watchHistory,
                            readHistory,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _handleEpisodeTap(
    BuildContext context,
    UnifiedEpisode episode,
    SourceInfo sourceInfo,
    List<WatchHistoryEntry> watchHistory,
    List<ReadHistoryEntry> readHistory,
  ) {
    if (widget.media.type == MediaType.MANGA ||
        widget.media.type == MediaType.NOVEL) {
      final historyEntry = readHistory
          .where((e) => (e.chapterNumber - episode.number).abs() < 0.01)
          .firstOrNull;

      final int startPosition;
      if (historyEntry != null &&
          historyEntry.positionPage > 0 &&
          historyEntry.positionPage <= historyEntry.totalPages) {
        startPosition = historyEntry.positionPage;
      } else {
        startPosition = 1;
      }

      context.pushReader(
        ReaderModeOnline(
          media: widget.media,
          episode: episode,
          sourceInfo: sourceInfo,
          startPosition: startPosition,
        ),
      );
    } else {
      final historyEntry = watchHistory
          .where((e) => (e.episodeNumber - episode.number).abs() < 0.01)
          .firstOrNull;

      final Duration? startPosition;
      final isFinished =
          historyEntry != null &&
          historyEntry.durationInMilliseconds > 0 &&
          historyEntry.positionInMilliseconds >=
              historyEntry.durationInMilliseconds * 0.9;
      if (historyEntry != null &&
          historyEntry.positionInMilliseconds > 0 &&
          !isFinished) {
        startPosition = Duration(
          milliseconds: historyEntry.positionInMilliseconds,
        );
      } else {
        startPosition = null;
      }

      context.pushPlayer(
        PlayerModeOnline(
          media: widget.media,
          episode: episode,
          sourceInfo: sourceInfo,
          startPosition: startPosition,
        ),
      );
    }
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 140,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 220,
                      height: 124,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 160,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 90,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    MediaArgs mediaArgs,
    double radius,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Colors.white30),
          const SizedBox(height: 10),
          const Text(
            'No content found for this source',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          TvFocusable(
            onTap: () {
              if (widget.onOpenSourceSelector != null) {
                widget.onOpenSourceSelector!();
              } else {
                TvSourceDialog.show(context, media: widget.media);
              }
            },
            builder: (context, isFocused, isHovered) {
              final active = isFocused || isHovered;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Text(
                  'Switch Source',
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    MediaArgs mediaArgs,
    double radius,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load episodes: $error',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TvFocusable(
                onTap: () => ref.refresh(episodesListProvider(mediaArgs)),
                builder: (context, isFocused, isHovered) {
                  final active = isFocused || isHovered;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              TvFocusable(
                onTap: () {
                  if (widget.onOpenSourceSelector != null) {
                    widget.onOpenSourceSelector!();
                  } else {
                    TvSourceDialog.show(context, media: widget.media);
                  }
                },
                builder: (context, isFocused, isHovered) {
                  final active = isFocused || isHovered;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Text(
                      'Change Source',
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TvEpisodeCard extends StatelessWidget {
  final UnifiedEpisode episode;
  final UnifiedMedia media;
  final SourceInfo source;
  final double progressPercent;
  final bool isCompleted;
  final double radius;
  final VoidCallback onTap;

  const _TvEpisodeCard({
    required this.episode,
    required this.media,
    required this.source,
    required this.progressPercent,
    required this.isCompleted,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageUrl = episode.thumbnailUrl?.isNotEmpty == true
        ? episode.thumbnailUrl!
        : (media.banner?.isNotEmpty == true
              ? media.banner!
              : (media.cover ?? ''));

    final epTitle = episode.title?.isNotEmpty == true
        ? episode.title!
        : (media.type == MediaType.MANGA
              ? 'Chapter ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}'
              : 'Episode ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}');

    return TvFocusable(
      onTap: onTap,
      scaleFactor: 1.04,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isCompleted && !active ? 0.55 : 1.0,
          child: SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 135,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (radius - 2).clamp(0.0, double.infinity),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white10,
                              child: const Icon(
                                Icons.movie_outlined,
                                color: Colors.white24,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: Colors.white24,
                            ),
                          ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.6).clamp(0.0, radius),
                              ),
                            ),
                            child: Text(
                              media.type == MediaType.MANGA
                                  ? 'CH ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}'
                                  : 'EP ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 10,
                              ),
                            ),
                          ),
                        if (progressPercent > 0.0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 2.5,
                              color: Colors.white24,
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progressPercent,
                                child: Container(color: cs.primary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  epTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (episode.airDate != null && episode.airDate!.isNotEmpty)
                      Text(
                        formatAirDate(episode.airDate) ?? episode.airDate!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      )
                    else
                      Text(
                        media.type == MediaType.MANGA ? 'Chapter' : 'Episode',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    if (episode.isFiller) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            (radius * 0.5).clamp(0.0, radius),
                          ),
                        ),
                        child: const Text(
                          'FILLER',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
