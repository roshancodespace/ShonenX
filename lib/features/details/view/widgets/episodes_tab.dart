import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/details/view_model/details_page_notifier.dart';
import 'package:collection/collection.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/features/details/view/widgets/episodes/episode_block_item.dart';
import 'package:shonenx/features/details/view/widgets/episodes/episode_compact_item.dart';
import 'package:shonenx/features/details/view/widgets/episodes/episode_grid_item.dart';
import 'package:shonenx/features/details/view/widgets/episodes/episode_list_item.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';

enum EpisodeViewMode { list, compact, grid, block }

class EpisodesTab extends ConsumerStatefulWidget {
  final String mediaId;
  final UniversalTitle mediaTitle;
  final String mediaFormat;
  final String mediaCover;

  const EpisodesTab({
    super.key,
    required this.mediaId,
    required this.mediaTitle,
    required this.mediaFormat,
    required this.mediaCover,
  });

  @override
  ConsumerState<EpisodesTab> createState() => _EpisodesTabState();
}

class _EpisodesTabState extends ConsumerState<EpisodesTab>
    with AutomaticKeepAliveClientMixin<EpisodesTab> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch State
    final notifier = ref.read(detailsPageProvider(widget.mediaId).notifier);
    final state = ref.watch(detailsPageProvider(widget.mediaId));
    final uiSettings = ref.watch(uiSettingsProvider);
    final viewMode = EpisodeViewMode.values.firstWhere(
      (e) => e.name == uiSettings.episodeViewMode,
      orElse: () => EpisodeViewMode.list,
    );

    // Watch other providers
    final episodeListState = ref.watch(episodeListProvider);
    final episodes = episodeListState.episodes;
    final loading = episodeListState.isLoading;
    final error = episodeListState.error;

    // UI state
    final exposedName = state.bestMatchName;
    final theme = Theme.of(context);

    // Filtering logic
    List<EpisodeDataModel> visibleEpisodes = episodes;
    if (state.selectedRange != 'All') {
      final parts = state.selectedRange.split('–');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0]) ?? 1;
        final end = int.tryParse(parts[1]) ?? episodes.length;
        visibleEpisodes = episodes.sublist(
          (start - 1).clamp(0, episodes.length),
          end.clamp(0, episodes.length),
        );
      }
    }
    if (state.isSortedDescending) {
      visibleEpisodes = visibleEpisodes.reversed.toList();
    }

    final totalEpisodes = episodes.length;

    return RefreshIndicator(
      onRefresh: () async => await notifier.refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header (Matched Source Info)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATCHED ( by ${ref.watch(experimentalProvider).useMangayomiExtensions ? ref.read(sourceProvider).activeAnimeSource?.name : ref.read(selectedAnimeProvider)?.providerName} )',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exposedName ?? 'None',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: exposedName == null ? theme.hintColor : null,
                            fontStyle: exposedName == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: theme.hintColor,
                    ),
                    tooltip: 'Change Source',
                    onPressed: () =>
                        _showSourceSelectionDialog(context, ref, notifier),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.help_outline_rounded,
                      color: theme.hintColor,
                    ),
                    tooltip: 'Wrong match?',
                    onPressed: () => _handleWrongMatch(context, ref, notifier),
                  ),
                ],
              ),
            ),
          ),

          // Content States (Loading, Error, Empty, List)
          if (state.isSearchingMatch)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Searching for best match...'),
                  ],
                ),
              ),
            )
          else if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if ((error != null || state.error != null) && episodes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.error ?? error ?? 'Unknown Error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _handleWrongMatch(context, ref, notifier),
                            icon: const Icon(Icons.search),
                            label: const Text('Manual Selection'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => notifier.refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (episodes.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No episodes found')),
            )
          else ...[
            // Toolbar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverToolbarDelegate(
                minHeight: 110.0,
                maxHeight: 110.0,
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              '$totalEpisodes Episodes',
                              style: theme.textTheme.titleSmall,
                            ),
                            const Spacer(),
                            // View Mode Toggle
                            PopupMenuButton<EpisodeViewMode>(
                              icon: const Icon(Icons.view_agenda_outlined),
                              tooltip: 'View Mode',
                              initialValue: viewMode,
                              onSelected: (mode) {
                                ref
                                    .read(uiSettingsProvider.notifier)
                                    .updateSettings(
                                      (s) => s.copyWith(
                                        episodeViewMode: mode.name,
                                      ),
                                    );
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: EpisodeViewMode.list,
                                  child: Row(
                                    children: [
                                      Icon(Icons.view_list),
                                      SizedBox(width: 8),
                                      Text('List'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: EpisodeViewMode.grid,
                                  child: Row(
                                    children: [
                                      Icon(Icons.grid_view),
                                      SizedBox(width: 8),
                                      Text('Grid'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: EpisodeViewMode.compact,
                                  child: Row(
                                    children: [
                                      Icon(Icons.view_headline),
                                      SizedBox(width: 8),
                                      Text('Compact'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: EpisodeViewMode.block,
                                  child: Row(
                                    children: [
                                      Icon(Icons.view_module),
                                      SizedBox(width: 8),
                                      Text('Block'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                state.isSortedDescending
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                              ),
                              tooltip: state.isSortedDescending
                                  ? 'Sort Ascending'
                                  : 'Sort Descending',
                              onPressed: () => notifier.toggleSort(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: state.rangeOptions.length,
                          itemBuilder: (context, index) {
                            final range = state.rangeOptions[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(range),
                                selected: state.selectedRange == range,
                                onSelected: (isSelected) {
                                  if (isSelected) {
                                    notifier.updateRange(range);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Episodes List/Grid
            _buildEpisodeSliver(
              context,
              ref,
              visibleEpisodes,
              episodeListState.animeTitle,
              episodes, // all episodes for navigation context
              state.animeIdForSource,
            ),
          ],
        ],
      ),
    );
  }

  // --- Sliver Builder Logic ---

  Widget _buildEpisodeSliver(
    BuildContext context,
    WidgetRef ref,
    List<EpisodeDataModel> visibleEpisodes,
    String? animeTitle,
    List<EpisodeDataModel> allEpisodes,
    String? animeIdForSource,
  ) {
    // Determine view mode again locally (or pass it)
    final viewMode = EpisodeViewMode.values.firstWhere(
      (e) => e.name == ref.watch(uiSettingsProvider).episodeViewMode,
      orElse: () => EpisodeViewMode.list,
    );

    // Shared Data Fetcher for individual items
    Widget buildItem(BuildContext context, int index) {
      final ep = visibleEpisodes[index];
      final progress = ref.watch(
        watchProgressRepositoryProvider.select(
          (w) => w.getProgress(widget.mediaId),
        ),
      );

      final epProgress = progress?.episodesProgress[ep.number ?? -1];
      final isWatched = epProgress?.isCompleted ?? false;
      final duration = epProgress?.durationInSeconds ?? 0;
      final progressSec = epProgress?.progressInSeconds ?? 0;
      final watchProgress = (duration > 0)
          ? (progressSec / duration).clamp(0.0, 1.0)
          : 0.0;

      final downloadState = ref.watch(downloadsProvider);
      final download = downloadState.downloads.firstWhereOrNull(
        (d) => d.animeTitle == animeTitle && d.episodeNumber == ep.number,
      );

      final fallbackCover = widget.mediaCover;

      switch (viewMode) {
        case EpisodeViewMode.grid:
          return EpisodeGridItem(
            episode: ep,
            index: index,
            isWatched: isWatched,
            watchProgress: watchProgress,
            download: download,
            episodeProgress: epProgress,
            fallbackCover: fallbackCover,
            onTap: () =>
                _navigateToWatch(ep, allEpisodes, animeIdForSource ?? ''),
            onLongPress: () => _showEpisodeMenu(context, ep, isWatched),
          );
        case EpisodeViewMode.compact:
          return EpisodeCompactItem(
            episode: ep,
            index: index,
            isWatched: isWatched,
            watchProgress: watchProgress,
            download: download,
            episodeProgress: epProgress,
            onTap: () =>
                _navigateToWatch(ep, allEpisodes, animeIdForSource ?? ''),
            onMoreOptions: () => _showEpisodeMenu(context, ep, isWatched),
          );
        case EpisodeViewMode.block:
          return EpisodeBlockItem(
            episode: ep,
            index: index,
            isWatched: isWatched,
            watchProgress: watchProgress,
            download: download,
            onTap: () =>
                _navigateToWatch(ep, allEpisodes, animeIdForSource ?? ''),
            onLongPress: () => _showEpisodeMenu(context, ep, isWatched),
          );
        case EpisodeViewMode.list:
          return EpisodeListItem(
            episode: ep,
            index: index,
            isWatched: isWatched,
            watchProgress: watchProgress,
            download: download,
            episodeProgress: epProgress,
            fallbackCover: fallbackCover,
            onTap: () =>
                _navigateToWatch(ep, allEpisodes, animeIdForSource ?? ''),
            onMoreOptions: () => _showEpisodeMenu(context, ep, isWatched),
          );
      }
    }

    if (viewMode == EpisodeViewMode.grid) {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180, // Responsive grid item width
            childAspectRatio: 0.75, // Aspect ratio (Card shape)
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildItem(context, index),
            childCount: visibleEpisodes.length,
          ),
        ),
      );
    } else if (viewMode == EpisodeViewMode.block) {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 80, // Smaller grid for blocks
            childAspectRatio: 1.0, // Square
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildItem(context, index),
            childCount: visibleEpisodes.length,
          ),
        ),
      );
    } else if (viewMode == EpisodeViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildItem(context, index),
            childCount: visibleEpisodes.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildItem(context, index),
            childCount: visibleEpisodes.length,
          ),
        ),
      );
    }
  }

  void _navigateToWatch(
    EpisodeDataModel ep,
    List<EpisodeDataModel> episodes,
    String animeIdForSource,
  ) {
    navigateToWatch(
      mediaId: widget.mediaId,
      animeId: animeIdForSource,
      animeName:
          (widget.mediaTitle.english ??
          widget.mediaTitle.romaji ??
          widget.mediaTitle.native)!,
      animeFormat: widget.mediaFormat,
      animeCover: widget.mediaCover,
      ref: ref,
      context: context,
      episodes: episodes,
      currentEpisode: ep.number ?? 1,
    );
  }

  // ... (Existing _showSourceSelectionDialog, _buildMangayomiSourceList, _buildLegacySourceList, _handleWrongMatch, _showEpisodeMenu, _buildFallbackContainer, _buildFallbackIcon methods remain unchanged)

  void _showSourceSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    DetailsPageNotifier notifier,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final useMangayomi = ref
                    .watch(experimentalProvider)
                    .useMangayomiExtensions;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Select Source',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Use Mangayomi Extensions'),
                      value: useMangayomi,
                      onChanged: (value) {
                        ref
                            .read(experimentalProvider.notifier)
                            .updateSettings(
                              (state) =>
                                  state.copyWith(useMangayomiExtensions: value),
                            );
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: useMangayomi
                          ? _buildMangayomiSourceList(
                              ref,
                              scrollController,
                              notifier,
                            )
                          : _buildLegacySourceList(
                              ref,
                              scrollController,
                              notifier,
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMangayomiSourceList(
    WidgetRef ref,
    ScrollController scrollController,
    DetailsPageNotifier notifier,
  ) {
    final sourceState = ref.watch(sourceProvider);
    final sources = sourceState.installedAnimeExtensions;
    final activeId = sourceState.activeAnimeSource?.id;

    if (sources.isEmpty) {
      return const Center(child: Text('No Mangayomi extensions installed.'));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final isSelected = source.id == activeId;
        return ListTile(
          title: Text(source.name ?? 'Unknown'),
          subtitle: Text(source.lang ?? ''),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(sourceProvider.notifier).setActiveSource(source);
            Navigator.pop(context);
            notifier.refresh();
          },
        );
      },
    );
  }

  Widget _buildLegacySourceList(
    WidgetRef ref,
    ScrollController scrollController,
    DetailsPageNotifier notifier,
  ) {
    final registry = ref.read(animeSourceRegistryProvider);
    final selectedAnimeSource = ref.watch(selectedAnimeProvider);
    final sources = registry.keys;

    if (sources.isEmpty) {
      return const Center(child: Text('No legacy sources available.'));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final isSelected =
            source.toLowerCase() == selectedAnimeSource?.providerName;
        return ListTile(
          title: Text(source),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(selectedProviderKeyProvider.notifier).select(source);
            Navigator.pop(context);
            notifier.refresh();
          },
        );
      },
    );
  }

  Future<void> _handleWrongMatch(
    BuildContext context,
    WidgetRef ref,
    DetailsPageNotifier notifier,
  ) async {
    final currentState = ref.read(detailsPageProvider(widget.mediaId));
    AppLogger.i(
      'User reported a wrong match. Best match was: ${currentState.bestMatchName}',
    );

    final anime = await providerAnimeMatchSearch(
      withAnimeMatch: false,
      beforeSearchCallback: () => null,
      afterSearchCallback: () => null,
      context: context,
      ref: ref,
      animeMedia: UniversalMedia(
        title: widget.mediaTitle,
        id: widget.mediaId,
        format: widget.mediaFormat,
        coverImage: UniversalCoverImage(
          large: widget.mediaCover,
          medium: widget.mediaCover,
        ),
      ),
    );

    if (!mounted) return;
    if (anime != null) {
      AppLogger.d('Selected anime: ${anime.id}');
      notifier.setManualMatch(anime.id!, anime.name!);
    }
  }

  void _showEpisodeMenu(
    BuildContext context,
    EpisodeDataModel episode,
    bool isWatched,
  ) {
    final repo = ref.read(watchProgressRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title ?? 'Episode ${episode.number}',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (episode.isFiller == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'FILLER',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(
                    isWatched
                        ? Icons.remove_red_eye_outlined
                        : Icons.check_circle_outline_rounded,
                  ),
                  title: Text(
                    isWatched ? 'Mark as Unwatched' : 'Mark as Watched',
                  ),
                  onTap: () {
                    repo.updateEpisodeProgress(
                      widget.mediaId,
                      EpisodeProgress(
                        episodeNumber: episode.number!,
                        episodeTitle:
                            episode.title ?? 'Episode ${episode.number}',
                        episodeThumbnail: episode.thumbnail,
                        isCompleted: !isWatched,
                      ),
                    );
                    AppLogger.i(
                      'Tapped Mark as Watched for Ep: ${episode.number}',
                    );
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('Download'),
                  onTap: () {
                    ref
                        .read(episodeDataProvider.notifier)
                        .downloadEpisode(context, episode.number!);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliverToolbarDelegate extends SliverPersistentHeaderDelegate {
  _SliverToolbarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverToolbarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
