import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dismissible_page/dismissible_page.dart';

class EpisodesList extends StatefulWidget {
  final AnimeItem anime;
  final ValueNotifier<List<Episode>> episodes;
  final ValueNotifier<bool> isLoading;
  final int rangeSize;
  final List<String?>? watchedEpisodes;

  const EpisodesList({
    super.key,
    required this.anime,
    required this.episodes,
    required this.isLoading,
    this.rangeSize = 50,
    this.watchedEpisodes = const [],
  });

  @override
  State<EpisodesList> createState() => _EpisodesListState();
}

class _EpisodesListState extends State<EpisodesList> {
  bool _isGridLayout = false;
  int _selectedRangeIndex = 0;

  void _navigateToStreamScreen(BuildContext context, Episode episode) {
    context.push(
      '/stream',
      extra: {
        'episodes': widget.episodes.value,
        'anime': widget.anime,
        'episode': episode,
      },
    );
  }

  List<Map<String, List<Episode>>> _getGroupedEpisodes(List<Episode> episodes) {
    if (episodes.isEmpty) return [];
    return List.generate(
      (episodes.length / widget.rangeSize).ceil(),
      (index) {
        final start = index * widget.rangeSize + 1;
        final end = (start + widget.rangeSize - 1).clamp(1, episodes.length);
        return {
          '$start - $end': episodes.sublist(
            index * widget.rangeSize,
            (index + 1) * widget.rangeSize > episodes.length
                ? episodes.length
                : (index + 1) * widget.rangeSize,
          )
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isLoading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<Episode>>(
          valueListenable: widget.episodes,
          builder: (context, episodes, _) {
            final groupedEpisodes = _getGroupedEpisodes(episodes);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EpisodesHeader(
                  episodes: episodes,
                  rangeSize: widget.rangeSize,
                  groupedEpisodes: groupedEpisodes,
                  isGridLayout: _isGridLayout,
                  selectedRangeIndex: _selectedRangeIndex,
                  onLayoutChanged: (isGrid) {
                    setState(() => _isGridLayout = isGrid);
                  },
                  onRangeChanged: (index) {
                    setState(() => _selectedRangeIndex = index);
                  },
                ),
                isLoading
                    ? _buildShimmerList(context)
                    : _EpisodesView(
                        episodes: episodes,
                        watchedEpisodes: widget.watchedEpisodes,
                        groupedEpisodes: groupedEpisodes,
                        rangeSize: widget.rangeSize,
                        isGridLayout: _isGridLayout,
                        selectedRangeIndex: _selectedRangeIndex,
                        onEpisodeSelected: (episode) =>
                            _navigateToStreamScreen(context, episode),
                      ),
                const SizedBox(height: 25),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.primaryContainer,
      highlightColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            height: 70.0,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: (Theme.of(context).cardTheme.shape
                        as RoundedRectangleBorder)
                    .borderRadius),
          ),
        ),
      ),
    );
  }
}

class _EpisodesHeader extends StatelessWidget {
  final List<Episode> episodes;
  final List<Map<String, List<Episode>>> groupedEpisodes;
  final int rangeSize;
  final bool isGridLayout;
  final int selectedRangeIndex;
  final ValueChanged<bool> onLayoutChanged;
  final ValueChanged<int> onRangeChanged;

  const _EpisodesHeader({
    required this.episodes,
    required this.groupedEpisodes,
    required this.rangeSize,
    required this.isGridLayout,
    required this.selectedRangeIndex,
    required this.onLayoutChanged,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Episodes",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Row(
          children: [
            if (groupedEpisodes.isNotEmpty)
              DropdownButton<int>(
                value: selectedRangeIndex,
                onChanged: (newIndex) {
                  if (newIndex != null) {
                    onRangeChanged(newIndex);
                  }
                },
                items: groupedEpisodes.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      entry.value.keys.first,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  );
                }).toList(),
              ),
            IconButton(
              icon: Icon(
                isGridLayout ? Icons.view_list : Icons.grid_view,
              ),
              onPressed: () => onLayoutChanged(!isGridLayout),
            ),
          ],
        ),
      ],
    );
  }
}

class _EpisodesView extends StatelessWidget {
  final List<Episode> episodes;
  final List<String?>? watchedEpisodes;
  final List<Map<String, List<Episode>>> groupedEpisodes;
  final int rangeSize;
  final bool isGridLayout;
  final int selectedRangeIndex;
  final ValueChanged<Episode> onEpisodeSelected;

  const _EpisodesView(
      {required this.episodes,
      required this.groupedEpisodes,
      required this.rangeSize,
      required this.isGridLayout,
      required this.selectedRangeIndex,
      required this.onEpisodeSelected,
      required this.watchedEpisodes});

  @override
  Widget build(BuildContext context) {
    if (groupedEpisodes.isEmpty) {
      return const Center(child: Text('No episodes available'));
    }

    final currentEpisodes = groupedEpisodes[selectedRangeIndex].values.first;

    return isGridLayout
        ? _buildGridView(context, currentEpisodes)
        : _buildListView(context, currentEpisodes);
  }

  Widget _buildListView(BuildContext context, List<Episode> episodes) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isWatched = watchedEpisodes?.contains(episode.episodeId) ?? false;

        return _EpisodeTile(
          episode: episode,
          onTap: () => onEpisodeSelected(episode),
          isWatched: isWatched,
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<Episode> episodes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isWatched = watchedEpisodes?.contains(episode.episodeId) ?? false;

        return _EpisodeGridTile(
          episode: episode,
          onTap: () => onEpisodeSelected(episode),
          isWatched: isWatched,
        );
      },
    );
  }
}

class _EpisodeGridTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final bool isWatched;

  const _EpisodeGridTile({
    required this.episode,
    required this.onTap,
    required this.isWatched,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius:
              (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                  .borderRadius,
          border: !episode.isFiller
              ? null
              : Border.all(
                  color: themeData.colorScheme.secondaryContainer, width: 2),
          gradient: LinearGradient(
            colors: isWatched
                ? [
                    themeData.colorScheme.secondaryContainer,
                    themeData.colorScheme.secondaryContainer
                        .withValues(alpha: 0.2),
                  ]
                : [
                    !episode.isFiller
                        ? themeData.colorScheme.primaryContainer
                            .withValues(alpha: 0.4)
                        : themeData.colorScheme.primaryContainer,
                    !episode.isFiller
                        ? themeData.colorScheme.secondaryContainer
                            .withValues(alpha: 0.7)
                        : themeData.colorScheme.secondaryContainer,
                  ],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "${episode.number}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (episode.isFiller || isWatched)
                Flexible(
                  child: Text(
                    " ${isWatched ? 'DONE' : 'FILLER'}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final bool isWatched;

  const _EpisodeTile({
    required this.episode,
    required this.onTap,
    required this.isWatched,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      shape: RoundedRectangleBorder(
        borderRadius:
            (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                .borderRadius,
        side: !episode.isFiller
            ? BorderSide.none
            : BorderSide(color: themeData.colorScheme.primaryContainer),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isWatched
                ? [
                    themeData.colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    themeData.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                  ]
                : [
                    !episode.isFiller
                        ? themeData.colorScheme.primaryContainer
                        : themeData.colorScheme.error.withValues(alpha: 0.5),
                    !episode.isFiller
                        ? themeData.colorScheme.primaryContainer
                            .withValues(alpha: 0.6)
                        : themeData.colorScheme.error.withValues(alpha: 0.3),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            "EP : ${episode.number} ${isWatched ? '- Watched' : episode.isFiller ? " : FILLER" : ""}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            episode.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlay,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}
