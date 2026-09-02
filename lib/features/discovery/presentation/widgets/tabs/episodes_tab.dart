import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/app_navigator.dart';

import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/download_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/widgets/source_selector_list.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/comments/presentation/widgets/comments_tab.dart';

class EpisodesTabWidget extends ConsumerWidget {
  final UnifiedMedia media;
  final bool isTv;

  const EpisodesTabWidget({super.key, required this.media, this.isTv = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final sourcesAsync = ref.watch(media.type.availableSourcesProvider);

    if (sourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sources = sourcesAsync.value ?? [];

    if (sources.isEmpty) {
      return _NoExtensionsPlaceholder(mediaType: media.type);
    }

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, media)),
    );
    final watchedProgress = trackingState.value?.progress.toDouble() ?? 0;

    final watchHistoryEntries =
        ref.watch(historyEpisodesProvider(media.id)).value ?? [];
    final readHistoryEntries =
        ref.watch(historyChaptersProvider(media.id)).value ?? [];
    final currentEpisodeNumber = media.type == MediaType.ANIME
        ? watchHistoryEntries.firstOrNull?.episodeNumber
        : readHistoryEntries.firstOrNull?.chapterNumber;

    return Column(
      children: [
        if (media.sourceId == null && !isTv) ...[
          StaggeredFadeIn(index: 0, child: _EpisodesHeader(media: media)),
          Container(
            width: double.maxFinite,
            height: 1,
            color: cs.surfaceContainerHighest,
          ),
        ],
        Expanded(
          child: EpisodeListPanel(
            media: media,
            isTv: isTv,
            watchedProgress: watchedProgress,
            currentEpisodeNumber: currentEpisodeNumber,
            useScrollController: false,
            onEpisodeTap: (UnifiedEpisode episode, SourceInfo sourceInfo) {
              if (media.type == MediaType.MANGA ||
                  media.type == MediaType.NOVEL) {
                final historyEntry = readHistoryEntries
                    .where((e) => e.chapterNumber == episode.number)
                    .firstOrNull;

                final int startPosition;
                if (historyEntry != null &&
                    historyEntry.positionPage > 0 &&
                    historyEntry.positionPage <= historyEntry.totalPages) {
                  startPosition = historyEntry.positionPage;
                } else {
                  startPosition = 1;
                }

                context.pushReader(
                  ReaderModeOnline(
                    media: media,
                    episode: episode,
                    sourceInfo: sourceInfo,
                    startPosition: startPosition,
                  ),
                );
              } else {
                final historyEntry = watchHistoryEntries
                    .where((e) => e.episodeNumber == episode.number)
                    .firstOrNull;

                final Duration? startPosition;
                if (historyEntry != null &&
                    historyEntry.positionInMilliseconds > 0 &&
                    historyEntry.positionInMilliseconds <
                        historyEntry.durationInMilliseconds) {
                  startPosition = Duration(
                    milliseconds: historyEntry.positionInMilliseconds,
                  );
                } else {
                  startPosition = null;
                }

                context.pushPlayer(
                  PlayerModeOnline(
                    media: media,
                    episode: episode,
                    sourceInfo: sourceInfo,
                    startPosition: startPosition,
                  ),
                );
              }
            },
            episodeActionsBuilder: (episodeActionsContext, episode, isCurrent, isWatched) {
              final epNum = episode.number.toInt();
              return [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Discussion',
                  onPressed: () {
                    AppBottomSheet.show(
                      context: episodeActionsContext,
                      title:
                          '${(media.type == MediaType.MANGA || media.type == MediaType.NOVEL) ? 'Chapter' : 'Episode'} $epNum Discussion',
                      contentPadding: EdgeInsets.zero,
                      child: SizedBox(
                        height:
                            MediaQuery.of(episodeActionsContext).size.height *
                            0.78,
                        child: CommentsTabWidget(
                          media: media,
                          initialEpisodeNumber: epNum,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AppBottomSheet.show(
                      context: episodeActionsContext,
                      title:
                          '${(media.type == MediaType.MANGA || media.type == MediaType.NOVEL) ? 'Chapter' : 'Episode'} ${episode.number.toString().contains('.0') ? episode.number.toInt() : episode.number}',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Discussion'),
                            leading: const Icon(Icons.forum_rounded),
                            onTap: () {
                              episodeActionsContext.pop();
                              AppBottomSheet.show(
                                context: episodeActionsContext,
                                title:
                                    '${media.type == MediaType.MANGA ? 'Chapter' : 'Episode'} $epNum Discussion',
                                contentPadding: EdgeInsets.zero,
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(
                                        episodeActionsContext,
                                      ).size.height *
                                      0.78,
                                  child: CommentsTabWidget(
                                    media: media,
                                    initialEpisodeNumber: epNum,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (media.type == MediaType.ANIME)
                            ListTile(
                              title: const Text('Stream / Download'),
                              leading: const Icon(Icons.tune_rounded),
                              onTap: () {
                                episodeActionsContext.pop();
                                DownloadSheet.show(
                                  context,
                                  episode,
                                  ref
                                          .read(
                                            mediaPreferenceProvider(
                                              MediaArgs(
                                                mediaTitle:
                                                    media.title.availableTitle,
                                                type: media.type,
                                                sourceId: media.sourceId,
                                                providerId: media.id,
                                              ),
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

    final availableSources =
        ref.watch(media.type.availableSourcesProvider).value ?? [];

    if (availableSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final matchArgs = MediaArgs(
      mediaTitle: title,
      type: media.type,
      sourceId: media.sourceId,
      providerId: media.id,
    );
    final sourceState = ref.watch(mediaPreferenceProvider(matchArgs)).value;

    final matchedMediaState = ref.watch(matchedMediaProvider(matchArgs));

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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Source',
            onTap: () => _showSourceSelector(
              context,
              ref,
              media,
              sourceState?.sourceInfo,
            ),
          ),
          const SizedBox(width: 6),
          _HeaderButton(
            icon: Icons.help_outline_rounded,
            label: 'Fix',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => ManualMatchSheet(
                  mediaTitle: title,
                  type: media.type,
                  matchArgs: matchArgs,
                ),
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
        ref.read(media.type.availableSourcesProvider).value ?? [];

    AppBottomSheet.show(
      context: context,
      title: 'Select Source',
      child: SourceSelectorList(
        availableSources: availableSources,
        currentSource: currentSource,
        mediaType: media.type,
        onSourceSelected: (sheetContext, source) {
          final matchArgs = MediaArgs(
            mediaTitle: title,
            type: media.type,
            sourceId: media.sourceId,
            providerId: media.id,
          );
          ref
              .read(mediaPreferenceProvider(matchArgs).notifier)
              .updateSource(source);
          ref.invalidate(matchedMediaProvider(matchArgs));
          ref.invalidate(episodesListProvider(matchArgs));
          if (media.sourceId != null) {
            ref.invalidate(
              sourceEpisodesProvider((
                providerId: media.id,
                sourceId: media.sourceId!,
                type: media.type,
              )),
            );
          }
          Navigator.pop(sheetContext);
        },
        onSettingsClosed: () {
          final matchArgs = MediaArgs(
            mediaTitle: title,
            type: media.type,
            sourceId: media.sourceId,
            providerId: media.id,
          );
          ref.invalidate(matchedMediaProvider(matchArgs));
          ref.invalidate(episodesListProvider(matchArgs));
          if (media.sourceId != null) {
            ref.invalidate(
              sourceEpisodesProvider((
                providerId: media.id,
                sourceId: media.sourceId!,
                type: media.type,
              )),
            );
          }
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.05,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        return Material(
          color: active
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoExtensionsPlaceholder extends StatelessWidget {
  final MediaType mediaType;
  const _NoExtensionsPlaceholder({required this.mediaType});

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
              mediaType == MediaType.MANGA
                  ? 'Install an extension to start reading chapters.'
                  : 'Install an extension to start streaming episodes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.pushSettingsExtensions(),
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
