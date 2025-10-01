import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';

class EpisodesPanel extends ConsumerStatefulWidget {
  const EpisodesPanel({super.key});

  @override
  ConsumerState<EpisodesPanel> createState() => _EpisodesPanelState();
}

class _EpisodesPanelState extends ConsumerState<EpisodesPanel> {
  // Local UI state for the panel
  int _rangeSize = 50;
  int _currentStart = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to generate the list of ranges for the dropdown
  List<Map<String, int>> _generateRanges(int totalEpisodes) {
    if (totalEpisodes == 0) return [];
    final ranges = <Map<String, int>>[];
    for (int start = 1; start <= totalEpisodes; start += _rangeSize) {
      final end = (start + _rangeSize - 1).clamp(0, totalEpisodes);
      ranges.add({'start': start, 'end': end});
      if (end >= totalEpisodes) break;
    }
    return ranges;
  }

  // A redesigned, theme-aware dialog for changing the range size
  void _showRangeSizeDialog(
      BuildContext context, EpisodeDataNotifier episodeNotifier) {
    int? selectedSize = _rangeSize;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Use StatefulBuilder for temporary state inside the dialog
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
                            setDialogState(() {
                              selectedSize = size;
                            });
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
                        _currentStart = 1; // Reset to the first range
                      });
                      episodeNotifier.syncEpisodesWithJikan();
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
    final episodeData = ref.watch(episodeDataProvider
        .select((ed) => (ed.episodes, ed.selectedEpisodeIdx)));
    final episodeNotifier = ref.read(episodeDataProvider.notifier);

    final totalEpisodes = episodeData.$1.length;
    final ranges = _generateRanges(totalEpisodes);

    // Filter episodes based on the selected range
    final filteredEpisodes = episodeData.$1.where((episode) {
      final match = RegExp(r'\d+').firstMatch(episode.number.toString());
      final epNumber = match != null ? int.tryParse(match.group(0)!) : null;

      return epNumber != null &&
          epNumber >= _currentStart &&
          epNumber <= (_currentStart + _rangeSize - 1);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- REDESIGNED HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Text("Episodes", style: theme.textTheme.titleMedium),
                const Spacer(),
                // A standard DropdownButton for a better, more consistent UX
                if (ranges.isNotEmpty)
                  DropdownButton<int>(
                    value: _currentStart,
                    underline:
                        const SizedBox.shrink(), // Hides the default underline
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
                          // Scroll to the top of the list when changing range
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }

                          final pageForJikan = (value - 1) / 100;
                          if (pageForJikan == pageForJikan.toInt()) {
                            AppLogger.w(
                                "It's an integer: ${pageForJikan.toInt()}");
                            // episodeNotifier.syncEpisodesWithJikan(
                          }
                        });
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Iconsax.refresh, size: 20),
                  onPressed: () => episodeNotifier.refreshEpisodes(),
                  tooltip: "Refresh episodes",
                ),
                IconButton(
                  icon: const Icon(Iconsax.setting_2, size: 20),
                  onPressed: () =>
                      _showRangeSizeDialog(context, episodeNotifier),
                  tooltip: "Change episode range size",
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // --- REDESIGNED EPISODE LIST ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: filteredEpisodes.length,
              itemBuilder: (context, index) {
                final episode = filteredEpisodes[index];
                // Get the actual index from the original, unfiltered list
                final actualIndex = episodeData.$1.indexOf(episode);
                final isSelected = episodeData.$2 == actualIndex;

                return EpisodeTile(
                  isFiller: episode.isFiller == true,
                  episodeNumber: episode.number.toString(),
                  episodeTitle: episode.title ?? 'Episode ${episode.number}',
                  isSelected: isSelected,
                  onTap: () => episodeNotifier.changeEpisode(actualIndex),
                );
              },
            ),
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
