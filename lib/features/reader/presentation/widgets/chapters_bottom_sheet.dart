import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'grouped_chapter_tile.dart';

class ChaptersBottomSheet extends ConsumerWidget {
  final MatchArgs matchArgs;
  final UnifiedEpisode currentEpisode;
  final String mediaId;
  final SourceInfo sourceInfo;
  final void Function(UnifiedEpisode) onEpisodeSelected;

  const ChaptersBottomSheet({
    super.key,
    required this.matchArgs,
    required this.currentEpisode,
    required this.mediaId,
    required this.sourceInfo,
    required this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesListProvider(matchArgs));

    return episodesAsync.when(
      data: (state) {
        final Map<double, List<UnifiedEpisode>> grouped = {};
        for (final ep in state.episodes) {
          grouped.putIfAbsent(ep.number, () => []).add(ep);
        }

        final sortedNumbers = grouped.keys.toList()..sort();

        int initialIndex = 0;
        for (int i = 0; i < sortedNumbers.length; i++) {
          if (sortedNumbers[i] == currentEpisode.number) {
            initialIndex = i;
            break;
          }
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ScrollablePositionedList.builder(
            initialScrollIndex: initialIndex,
            itemCount: sortedNumbers.length,
            itemBuilder: (context, index) {
              final chapterNum = sortedNumbers[index];
              final eps = grouped[chapterNum]!;
              final isCurrentChapterNum = currentEpisode.number == chapterNum;
              final chapterTitle =
                  'Chapter ${chapterNum.toString().contains('.0') ? chapterNum.toInt() : chapterNum}';

              if (eps.length == 1) {
                final ep = eps.first;
                final isCurrent = ep.id == currentEpisode.id;

                return ListTile(
                  title: Text(
                    ep.title ?? chapterTitle,
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: ep.scanlator != null ? Text(ep.scanlator!) : null,
                  selected: isCurrent,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  onTap: () =>
                      _handleEpisodeSelection(context, ref, ep, isCurrent),
                );
              }

              return GroupedChapterTile(
                title: chapterTitle,
                episodes: eps,
                currentEpisode: currentEpisode,
                preferredScanlator: ref.read(
                  preferredScanlatorProvider(mediaId),
                ),
                isCurrentChapterNum: isCurrentChapterNum,
                onEpisodeTap: (ep) => _handleEpisodeSelection(
                  context,
                  ref,
                  ep,
                  ep.id == currentEpisode.id,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text('Error: $err')),
      ),
    );
  }

  void _handleEpisodeSelection(
    BuildContext context,
    WidgetRef ref,
    UnifiedEpisode ep,
    bool isCurrent,
  ) {
    context.pop();
    if (ep.scanlator != null) {
      ref
          .read(preferredScanlatorProvider(mediaId).notifier)
          .setPreferred(ep.scanlator!);
    }
    if (!isCurrent) {
      onEpisodeSelected(ep);
    }
  }
}
