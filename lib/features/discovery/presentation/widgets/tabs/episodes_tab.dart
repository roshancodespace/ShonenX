import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/presentation/widgets/download_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';

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
            useScrollController: false,
            onEpisodeTap: (UnifiedEpisode episode, SourceInfo sourceInfo) {
              context.push(
                '/player',
                extra: PlayerModeOnline(
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

    final matchedMediaState = ref.watch(matchedMediaProvider(title));

    final String matchedTitle;
    final bool hasError = matchedMediaState.hasError;

    if (hasError) {
      matchedTitle = 'Failed to match';
    } else if (matchedMediaState.isLoading) {
      matchedTitle = 'Searching...';
    } else {
      matchedTitle =
          matchedMediaState.value?.matchedMedia?.title ?? 'No match found';
    }

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
              color: hasError ? cs.errorContainer : cs.secondaryContainer,
            ),
            child: Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 18,
              color: hasError ? cs.onErrorContainer : cs.onSecondaryContainer,
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
                      hasError ? 'ERROR' : 'MATCHED',
                      style: textTheme.labelMedium?.copyWith(
                        color: hasError ? cs.error : cs.primary,
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
                  matchedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasError ? cs.error : null,
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
              media,
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
    UnifiedMedia media,
    SourceInfo? currentSource,
  ) {
    final title = media.title.availableTitle;
    final availableSources =
        ref.read(availableAnimeSourcesProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final textTheme = theme.textTheme;

        return AppBottomSheet(
          title: 'Select Source',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (availableSources.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No sources available',
                      style: textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableSources.length,
                  itemBuilder: (context, index) {
                    final sourceInfo = availableSources[index];
                    final selected = currentSource == sourceInfo;
                    final sourceImpl = ref.read(
                      animeSourceProvider(sourceInfo),
                    );

                    return InkWell(
                      onTap: () {
                        ref
                            .read(sourcePreferenceProvider(title).notifier)
                            .updateSource(sourceInfo);
                        Navigator.pop(sheetContext);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sourceInfo.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sourceInfo.type.name.toUpperCase(),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.7,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<List<SourceSetting>>(
                              future: sourceImpl.getSettingsSchema(),
                              builder: (context, snapshot) {
                                final hasSettings =
                                    snapshot.hasData &&
                                    snapshot.data!.isNotEmpty;
                                if (!hasSettings) {
                                  return const SizedBox.shrink();
                                }

                                return IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  color: cs.onSurfaceVariant,
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => SourceSettingsSheet(
                                        source: sourceInfo,
                                        schema: snapshot.data!,
                                      ),
                                    ).then((_) {
                                      if (selected) {
                                        ref.invalidate(
                                          matchedMediaProvider(title),
                                        );
                                        ref.invalidate(
                                          episodesListProvider(title),
                                        );
                                        if (media.sourceId != null) {
                                          ref.invalidate(
                                            sourceEpisodesProvider((
                                              providerId: media.id,
                                              sourceId: media.sourceId!,
                                            )),
                                          );
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_rounded,
                                color: cs.primary,
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
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
