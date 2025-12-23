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

  List<Map<String, int>> _generateRanges(int totalEpisodes) {
    if (totalEpisodes == 0) return [];
    final ranges = <Map<String, int>>[];
    for (int start = 1; start <= totalEpisodes; start += _rangeSize) {
      final end = (start + _rangeSize - 1).clamp(0, totalEpisodes);
      ranges.add({'start': start, 'end': end});
    }
    return ranges;
  }

  void _showRangeSizeDialog(
      BuildContext context, EpisodeListNotifier episodeListNotifier) {
    int? selectedSize = _rangeSize;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Episode Range Size"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Choose how many episodes to show."),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: [10, 25, 50, 100].map((size) {
                      return ChoiceChip(
                        label: Text("$size"),
                        selected: selectedSize == size,
                        onSelected: (isSelected) {
                          if (isSelected) {
                            setDialogState(() => selectedSize = size);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedSize != null) {
                      setState(() {
                        _rangeSize = selectedSize!;
                        _currentStart = 1;
                      });
                      episodeListNotifier.syncEpisodesWithJikan();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodes = ref.watch(episodeListProvider.select((ed) => ed.episodes));
    final selectedIdx =
        ref.watch(episodeDataProvider.select((ed) => ed.selectedEpisodeIdx));
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    final episodeListNotifier = ref.read(episodeListProvider.notifier);

    final totalEpisodes = episodes.length;
    final ranges = _generateRanges(totalEpisodes);

    final filteredEpisodes = episodes.where((episode) {
      final epNumStr = episode.number.toString();
      final match = RegExp(r'\d+').firstMatch(epNumStr);
      final epNumber = match != null ? int.tryParse(match.group(0)!) : null;

      if (epNumber == null) return false;
      return epNumber >= _currentStart &&
          epNumber <= (_currentStart + _rangeSize - 1);
    }).toList();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            widget.panelAnimation.reverse();
          }
        },
        child: Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, ranges, episodeListNotifier),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: filteredEpisodes.length,
                  itemBuilder: (context, index) {
                    final episode = filteredEpisodes[index];
                    final actualIndex = episodes.indexOf(episode);
                    final isSelected = selectedIdx == actualIndex;

                    return EpisodeTile(
                      isFiller: episode.isFiller == true,
                      episodeNumber: episode.number.toString(),
                      episodeTitle:
                          episode.title ?? 'Episode ${episode.number}',
                      isSelected: isSelected,
                      onTap: () => episodeNotifier.changeEpisode(actualIndex),
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

  Widget _buildHeader(BuildContext context, ThemeData theme,
      List<Map<String, int>> ranges, EpisodeListNotifier episodeListNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Text("Episodes", style: theme.textTheme.titleMedium),
          const Spacer(),
          if (ranges.isNotEmpty)
            DropdownButton<int>(
              value: _currentStart,
              underline: const SizedBox.shrink(),
              items: ranges.map((range) {
                return DropdownMenuItem<int>(
                  value: range['start'],
                  child: Text("${range['start']}-${range['end']}"),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentStart = value;
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  });
                }
              },
            ),
          IconButton(
            icon: const Icon(Iconsax.refresh, size: 20),
            onPressed: () => episodeListNotifier.refreshEpisodes(),
            tooltip: "Refresh episodes",
          ),
          IconButton(
            icon: const Icon(Iconsax.setting_2, size: 20),
            onPressed: () => _showRangeSizeDialog(context, episodeListNotifier),
            tooltip: "Change episode range size",
          ),
        ],
      ),
    );
  }
}

// --- REDESIGNED EPISODE TILE ---
// Now a stateless ConsumerWidget, relying on theme colors.
class EpisodeTile extends ConsumerWidget {
  final bool isFiller;
  final String episodeNumber;
  final String episodeTitle;
  final bool isSelected;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    this.isFiller = false,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Determine colors based on theme and selection state
    final Color backgroundColor =
        isSelected ? theme.colorScheme.primaryContainer : Colors.transparent;
    final Color numberBackgroundColor = isSelected
        ? theme.colorScheme.primary
        : isFiller
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest;
    final Color numberTextColor = isSelected
        ? theme.colorScheme.onPrimary
        : isFiller
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onSurfaceVariant;
    final Color titleTextColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final FontWeight titleFontWeight =
        isSelected ? FontWeight.bold : FontWeight.normal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      // Use theme-aware hover and splash colors
      hoverColor: theme.colorScheme.onSurface.withOpacity(0.08),
      splashColor: theme.colorScheme.primary.withOpacity(0.12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Episode Number Box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: numberBackgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  episodeNumber,
                  style: TextStyle(
                    color: numberTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title and Filler Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (episodeTitle.isEmpty && isFiller) Text("FILLER"),
                      Flexible(
                        child: Text(
                          episodeTitle.isEmpty
                              ? 'Episode: $episodeNumber'
                              : episodeTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: titleTextColor,
                            fontWeight: titleFontWeight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isFiller) ...[
                    const SizedBox(height: 4),
                    // Theme-aware "Filler" chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FILLER',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Play Indicator
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Iconsax.play5,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
