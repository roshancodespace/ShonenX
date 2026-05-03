import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class _EpisodeChunk {
  final String label;
  final double? min;
  final double? max;

  _EpisodeChunk(this.label, this.min, this.max);
}

class EpisodesTabWidget extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  const EpisodesTabWidget({super.key, required this.media});

  @override
  ConsumerState<EpisodesTabWidget> createState() => _EpisodesTabWidgetState();
}

class _EpisodesTabWidgetState extends ConsumerState<EpisodesTabWidget> {
  bool _isDescending = false;
  int _selectedChunkIndex = 0;

  void _toggleSort() {
    setState(() {
      _isDescending = !_isDescending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.media.title.availableTitle;
    final episodesAsync = widget.media.sourceId != null
        ? ref.watch(
            sourceEpisodesProvider((
              providerId: widget.media.id,
              sourceId: widget.media.sourceId!,
            )),
          )
        : ref.watch(episodesListProvider(title));

    return Column(
      children: [
        _EpisodesHeader(media: widget.media),
        const SizedBox(height: 10),
        episodesAsync.when(
          data: (state) {
            final sortedNums = state.episodes.map((e) => e.number).toList()
              ..sort();
            final chunks = <_EpisodeChunk>[_EpisodeChunk('All', null, null)];

            if (sortedNums.length > 100) {
              for (int i = 0; i < sortedNums.length; i += 100) {
                int endIdx = i + 99 < sortedNums.length
                    ? i + 99
                    : sortedNums.length - 1;
                double min = sortedNums[i];
                double max = sortedNums[endIdx];
                String minStr = min % 1 == 0
                    ? min.toInt().toString()
                    : min.toString();
                String maxStr = max % 1 == 0
                    ? max.toInt().toString()
                    : max.toString();
                chunks.add(_EpisodeChunk('$minStr - $maxStr', min, max));
              }
            }

            final safeIndex = _selectedChunkIndex < chunks.length
                ? _selectedChunkIndex
                : 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        '${state.episodes.length} episodes',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleSort,
                        icon: Icon(
                          _isDescending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                        tooltip: _isDescending
                            ? 'Sort Ascending'
                            : 'Sort Descending',
                      ),
                    ],
                  ),
                ),
                if (chunks.length > 1) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      itemCount: chunks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final chunk = chunks[index];
                        final isSelected = safeIndex == index;
                        final theme = Theme.of(context);

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChunkIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceBright,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                chunk.label,
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
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            );
          },
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          loading: () => const SizedBox.shrink(),
        ),
        const Divider(),
        Expanded(
          child: _EpisodesList(
            media: widget.media,
            isDescending: _isDescending,
            selectedChunkIndex: _selectedChunkIndex,
          ),
        ),
      ],
    );
  }
}

class _EpisodesHeader extends ConsumerWidget {
  final UnifiedMedia media;

  const _EpisodesHeader({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = media.title.availableTitle;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Source Mode: media came from a direct source, no matching needed.
    if (media.sourceId != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOURCE',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    title,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tracker Mode: show matched media info.
    final sourceState = ref.watch(sourcePreferenceProvider(title)).value;

    final matchedTitle = ref.watch(
      matchedMediaProvider(title).select((s) => s.value?.matchedMedia?.title),
    );

    final sourceName = sourceState?.sourceInfo.name ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCHED (by $sourceName)',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  matchedTitle ?? 'Searching...',
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSourceSelector(
              context,
              ref,
              title,
              sourceState?.sourceInfo,
            ),
            icon: const Icon(Icons.swap_horiz),
            label: Text(sourceName, style: textTheme.labelLarge),
          ),
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) =>
                  ManualMatchSheet(mediaTitle: title, type: media.type),
            ),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Manual Match',
          ),
        ],
      ),
    );
  }

  void _showSourceSelector(
    BuildContext context,
    WidgetRef ref,
    String title,
    SourceInfo? currentSource,
  ) {
    final availableSources =
        ref.read(availableAnimeSourcesProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return AppBottomSheet(
          title: title,
          child: ListView.builder(
            itemCount: availableSources.length,
            itemBuilder: (context, index) {
              final sourceInfo = availableSources[index];

              return ListTile(
                title: Text(sourceInfo.name),
                trailing: currentSource == sourceInfo
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(sourcePreferenceProvider(title).notifier)
                      .updateSource(sourceInfo);
                  Navigator.pop(sheetContext);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EpisodesList extends ConsumerWidget {
  final UnifiedMedia media;
  final bool isDescending;
  final int selectedChunkIndex;

  const _EpisodesList({
    required this.media,
    required this.isDescending,
    required this.selectedChunkIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = media.title.availableTitle;
    final episodesAsync = media.sourceId != null
        ? ref.watch(
            sourceEpisodesProvider((
              providerId: media.id,
              sourceId: media.sourceId!,
            )),
          )
        : ref.watch(episodesListProvider(title));

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final query = TrackingQuery(primaryTracker.type, media.id);
    final trackingState = ref.watch(mediaTrackingProvider(query));
    final watchedProgress = trackingState.value?.progress ?? 0;

    return episodesAsync.when(
      data: (state) {
        if (state.episodes.isEmpty) {
          return Center(child: Text('No episodes found.'));
        }

        final sortedNums = state.episodes.map((e) => e.number).toList()..sort();
        final chunks = <_EpisodeChunk>[_EpisodeChunk('All', null, null)];

        if (sortedNums.length > 100) {
          for (int i = 0; i < sortedNums.length; i += 100) {
            int endIdx = i + 99 < sortedNums.length
                ? i + 99
                : sortedNums.length - 1;
            chunks.add(_EpisodeChunk('', sortedNums[i], sortedNums[endIdx]));
          }
        }

        final safeIndex = selectedChunkIndex < chunks.length
            ? selectedChunkIndex
            : 0;
        final activeChunk = chunks[safeIndex];

        var filteredEpisodes = state.episodes;
        if (activeChunk.min != null && activeChunk.max != null) {
          filteredEpisodes = filteredEpisodes.where((e) {
            return e.number >= activeChunk.min! && e.number <= activeChunk.max!;
          }).toList();
        }

        final sortedEpisodes = List.of(filteredEpisodes);

        sortedEpisodes.sort(
          (a, b) => isDescending
              ? b.number.compareTo(a.number)
              : a.number.compareTo(b.number),
        );

        return ListView.builder(
          itemCount: sortedEpisodes.length,
          itemBuilder: (context, index) {
            final episode = sortedEpisodes[index];
            final isWatched = watchedProgress >= episode.number;

            return _EpisodeTile(
              episode: episode,
              media: media,
              sourceInfo: state.source,
              isWatched: isWatched,
            );
          },
        );
      },
      error: (error, stack) =>
          const Center(child: Text('Error loading episodes')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final UnifiedEpisode episode;
  final UnifiedMedia media;
  final SourceInfo sourceInfo;
  final bool isWatched;

  const _EpisodeTile({
    required this.episode,
    required this.media,
    required this.sourceInfo,
    required this.isWatched,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedNumber = episode.number.toString().contains('.0')
        ? episode.number.toInt().toString()
        : episode.number.toString();
    final dimColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return InkWell(
      onTap: () {
        context.push(
          '/player',
          extra: PlayerParams(
            media: media,
            episode: episode,
            sourceInfo: sourceInfo,
          ),
        );
      },
      child: Container(
        decoration:
            episode.thumbnailUrl != null && episode.thumbnailUrl!.isNotEmpty
            ? BoxDecoration(
                image: DecorationImage(
                  alignment: Alignment.centerLeft,
                  opacity: isWatched ? 0.15 : 0.3,
                  fit: BoxFit.fitWidth,
                  image: CachedNetworkImageProvider(
                    episode.thumbnailUrl!.split('#').first,
                    headers: {'Referer': episode.thumbnailUrl!.split('#').last},
                  ),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isWatched
                            ? dimColor
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        isWatched
                            ? Icons.check_circle
                            : Icons.play_circle_fill_rounded,
                        size: 30,
                        color: isWatched ? dimColor : theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isWatched
                            ? dimColor
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EPISODE $formattedNumber',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isWatched
                                ? dimColor
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          episode.title ?? 'Episode $formattedNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isWatched
                                ? dimColor
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
