import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/comments/presentation/widgets/comments_tab.dart';

class EpisodesTabWidget extends ConsumerWidget {
  final UnifiedMedia media;
  const EpisodesTabWidget({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final sourcesAsync = ref.watch(
      media.type == MediaType.ANIME
          ? availableAnimeSourcesProvider
          : availableMangaSourcesProvider,
    );

    if (sourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sources = sourcesAsync.value ?? [];

    if (sources.isEmpty) {
      return _NoExtensionsPlaceholder(mediaType: media.type);
    }

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(
        TrackingQuery(primaryTracker.type, media.id, media.type),
      ),
    );
    final watchedProgress = trackingState.value?.progress.toDouble() ?? 0;

    final watchHistoryEntries =
        ref.watch(historyEpisodesProvider(media.id)).value ?? [];
    final readHistoryEntries =
        ref.watch(historyChaptersProvider(media.id)).value ?? [];

    return Column(
      children: [
        StaggeredFadeIn(index: 0, child: _EpisodesHeader(media: media)),
        StaggeredFadeIn(
          index: 1,
          child: Container(
            width: double.maxFinite,
            height: 2,
            color: cs.surfaceContainerHigh,
          ),
        ),
        Expanded(
          child: EpisodeListPanel(
            media: media,
            watchedProgress: watchedProgress,
            useScrollController: false,
            onEpisodeTap: (UnifiedEpisode episode, SourceInfo sourceInfo) {
              if (media.type == MediaType.MANGA) {
                final historyEntry = readHistoryEntries
                    .where((e) => e.chapterNumber == episode.number)
                    .firstOrNull;

                final int startPosition;
                if (historyEntry != null &&
                    historyEntry.positionPage > 0 &&
                    historyEntry.positionPage < historyEntry.totalPages) {
                  startPosition = historyEntry.positionPage;
                } else {
                  startPosition = 1;
                }

                context.push(
                  '/reader',
                  extra: ReaderModeOnline(
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

                context.push(
                  '/player',
                  extra: PlayerModeOnline(
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
                          '${media.type == MediaType.MANGA ? 'Chapter' : 'Episode'} $epNum Discussion',
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
                          '${media.type == MediaType.MANGA ? 'Chapter' : 'Episode'} ${episode.number.toString().contains('.0') ? episode.number.toInt() : episode.number}',
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
                                          mediaPreferenceProvider(
                                            MatchArgs(
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
        ref
            .watch(
              media.type == MediaType.ANIME
                  ? availableAnimeSourcesProvider
                  : availableMangaSourcesProvider,
            )
            .value ??
        [];

    if (availableSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final matchArgs = MatchArgs(
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
        ref
            .read(
              media.type == MediaType.ANIME
                  ? availableAnimeSourcesProvider
                  : availableMangaSourcesProvider,
            )
            .value ??
        [];

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
          child: ListView(
            shrinkWrap: true,
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
              else ...[
                Builder(
                  builder: (context) {
                    final Map<String, List<SourceInfo>> groupedSources = {};
                    for (final source in availableSources) {
                      groupedSources
                          .putIfAbsent(source.name, () => [])
                          .add(source);
                    }

                    for (final name in groupedSources.keys) {
                      if (groupedSources[name]!.length > 1) {
                        groupedSources[name]!.removeWhere(
                          (s) => s.lang?.toLowerCase() == 'all',
                        );
                      }
                    }

                    final groupedNames = groupedSources.keys.toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedNames.length,
                      itemBuilder: (context, index) {
                        final sourceName = groupedNames[index];
                        final sources = groupedSources[sourceName]!;

                        Widget buildSourceItem(
                          SourceInfo sourceInfo,
                          bool isSubItem,
                        ) {
                          final selected = currentSource == sourceInfo;
                          final sourceImpl = media.type == MediaType.ANIME
                              ? ref.read(animeSourceProvider(sourceInfo))
                              : ref.read(mangaSourceProvider(sourceInfo));

                          return InkWell(
                            onTap: () {
                              final matchArgs = MatchArgs(
                                mediaTitle: title,
                                type: media.type,
                                sourceId: media.sourceId,
                                providerId: media.id,
                              );
                              ref
                                  .read(
                                    mediaPreferenceProvider(matchArgs).notifier,
                                  )
                                  .updateSource(sourceInfo);
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
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isSubItem ? 30 : 18,
                                8,
                                18,
                                8,
                              ),
                              child: Row(
                                children: [
                                  if (isSubItem)
                                    const SizedBox(width: 40)
                                  else
                                    (sourceInfo.iconUrl != null &&
                                            sourceInfo.iconUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: sourceInfo.iconUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.extension,
                                                      size: 40,
                                                    ),
                                          )
                                        : const Icon(Icons.extension, size: 40),
                                  if (!isSubItem) const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isSubItem
                                              ? (sourceInfo.lang ??
                                                        sourceInfo.type.name)
                                                    .toUpperCase()
                                              : sourceInfo.name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? cs.primary
                                                    : cs.onSurface,
                                              ),
                                        ),
                                        if (!isSubItem) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            (sourceInfo.lang ??
                                                    sourceInfo.type.name)
                                                .toUpperCase(),
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant
                                                      .withValues(alpha: 0.7),
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ],
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
                                        icon: const Icon(
                                          Icons.settings_outlined,
                                        ),
                                        color: cs.onSurfaceVariant,
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                SourceSettingsSheet(
                                                  source: sourceInfo,
                                                  schema: snapshot.data!,
                                                ),
                                          ).then((_) {
                                            if (selected) {
                                              final matchArgs = MatchArgs(
                                                mediaTitle: title,
                                                type: media.type,
                                                sourceId: media.sourceId,
                                                providerId: media.id,
                                              );
                                              ref.invalidate(
                                                matchedMediaProvider(matchArgs),
                                              );
                                              ref.invalidate(
                                                episodesListProvider(matchArgs),
                                              );
                                              if (media.sourceId != null) {
                                                ref.invalidate(
                                                  sourceEpisodesProvider((
                                                    providerId: media.id,
                                                    sourceId: media.sourceId!,
                                                    type: media.type,
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
                        }

                        if (sources.length == 1) {
                          return buildSourceItem(sources.first, false);
                        }

                        final hasSelectedVariant = sources.any(
                          (s) => s == currentSource,
                        );

                        final defaultVariant = sources.firstWhere((s) {
                          final l = s.lang?.toLowerCase();
                          return l == 'en' || l == 'english';
                        }, orElse: () => sources.first);

                        final activeVariant = hasSelectedVariant
                            ? currentSource!
                            : defaultVariant;
                        final activeSourceImpl = media.type == MediaType.ANIME
                            ? ref.read(animeSourceProvider(activeVariant))
                            : ref.read(mangaSourceProvider(activeVariant));

                        bool isExpanded = false;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    final matchArgs = MatchArgs(
                                      mediaTitle: title,
                                      type: media.type,
                                      sourceId: media.sourceId,
                                      providerId: media.id,
                                    );
                                    ref
                                        .read(
                                          mediaPreferenceProvider(
                                            matchArgs,
                                          ).notifier,
                                        )
                                        .updateSource(defaultVariant);
                                    ref.invalidate(
                                      matchedMediaProvider(matchArgs),
                                    );
                                    ref.invalidate(
                                      episodesListProvider(matchArgs),
                                    );
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        (activeVariant.iconUrl != null &&
                                                activeVariant
                                                    .iconUrl!
                                                    .isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    activeVariant.iconUrl!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(
                                                          Icons.extension,
                                                          size: 40,
                                                        ),
                                              )
                                            : const Icon(
                                                Icons.extension,
                                                size: 40,
                                              ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sourceName,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          hasSelectedVariant
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: hasSelectedVariant
                                                          ? cs.primary
                                                          : cs.onSurface,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${sources.length} variants • ${(activeVariant.lang ?? activeVariant.type.name).toUpperCase()}',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: cs.onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      letterSpacing: 0.5,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        FutureBuilder<List<SourceSetting>>(
                                          future: activeSourceImpl
                                              .getSettingsSchema(),
                                          builder: (context, snapshot) {
                                            final hasSettings =
                                                snapshot.hasData &&
                                                snapshot.data!.isNotEmpty;
                                            if (!hasSettings) {
                                              return const SizedBox.shrink();
                                            }

                                            return IconButton(
                                              icon: const Icon(
                                                Icons.settings_outlined,
                                              ),
                                              color: cs.onSurfaceVariant,
                                              onPressed: () {
                                                Navigator.pop(sheetContext);
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) =>
                                                      SourceSettingsSheet(
                                                        source: activeVariant,
                                                        schema: snapshot.data!,
                                                      ),
                                                ).then((_) {
                                                  if (hasSelectedVariant) {
                                                    final matchArgs = MatchArgs(
                                                      mediaTitle: title,
                                                      type: media.type,
                                                      sourceId: media.sourceId,
                                                      providerId: media.id,
                                                    );
                                                    ref.invalidate(
                                                      matchedMediaProvider(
                                                        matchArgs,
                                                      ),
                                                    );
                                                    ref.invalidate(
                                                      episodesListProvider(
                                                        matchArgs,
                                                      ),
                                                    );
                                                    if (media.sourceId !=
                                                        null) {
                                                      ref.invalidate(
                                                        sourceEpisodesProvider((
                                                          providerId: media.id,
                                                          sourceId:
                                                              media.sourceId!,
                                                          type: media.type,
                                                        )),
                                                      );
                                                    }
                                                  }
                                                });
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              isExpanded = !isExpanded;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  ...sources.map(
                                    (s) => buildSourceItem(s, true),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
