import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/core/models/anilist/media.dart' as media;
import 'package:shonenx/features/details/view_model/episodes_tab_notifier.dart';

class EpisodesTab extends ConsumerStatefulWidget {
  final String mediaId;
  final media.Title mediaTitle;
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
    final notifierProvider = episodesTabNotifierProvider(widget.mediaTitle);
    final notifier = ref.read(notifierProvider.notifier);
    final state = ref.watch(notifierProvider);

    // Watch other providers
    final episodeListState = ref.watch(episodeListProvider);
    final episodes = episodeListState.episodes;
    final loading = episodeListState.isLoading;
    final error = episodeListState.error;

    // UI state
    final exposedName = state.bestMatchName;

    final progress = ref.watch(watchProgressRepositoryProvider
        .select((w) => w.getProgress(widget.mediaId)));
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
            end.clamp(0, episodes.length));
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
                    icon:
                        Icon(Icons.swap_horiz_rounded, color: theme.hintColor),
                    tooltip: 'Change Source',
                    onPressed: () =>
                        _showSourceSelectionDialog(context, ref, notifier),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline_rounded,
                        color: theme.hintColor),
                    tooltip: 'Wrong match?',
                    onPressed: () => _handleWrongMatch(context, ref, notifier),
                  ),
                ],
              ),
            ),
          ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalEpisodes Episodes',
                              style: theme.textTheme.titleSmall,
                            ),
                            IconButton(
                              icon: Icon(state.isSortedDescending
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ep = visibleEpisodes[index];
                    final epProgress =
                        progress?.episodesProgress[ep.number ?? -1];
                    final isWatched = epProgress?.isCompleted ?? false;
                    final duration = epProgress?.durationInSeconds ?? 0;
                    final progressSec = epProgress?.progressInSeconds ?? 0;
                    final watchProgress = (duration > 0)
                        ? (progressSec / duration).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            leading: _buildEpisodeThumbnail(context, ep, index,
                                isWatched: isWatched,
                                episodeThumbnail: epProgress?.episodeThumbnail,
                                fallbackUrl: ep.thumbnail ?? widget.mediaCover),
                            title: Text(
                              ep.title ?? 'Episode ${ep.number ?? index + 1}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isWatched ? theme.hintColor : null,
                              ),
                            ),
                            subtitle: ep.isFiller == true
                                ? Text(
                                    'FILLER',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'More options',
                              onPressed: () {
                                _showEpisodeMenu(context, ep, isWatched);
                              },
                            ),
                            onTap: () => navigateToWatch(
                              mediaId: widget.mediaId,
                              animeId: state.animeIdForSource,
                              animeName: (widget.mediaTitle.english ??
                                  widget.mediaTitle.romaji ??
                                  widget.mediaTitle.native)!,
                              animeFormat: widget.mediaFormat,
                              animeCover: widget.mediaCover,
                              ref: ref,
                              context: context,
                              episodes: episodes,
                              currentEpisode: ep.number ?? 1,
                            ),
                          ),
                          if (watchProgress > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: LinearProgressIndicator(
                                value: watchProgress,
                                backgroundColor: theme
                                    .colorScheme.primaryContainer
                                    .withOpacity(0.2),
                                color: isWatched
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.primaryContainer,
                                minHeight: isWatched ? 3 : 2,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: visibleEpisodes.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSourceSelectionDialog(
      BuildContext context, WidgetRef ref, EpisodesTabNotifier notifier) {
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
                final useMangayomi =
                    ref.watch(experimentalProvider).useMangayomiExtensions;
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
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Use Mangayomi Extensions'),
                      value: useMangayomi,
                      onChanged: (value) {
                        ref.read(experimentalProvider.notifier).updateSettings(
                              (state) =>
                                  state.copyWith(useMangayomiExtensions: value),
                            );
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: useMangayomi
                          ? _buildMangayomiSourceList(
                              ref, scrollController, notifier)
                          : _buildLegacySourceList(
                              ref, scrollController, notifier),
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

  Widget _buildMangayomiSourceList(WidgetRef ref,
      ScrollController scrollController, EpisodesTabNotifier notifier) {
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
              ? Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary)
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

  Widget _buildLegacySourceList(WidgetRef ref,
      ScrollController scrollController, EpisodesTabNotifier notifier) {
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
              ? Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary)
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
      BuildContext context, WidgetRef ref, EpisodesTabNotifier notifier) async {
    final currentState =
        ref.read(episodesTabNotifierProvider(widget.mediaTitle));
    AppLogger.i(
        'User reported a wrong match. Best match was: ${currentState.bestMatchName}');

    final anime = await providerAnimeMatchSearch(
      withAnimeMatch: false,
      beforeSearchCallback: () => null,
      afterSearchCallback: () => null,
      context: context,
      ref: ref,
      animeMedia: media.Media(
        title: widget.mediaTitle,
        id: widget.mediaId,
        format: widget.mediaCover,
        coverImage: media.CoverImage(
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
      BuildContext context, EpisodeDataModel episode, bool isWatched) {
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
                  leading: Icon(isWatched
                      ? Icons.remove_red_eye_outlined
                      : Icons.check_circle_outline_rounded),
                  title:
                      Text(isWatched ? 'Mark as Unwatched' : 'Mark as Watched'),
                  onTap: () {
                    repo.updateEpisodeProgress(
                        widget.mediaId,
                        EpisodeProgress(
                            episodeNumber: episode.number!,
                            episodeTitle:
                                episode.title ?? 'Episode ${episode.number}',
                            episodeThumbnail: episode.thumbnail,
                            isCompleted: !isWatched));
                    AppLogger.i(
                        'Tapped Mark as Watched for Ep: ${episode.number}');
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('Download'),
                  onTap: () {},
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeThumbnail(
      BuildContext context, EpisodeDataModel ep, int index,
      {bool isWatched = false, String? episodeThumbnail, String? fallbackUrl}) {
    final theme = Theme.of(context);
    final episodeNumber = ep.number ?? index + 1;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (episodeThumbnail != null)
              Image.memory(
                base64Decode(episodeThumbnail),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(theme),
              )
            else if (fallbackUrl != null && fallbackUrl.isNotEmpty)
              Image.network(
                fallbackUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(theme),
              )
            else
              _buildFallbackContainer(theme),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$episodeNumber',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (isWatched)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackContainer(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
          size: 30,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverToolbarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
