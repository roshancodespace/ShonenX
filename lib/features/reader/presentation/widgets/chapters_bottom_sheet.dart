import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'grouped_chapter_tile.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';
import 'package:shonenx/shared/widgets/app_empty_state.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class ChaptersBottomSheet extends ConsumerStatefulWidget {
  final MediaArgs matchArgs;
  final UnifiedEpisode currentEpisode;
  final String mediaId;
  final SourceInfo sourceInfo;
  final void Function(UnifiedEpisode) onEpisodeSelected;
  final void Function(UnifiedEpisode)? onDownloadEpisode;

  const ChaptersBottomSheet({
    super.key,
    required this.matchArgs,
    required this.currentEpisode,
    required this.mediaId,
    required this.sourceInfo,
    required this.onEpisodeSelected,
    this.onDownloadEpisode,
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
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppChip(
                      icon: Icons.menu_book_rounded,
                      label: '${sortedNumbers.length} Chapters',
                    ),
                    AppButton(
                      label: _isAscending ? 'Oldest First' : 'Newest First',
                      icon: _isAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      variant: AppButtonVariant.tonal,
                      size: AppButtonSize.small,
                      onPressed: () =>
                          setState(() => _isAscending = !_isAscending),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollablePositionedList.builder(
                  initialScrollIndex: initialIndex.clamp(
                    0,
                    sortedNumbers.isNotEmpty ? sortedNumbers.length - 1 : 0,
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCardSurface(
                          color: isCurrent
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.45,
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: () => _handleEpisodeSelection(
                            context,
                            ref,
                            ep,
                            isCurrent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (ep.scanlator != null) ...[
                                          const SizedBox(width: 8),
                                          AppChip(
                                            label: ep.scanlator!,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(height: 6),
                                      const AppChip(
                                        label: 'CURRENT',
                                        selected: true,
                                        showCheckmark: false,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.onDownloadEpisode != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 20,
                                  ),
                                  tooltip: 'Download Chapter',
                                  onPressed: () =>
                                      widget.onDownloadEpisode!(ep),
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
          child: Center(
            child: AppProgressIndicator(type: AppProgressType.circular),
          ),
        ),
        error: (err, _) => AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load chapters',
          subtitle: '$err',
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
