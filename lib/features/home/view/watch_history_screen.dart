import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  ConsumerState<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  bool _isBatchMode = false;
  final Set<String> _selectedAnimeIds = {};
  String _filter = 'All'; // All, Completed, In Progress

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = ref.watch(watchProgressRepositoryProvider);
    final allProgress = repository.getAllProgress();

    // Apply filter
    final filteredProgress = allProgress.where((entry) {
      if (_filter == 'All') return true;
      return true;
    }).toList();

    // Sort by last updated descending
    filteredProgress.sort((a, b) =>
        (b.lastUpdated ?? DateTime(0)).compareTo(a.lastUpdated ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History'),
        actions: [
          if (_isBatchMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isBatchMode = false;
                  _selectedAnimeIds.clear();
                });
              },
              child: const Text('Cancel'),
            )
          else
            IconButton(
              icon: const Icon(Iconsax.task_square),
              tooltip: 'Batch Select',
              onPressed: () {
                setState(() {
                  _isBatchMode = true;
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.filter),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              // Add more filters if we enhance the model to support them
            ],
          ),
        ],
      ),
      body: filteredProgress.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.clock,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No watch history yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredProgress.length,
              padding: const EdgeInsets.only(bottom: 80),
              itemBuilder: (context, index) {
                final entry = filteredProgress[index];
                final isSelected = _selectedAnimeIds.contains(entry.animeId);

                return _HistoryEntryTile(
                  entry: entry,
                  isBatchMode: _isBatchMode,
                  isSelected: isSelected,
                  onSelect: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedAnimeIds.add(entry.animeId);
                      } else {
                        _selectedAnimeIds.remove(entry.animeId);
                      }
                    });
                  },
                  onDeleteAnime: () async {
                    await repository.deleteProgress(entry.animeId);
                    setState(() {}); // Refresh UI
                  },
                  onDeleteEpisode: (episodeNumber) async {
                    await repository.deleteEpisodeProgress(
                        entry.animeId, episodeNumber);
                    setState(() {}); // Refresh UI
                  },
                );
              },
            ),
      bottomNavigationBar: _isBatchMode && _selectedAnimeIds.isNotEmpty
          ? BottomAppBar(
              child: Row(
                children: [
                  Text(
                    '${_selectedAnimeIds.length} selected',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      await repository
                          .deleteMultipleProgress(_selectedAnimeIds.toList());
                      setState(() {
                        _isBatchMode = false;
                        _selectedAnimeIds.clear();
                      });
                    },
                    icon: const Icon(Iconsax.trash),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  final AnimeWatchProgressEntry entry;
  final bool isBatchMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onDeleteAnime;
  final Function(int) onDeleteEpisode;

  const _HistoryEntryTile({
    required this.entry,
    required this.isBatchMode,
    required this.isSelected,
    required this.onSelect,
    required this.onDeleteAnime,
    required this.onDeleteEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodes = entry.episodesProgress.values.toList()
      ..sort((a, b) => b.episodeNumber.compareTo(a.episodeNumber));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: isBatchMode
            ? Checkbox(
                value: isSelected,
                onChanged: onSelect,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  entry.animeCover,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 60,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Iconsax.image),
                  ),
                ),
              ),
        title: Text(
          entry.animeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Last watched: Ep ${entry.currentEpisode}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: isBatchMode
            ? null
            : IconButton(
                icon: const Icon(Iconsax.trash, size: 20),
                onPressed: onDeleteAnime,
                tooltip: 'Delete Anime Progress',
              ),
        children: [
          if (!isBatchMode)
            ...episodes.map((ep) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(
                    'Episode ${ep.episodeNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${_formatDuration(ep.progressInSeconds!)} / ${_formatDuration(ep.durationInSeconds!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.close_circle, size: 18),
                    onPressed: () => onDeleteEpisode(ep.episodeNumber),
                    color: theme.colorScheme.error,
                    tooltip: 'Remove Episode',
                  ),
                )),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
