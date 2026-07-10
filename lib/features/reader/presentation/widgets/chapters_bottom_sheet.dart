import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'grouped_chapter_tile.dart';

class ChaptersBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ChaptersBottomSheet> createState() =>
      _ChaptersBottomSheetState();
}

class _ChaptersBottomSheetState extends ConsumerState<ChaptersBottomSheet> {
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(episodesListProvider(widget.matchArgs));
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: episodesAsync.when(
        data: (state) {
          final Map<double, List<UnifiedEpisode>> grouped = {};
          for (final ep in state.episodes) {
            grouped.putIfAbsent(ep.number, () => []).add(ep);
          }

          final sortedNumbers = grouped.keys.toList();
          sortedNumbers.sort(
            (a, b) => _isAscending ? a.compareTo(b) : b.compareTo(a),
          );

          int initialIndex = 0;
          for (int i = 0; i < sortedNumbers.length; i++) {
            if (sortedNumbers[i] == widget.currentEpisode.number) {
              initialIndex = i;
              break;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sortedNumbers.length} Chapters',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _isAscending = !_isAscending),
                      icon: Icon(
                        _isAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _isAscending ? 'Oldest First' : 'Newest First',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollablePositionedList.builder(
                  initialScrollIndex: initialIndex.clamp(
                    0,
                    sortedNumbers.length > 0 ? sortedNumbers.length - 1 : 0,
                  ),
                  itemCount: sortedNumbers.length,
                  itemBuilder: (context, index) {
                    final chapterNum = sortedNumbers[index];
                    final eps = grouped[chapterNum]!;
                    final isCurrentChapterNum =
                        widget.currentEpisode.number == chapterNum;
                    final chapterTitle =
                        'Chapter ${chapterNum.toString().contains('.0') ? chapterNum.toInt() : chapterNum}';

                    if (eps.length == 1) {
                      final ep = eps.first;
                      final isCurrent = ep.id == widget.currentEpisode.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.45,
                                )
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                          border: isCurrent
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                          child: InkWell(
                            onTap: () => _handleEpisodeSelection(
                              context,
                              ref,
                              ep,
                              isCurrent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                ep.title ?? chapterTitle,
                                                style: TextStyle(
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  fontSize: 14.5,
                                                  color: isCurrent
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (ep.scanlator != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                ),
                                                child: Text(
                                                  ep.scanlator!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'CURRENT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    theme.colorScheme.onPrimary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isCurrent)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return GroupedChapterTile(
                      title: chapterTitle,
                      episodes: eps,
                      currentEpisode: widget.currentEpisode,
                      preferredScanlator: ref.read(
                        preferredScanlatorProvider(widget.mediaId),
                      ),
                      isCurrentChapterNum: isCurrentChapterNum,
                      uiRoundness: GlobalUI.uiRoundness,
                      onEpisodeTap: (ep) => _handleEpisodeSelection(
                        context,
                        ref,
                        ep,
                        ep.id == widget.currentEpisode.id,
                      ),
                    );
                  },
                ),
              ),
            ],
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
          .read(preferredScanlatorProvider(widget.mediaId).notifier)
          .setPreferred(ep.scanlator!);
    }
    if (!isCurrent) {
      widget.onEpisodeSelected(ep);
    }
  }
}
