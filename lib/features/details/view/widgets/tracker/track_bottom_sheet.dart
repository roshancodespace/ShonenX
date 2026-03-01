import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/features/details/view/widgets/tracker/tracker_search_sheet.dart';
import 'package:shonenx/features/details/view/widgets/tracker/tracker_update_dialogs.dart';
import 'package:shonenx/shared/providers/tracker/media_tracker_notifier.dart';

class TrackBottomSheet extends ConsumerStatefulWidget {
  final UniversalMedia anime;
  const TrackBottomSheet({super.key, required this.anime});

  static void show(BuildContext context, UniversalMedia anime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrackBottomSheet(anime: anime),
    );
  }

  @override
  ConsumerState<TrackBottomSheet> createState() => _TrackBottomSheetState();
}

class _TrackBottomSheetState extends ConsumerState<TrackBottomSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(mediaTrackerProvider(widget.anime.id).notifier)
          .fetchRemoteEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaTrackerProvider(widget.anime.id));

    if (state.isLoading && !state.remoteLoaded) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final hasAnilist = state.bindings.any((b) => b.type == TrackerType.anilist);
    final hasMal = state.bindings.any((b) => b.type == TrackerType.mal);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrackerListItem(
              title:
                  widget.anime.title.english ??
                  widget.anime.title.romaji ??
                  'Unknown Title',
              type: TrackerType.mal,
              iconUrl:
                  'https://upload.wikimedia.org/wikipedia/commons/7/7a/MyAnimeList_Logo.png',
              iconBgColor: const Color(0xFF2E51A2),
              isBound: hasMal,
              entry: state.entries[TrackerType.mal],
              statuses: state.supportedStatuses[TrackerType.mal] ?? [],
              anime: widget.anime,
            ),
            const SizedBox(height: 16),
            _TrackerListItem(
              title:
                  widget.anime.title.english ??
                  widget.anime.title.romaji ??
                  'Unknown Title',
              type: TrackerType.anilist,
              iconUrl:
                  'https://anilist.co/img/icons/android-chrome-512x512.png',
              iconBgColor: const Color(0xFF11161D),
              isBound: hasAnilist,
              entry: state.entries[TrackerType.anilist],
              statuses: state.supportedStatuses[TrackerType.anilist] ?? [],
              anime: widget.anime,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerListItem extends ConsumerWidget {
  final String title;
  final TrackerType type;
  final String iconUrl;
  final Color iconBgColor;
  final bool isBound;
  final UniversalMediaListEntry? entry;
  final List<String> statuses;
  final UniversalMedia anime;

  const _TrackerListItem({
    required this.title,
    required this.type,
    required this.iconUrl,
    required this.iconBgColor,
    required this.isBound,
    this.entry,
    required this.statuses,
    required this.anime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.network(
                  iconUrl,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isBound
                  ? Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _editBinding(context, ref),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () => _editBinding(context, ref),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'Add tracking',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        if (isBound && entry != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _StatCell(
                          value: _formatStatus(entry!.status),
                          onTap: () async {
                            final newStatus =
                                await TrackerUpdateDialogs.showStatusUpdateDialog(
                                  context,
                                  entry!.status,
                                  statuses,
                                );
                            if (newStatus != null &&
                                newStatus != entry!.status) {
                              ref
                                  .read(mediaTrackerProvider(anime.id).notifier)
                                  .syncForTracker(type, status: newStatus);
                            }
                          },
                        ),
                      ),
                      _buildDivider(colorScheme.outlineVariant),
                      Expanded(
                        flex: 2,
                        child: _StatCell(
                          value: entry!.progress.toString(),
                          onTap: () async {
                            final newProgress =
                                await TrackerUpdateDialogs.showProgressUpdateDialog(
                                  context,
                                  entry!.progress,
                                  anime.episodes,
                                );
                            if (newProgress != null &&
                                newProgress != entry!.progress) {
                              ref
                                  .read(mediaTrackerProvider(anime.id).notifier)
                                  .syncForTracker(type, progress: newProgress);
                            }
                          },
                        ),
                      ),
                      _buildDivider(colorScheme.outlineVariant),
                      Expanded(
                        flex: 2,
                        child: _StatCell(
                          value: entry!.score > 0
                              ? entry!.score.toString()
                              : '-',
                          onTap: () async {
                            final newScore =
                                await TrackerUpdateDialogs.showScoreUpdateDialog(
                                  context,
                                  entry!.score,
                                );
                            if (newScore != null && newScore != entry!.score) {
                              ref
                                  .read(mediaTrackerProvider(anime.id).notifier)
                                  .syncForTracker(type, score: newScore);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCell(value: '29/09/25', onTap: () {}),
                      ),
                      _buildDivider(colorScheme.outlineVariant),
                      Expanded(
                        child: _StatCell(value: '09/01/26', onTap: () {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: color.withOpacity(0.3),
    );
  }

  void _editBinding(BuildContext context, WidgetRef ref) {
    TrackerSearchSheet.show(
      context,
      type: type,
      initialQuery: anime.title.english ?? anime.title.romaji ?? '',
      onSelected: (media) async {
        await ref
            .read(mediaTrackerProvider(anime.id).notifier)
            .addTrackerBinding(type, media.id.toString());
      },
    );
  }

  String _formatStatus(String status) {
    final clean = status.replaceAll('_', ' ').toLowerCase();
    return clean[0].toUpperCase() + clean.substring(1);
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _StatCell({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }
}
