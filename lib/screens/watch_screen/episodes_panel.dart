import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/providers/watch_providers.dart';

class EpisodesPanel extends ConsumerStatefulWidget {
  final String animeId;
  const EpisodesPanel({super.key, required this.animeId});

  @override
  ConsumerState<EpisodesPanel> createState() => _EpisodesPanelState();
}

class _EpisodesPanelState extends ConsumerState<EpisodesPanel> {
  int _rangeSize = 50; // Default range size
  int _currentStart = 1; // Current range start

  List<Map<String, int>> _generateRanges(int totalEpisodes, int rangeSize) {
    final ranges = <Map<String, int>>[];
    for (int start = 1; start <= totalEpisodes; start += rangeSize) {
      final end = (start + rangeSize - 1).clamp(0, totalEpisodes);
      ranges.add({'start': start, 'end': end});
      if (end >= totalEpisodes) break;
    }
    return ranges;
  }

  void _showRangeSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Range Size"),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [10, 25, 50, 100].map((size) {
                final isSelected = _rangeSize == size;
                return ChoiceChip(
                  label: Text("$size"),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _rangeSize = size;
                        _currentStart = 1; // Reset to first range
                      });
                      Navigator.pop(context);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchState = ref.watch(watchProvider);
    final totalEpisodes = watchState.episodes.length;
    final ranges = _generateRanges(totalEpisodes, _rangeSize);

    // Filter episodes based on the current range
    final filteredEpisodes = watchState.episodes.where((episode) {
      final epNumber = int.parse(episode.number.toString());
      return epNumber >= _currentStart &&
          epNumber <= (_currentStart + _rangeSize - 1);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ranges.map((range) {
                      final isSelected = _currentStart == range['start'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text("${range['start']}-${range['end']}"),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _currentStart = range['start'] ?? 1;
                              });
                            }
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Iconsax.more, size: 20),
                onPressed: _showRangeSizeDialog,
                tooltip: "Adjust Range Size",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredEpisodes.length,
              itemBuilder: (context, index) {
                final episode = filteredEpisodes[index];
                final isSelected = (watchState.selectedEpisodeIdx ?? 0) ==
                    watchState.episodes.indexOf(episode);

                return EpisodeTile(
                  episodeNumber: episode.number.toString(),
                  episodeTitle: episode.title ?? 'Episode ${episode.number}',
                  isSelected: isSelected,
                  onTap: () async {
                    await ref
                        .read(watchProvider.notifier)
                        .changeEpisode(index, withPlay: true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EpisodeTile extends StatelessWidget {
  final String episodeNumber;
  final String episodeTitle;
  final bool isSelected;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text(
                  episodeNumber,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                episodeTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.play5,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
