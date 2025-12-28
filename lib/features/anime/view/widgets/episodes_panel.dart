import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';

class EpisodesPanel extends ConsumerStatefulWidget {
  final AnimationController panelAnimation;
  const EpisodesPanel({super.key, required this.panelAnimation});

  @override
  ConsumerState<EpisodesPanel> createState() => _EpisodesPanelState();
}

class _EpisodesPanelState extends ConsumerState<EpisodesPanel> {
  int _rangeSize = 50;
  int _currentStart = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<(int, int)> _generateRanges(int total) {
    if (total == 0) return const [];
    final ranges = <(int, int)>[];
    for (int start = 1; start <= total; start += _rangeSize) {
      final end = (start + _rangeSize - 1).clamp(1, total);
      ranges.add((start, end));
    }
    return ranges;
  }

  void _showRangeSizeDialog(
    BuildContext context,
    EpisodeListNotifier notifier,
  ) {
    int temp = _rangeSize;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Episode Range Size"),
          content: Wrap(
            spacing: 8,
            children: [10, 25, 50, 100].map((size) {
              return ChoiceChip(
                label: Text("$size"),
                selected: temp == size,
                onSelected: (_) => setState(() => temp = size),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _rangeSize = temp;
                  _currentStart = 1;
                });
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final episodes =
        ref.watch(episodeListProvider.select((s) => s.episodes));
    final selectedIdx =
        ref.watch(episodeDataProvider.select((s) => s.selectedEpisodeIdx));

    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    final episodeListNotifier = ref.read(episodeListProvider.notifier);

    final total = episodes.length;
    final ranges = _generateRanges(total);

    final startIdx = (_currentStart - 1).clamp(0, total);
    final endIdx = (_currentStart + _rangeSize - 1).clamp(0, total);

    final visibleEpisodes = episodes.sublist(startIdx, endIdx);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 200) {
            widget.panelAnimation.reverse();
          }
        },
        child: Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Text("Episodes", style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (ranges.isNotEmpty)
                    DropdownButton<int>(
                      value: _currentStart,
                      underline: const SizedBox.shrink(),
                      items: ranges
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.$1,
                              child: Text("${r.$1}-${r.$2}"),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _currentStart = v;
                          _scrollController.jumpTo(0);
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Iconsax.refresh, size: 20),
                    onPressed: episodeListNotifier.refreshEpisodes,
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.setting_2, size: 20),
                    onPressed: () =>
                        _showRangeSizeDialog(context, episodeListNotifier),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: visibleEpisodes.length,
                  itemBuilder: (_, i) {
                    final episode = visibleEpisodes[i];
                    final actualIndex = startIdx + i;

                    return EpisodeTile(
                      isFiller: episode.isFiller ?? false,
                      episodeNumber:
                          episode.number?.toString() ?? "?",
                      episodeTitle:
                          episode.title ?? "Episode ${episode.number}",
                      isSelected: selectedIdx == actualIndex,
                      onTap: () =>
                          episodeNotifier.changeEpisode(actualIndex),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodeTile extends StatelessWidget {
  final bool isFiller;
  final String episodeNumber;
  final String episodeTitle;
  final bool isSelected;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.isFiller,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isFiller
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                episodeNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                episodeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.play5,
                size: 18,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
