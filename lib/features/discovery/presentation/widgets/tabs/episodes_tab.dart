import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episode_list_panel.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
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
        _EpisodesHeader(media: media),
        const Divider(),
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
    final title = media.title.availableTitle;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (media.sourceId != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOURCE',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    title,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCHED (by $sourceName)',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  matchedTitle ?? 'Searching...',
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSourceSelector(
              context,
              ref,
              title,
              sourceState?.sourceInfo,
            ),
            icon: const Icon(Icons.swap_horiz),
            label: Text(sourceName, style: textTheme.labelLarge),
          ),
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) =>
                  ManualMatchSheet(mediaTitle: title, type: media.type),
            ),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Manual Match',
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
        return AppBottomSheet(
          title: title,
          child: ListView.builder(
            itemCount: availableSources.length,
            itemBuilder: (context, index) {
              final sourceInfo = availableSources[index];
              return ListTile(
                title: Text(sourceInfo.name),
                trailing: currentSource == sourceInfo
                    ? const Icon(Icons.check)
                    : null,
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

class _NoExtensionsPlaceholder extends StatelessWidget {
  const _NoExtensionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No extensions installed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You need at least one extension to stream episodes. Head to Extensions settings to get started.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/settings/extensions'),
              icon: const Icon(Icons.extension_rounded),
              label: const Text('Get Extensions'),
            ),
          ],
        ),
      ),
    );
  }
}
