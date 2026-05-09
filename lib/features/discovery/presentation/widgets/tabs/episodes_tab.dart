import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/presentation/widgets/download_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episode_list_panel.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class EpisodesTabWidget extends ConsumerWidget {
  final UnifiedMedia media;
  const EpisodesTabWidget({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(availableAnimeSourcesProvider);

    if (sourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sources = sourcesAsync.value ?? [];
    if (sources.isEmpty && media.sourceId == null) {
      return const _NoExtensionsPlaceholder();
    }

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, media.id)),
    );
    final watchedProgress = trackingState.value?.progress.toDouble() ?? 0;

    return Column(
      children: [
        StaggeredFadeIn(index: 0, child: _EpisodesHeader(media: media)),
        const StaggeredFadeIn(index: 1, child: Divider()),
        Expanded(
          child: EpisodeListPanel(
            media: media,
            watchedProgress: watchedProgress,
            onEpisodeTap: (UnifiedEpisode episode, SourceInfo sourceInfo) {
              context.push(
                '/player',
                extra: PlayerParams(
                  media: media,
                  episode: episode,
                  sourceInfo: sourceInfo,
                ),
              );
            },
            episodeActionsBuilder:
                (episodeActionsContext, episode, isCurrent, isWatched) {
                  return [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        AppBottomSheet.show(
                          context: episodeActionsContext,
                          title:
                              'Episode ${episode.number.toString().contains('.0') ? episode.number.toInt() : episode.number}',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Download'),
                                leading: const Icon(Icons.download),
                                onTap: () {
                                  episodeActionsContext.pop();
                                  DownloadSheet.show(
                                    context,
                                    episode,
                                    ref
                                            .read(
                                              sourcePreferenceProvider(
                                                media.title.availableTitle,
                                              ),
                                            )
                                            .value
                                            ?.sourceInfo ??
                                        sources.first,
                                    media,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ];
                },
          ),
        ),
      ],
    );
  }
}

class _EpisodesHeader extends ConsumerWidget {
  final UnifiedMedia media;

  const _EpisodesHeader({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final title = media.title.availableTitle;

    if (media.sourceId != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(
                Icons.hub_rounded,
                size: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOURCE',
                    style: textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final availableSources =
        ref.watch(availableAnimeSourcesProvider).value ?? [];

    if (availableSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final sourceState = ref.watch(sourcePreferenceProvider(title)).value;

    final matchedTitle = ref.watch(
      matchedMediaProvider(title).select((s) => s.value?.matchedMedia?.title),
    );

    final sourceName = sourceState?.sourceInfo.name ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.secondaryContainer,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MATCHED',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $sourceName',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  matchedTitle ?? 'Searching...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.swap_horiz_rounded,
            onTap: () => _showSourceSelector(
              context,
              ref,
              title,
              sourceState?.sourceInfo,
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.tune_rounded,
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) =>
                    ManualMatchSheet(mediaTitle: title, type: media.type),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSourceSelector(
    BuildContext context,
    WidgetRef ref,
    String title,
    SourceInfo? currentSource,
  ) {
    final availableSources =
        ref.read(availableAnimeSourcesProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;

        return AppBottomSheet(
          title: title,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSources.length,
            itemBuilder: (context, index) {
              final sourceInfo = availableSources[index];
              final selected = currentSource == sourceInfo;

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                title: Text(
                  sourceInfo.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  ref
                      .read(sourcePreferenceProvider(title).notifier)
                      .updateSource(sourceInfo);

                  Navigator.pop(sheetContext);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        foregroundColor: cs.onSurfaceVariant,
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _NoExtensionsPlaceholder extends StatelessWidget {
  const _NoExtensionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(
                Icons.extension_off_rounded,
                size: 30,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No extensions installed',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Install an extension to start streaming episodes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.push('/settings/extensions'),
              icon: const Icon(Icons.extension_rounded),
              label: const Text('Get Extensions'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
