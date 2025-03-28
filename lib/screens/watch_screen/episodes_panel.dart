import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';

class EpisodesPanel extends StatelessWidget {
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final int totalEpisodes;
  final int rangeStart;
  final int itemsPerPage;
  final int gridColumns;
  final bool isGridView;
  final AnimeWatchProgressBox animeWatchProgressBox;
  final anilist_media.Media animeMedia;
  final VoidCallback onToggleLayout;
  final void Function(int) onRangeChange;
  final void Function(int) onItemsPerPageChange;
  final void Function(int) onGridColumnsChange;
  final void Function(int) onEpisodeTap;

  const EpisodesPanel({
    super.key,
    required this.episodes,
    required this.selectedEpisodeIndex,
    required this.totalEpisodes,
    required this.rangeStart,
    required this.itemsPerPage,
    required this.gridColumns,
    required this.isGridView,
    required this.animeWatchProgressBox,
    required this.animeMedia,
    required this.onToggleLayout,
    required this.onRangeChange,
    required this.onItemsPerPageChange,
    required this.onGridColumnsChange,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          _buildControls(context),
          Expanded(child: _buildEpisodesView(context)),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildRangeSelector(context),
          IconButton(
            icon: Icon(isGridView ? Iconsax.element_3 : Iconsax.element_2),
            onPressed: onToggleLayout,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final rangeOptions = _generateRangeOptions();
    final currentRangeLabel = rangeOptions.firstWhere(
      (option) => option['start'] == rangeStart.toString(),
      orElse: () => {'label': 'All Episodes', 'start': '1'},
    )['label']!;

    return PopupMenuButton<String>(
      icon: Row(
        children: [
          const Icon(Iconsax.filter, color: Colors.grey, size: 20),
          const SizedBox(width: 6),
          Text(
            currentRangeLabel,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      onSelected: (value) => onRangeChange(int.parse(value)),
      itemBuilder: (context) => rangeOptions
          .map((option) => PopupMenuItem(
                value: option['start']!,
                child: Text(option['label']!),
              ))
          .toList(),
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      offset: const Offset(0, 32),
    );
  }

  List<Map<String, String>> _generateRangeOptions() {
    final options = <Map<String, String>>[];
    options.add({'label': 'All Episodes', 'start': '1'});
    for (int i = 0; i < (totalEpisodes / itemsPerPage).ceil(); i++) {
      final start = i * itemsPerPage + 1;
      final end = (start + itemsPerPage - 1) > totalEpisodes
          ? totalEpisodes
          : start + itemsPerPage - 1;
      options.add({'label': '$start-$end', 'start': start.toString()});
    }
    return options;
  }

  Widget _buildEpisodesView(BuildContext context) {
    final theme = Theme.of(context);
    final startIdx = rangeStart - 1;
    final endIdx = (startIdx + itemsPerPage > totalEpisodes)
        ? totalEpisodes
        : startIdx + itemsPerPage;
    final episodesInRange = episodes.sublist(startIdx, endIdx);
    final animeProgress =
        animeWatchProgressBox.getAllProgressByAnimeId(animeMedia.id!);

    return isGridView
        ? _buildGridView(episodesInRange, animeProgress, theme)
        : _buildListView(episodesInRange, animeProgress, theme);
  }

  Widget _buildListView(List<EpisodeDataModel> episodesInRange,
      List<dynamic> animeProgress, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: episodesInRange.length,
      itemBuilder: (context, index) {
        final episode = episodesInRange[index];
        final globalIndex = (rangeStart - 1) + index;
        final isSelected = globalIndex == selectedEpisodeIndex;
        final isWatched =
            index < animeProgress.length && animeProgress[index].isCompleted;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isWatched
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primaryContainer,
              child: Text(
                '${episode.number}',
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            title: Text(
              'Episode ${episode.number}',
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14),
            ),
            subtitle: episode.title != null
                ? Text(
                    episode.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  )
                : null,
            trailing: isSelected
                ? Icon(Iconsax.play_circle,
                    color: theme.colorScheme.primary, size: 20)
                : null,
            onTap: () => onEpisodeTap(globalIndex),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<EpisodeDataModel> episodesInRange,
      List<dynamic> animeProgress, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: episodesInRange.length,
      itemBuilder: (context, index) {
        final episode = episodesInRange[index];
        final globalIndex = (rangeStart - 1) + index;
        final isSelected = globalIndex == selectedEpisodeIndex;
        final isWatched =
            index < animeProgress.length && animeProgress[index].isCompleted;

        return GestureDetector(
          onTap: () => onEpisodeTap(globalIndex),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.9)
                      : theme.colorScheme.surfaceContainer,
                  isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.6)
                      : theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${episode.number}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                if (isWatched)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Iconsax.tick_circle,
                      color: theme.colorScheme.secondary,
                      size: 18,
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Icon(
                      Iconsax.play_circle,
                      color: theme.colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
