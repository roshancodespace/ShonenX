import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/core/models/anilist/media.dart' as media;
import 'package:shonenx/storage_provider.dart';
import 'package:shonenx/utils/extractors.dart';

final _bestMatchNameProvider = StateProvider<String?>((ref) => null);

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
  String? animeIdForSource;
  String? _bestMatchName;
  bool _isSearchingMatch = false;

  String _selectedRange = 'All';
  List<String> _rangeOptions = ['All'];
  bool _isSortedDescending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchEpisodes(ref));
  }

  Future<void> _fetchEpisodes(WidgetRef ref, {bool force = false}) async {
    final state = ref.read(episodeListProvider);
    if (!force && (state.episodes.isNotEmpty || state.isLoading)) return;

    AppLogger.d("Fetching episodes for ${widget.mediaTitle}");

    final useMangayomi =
        ref.read(experimentalProvider.select((s) => s.useMangayomiExtensions));

    // Reset best match ONLY if we don't have a forced ID (manual selection)
    if (force && animeIdForSource == null) {
      ref.read(_bestMatchNameProvider.notifier).state = null;
      setState(() => _bestMatchName = null);
    }

    try {
      if (animeIdForSource == null) {
        if (mounted) setState(() => _isSearchingMatch = true);

        final titles = [
          widget.mediaTitle.english,
          widget.mediaTitle.romaji,
          widget.mediaTitle.native,
        ]
            .where((t) => t != null && t.trim().isNotEmpty)
            .cast<String>()
            .toList();

        if (titles.isEmpty) throw Exception("No valid title available.");

        List<Map<String, String>> candidates = [];
        Map<String, String>? best;
        String? usedTitle;

        for (final title in titles) {
          if (useMangayomi) {
            final res = await ref.read(sourceProvider.notifier).search(title);
            candidates = res.list
                .where((r) => r.name != null && r.link != null)
                .map((r) => {"id": r.link!, "name": r.name!})
                .toList();
          } else {
            final provider = ref.read(selectedAnimeProvider);
            if (provider == null) continue;

            final res =
                await provider.getSearch(Uri.encodeComponent(title), null, 1);
            candidates = res.results
                .where((r) => r.id != null && r.name != null)
                .map((r) => {"id": r.id!, "name": r.name!})
                .toList();
          }

          if (!mounted) return;
          if (candidates.isEmpty) continue;

          final matches = getBestMatches<Map<String, String>>(
            results: candidates,
            title: title,
            nameSelector: (r) => r["name"]!,
            idSelector: (r) => r["id"]!,
          );

          if (!mounted) return;

          if (matches.isNotEmpty && matches.first.similarity >= 0.8) {
            best = matches.first.result;
            usedTitle = title;
            break;
          }
        }

        if (best == null) {
          _fail('Anime Match', 'No suitable match found for any title.',
              ContentType.failure);
          return;
        }

        animeIdForSource = best["id"];

        if (mounted) {
          ref.read(_bestMatchNameProvider.notifier).state = best["name"];
          setState(() => _bestMatchName = best?["name"]);
        }

        AppLogger.d(
            'High-confidence match found: ${best["name"]} (via "$usedTitle")');
      }

      if (mounted) setState(() => _isSearchingMatch = false);

      await ref.read(episodeListProvider.notifier).fetchEpisodes(
            animeTitle: _bestMatchName!,
            animeId: animeIdForSource!,
            force: force, // Pass the force flag correctly
          );
    } catch (err, stack) {
      AppLogger.e(err, stack);
    } finally {
      if (mounted) setState(() => _isSearchingMatch = false);
    }
  }

  void _fail(String title, String message, ContentType type) {
    if (!mounted) return;
    if (mounted) {
      setState(() => _isSearchingMatch = false); // Ensure loading stops on fail
    }
    showAppSnackBar(title, message, type: ContentType.failure);
    // Just show snackbar, state is managed by provider or local UI variables
    // ref.read(_bestMatchNameProvider.notifier).state = null; // Maybe keep this?
    // setState(() {
    //   _loading = false;
    //   _error = message;
    // });
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.read(_bestMatchNameProvider.notifier).state = null;
    setState(() {
      _bestMatchName = null;
      _selectedRange = 'All';
      _isSortedDescending = false;
      animeIdForSource = null;
    });
    await _fetchEpisodes(ref, force: true);
  }

  void _showSourceSelectionDialog(BuildContext context, WidgetRef ref) {
    final useMangayomi = ref.read(experimentalProvider).useMangayomiExtensions;
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Source',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: useMangayomi
                      ? _buildMangayomiSourceList(ref, scrollController)
                      : _buildLegacySourceList(ref, scrollController),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMangayomiSourceList(
      WidgetRef ref, ScrollController scrollController) {
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
            _refresh(ref);
          },
        );
      },
    );
  }

  Widget _buildLegacySourceList(
      WidgetRef ref, ScrollController scrollController) {
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
            _refresh(ref);
          },
        );
      },
    );
  }

  Future<void> _handleWrongMatch(BuildContext context, WidgetRef ref) async {
    AppLogger.i('User reported a wrong match. Best match was: $_bestMatchName');
    // showAppSnackBar(
    //   'Wrong Match?',
    //   'Functionality to re-select anime is not yet implemented.',
    //   type: ContentType.help,
    // );
    final anime = await providerAnimeMatchSearch(
      withAnimeMatch: false,
      beforeSearchCallback: () {
        setState(() {
          _bestMatchName = null;
          _selectedRange = 'All';
          _isSortedDescending = false;
        });
      },
      afterSearchCallback: () {},
      context: context,
      ref: ref,
      animeMedia: media.Media(title: widget.mediaTitle),
    );
    AppLogger.d('Selected anime: ${anime?.id}');
    if (!mounted) return;
    if (anime == null) {
      return;
    }
    ref.read(_bestMatchNameProvider.notifier).state = anime.name;
    setState(() => _bestMatchName = anime.name);
    animeIdForSource = anime.id;
    await _fetchEpisodes(ref, force: true);
  }

  List<EpisodeDataModel> _getVisibleEpisodes(List<EpisodeDataModel> episodes) {
    List<EpisodeDataModel> filtered;
    if (_selectedRange == 'All') {
      filtered = episodes;
    } else {
      final parts = _selectedRange.split('–');
      if (parts.length != 2) {
        filtered = episodes;
      } else {
        final start = int.tryParse(parts[0]) ?? 1;
        final end = int.tryParse(parts[1]) ?? episodes.length;
        filtered = episodes.sublist(start - 1, end.clamp(0, episodes.length));
      }
    }

    if (_isSortedDescending) {
      return filtered.reversed.toList();
    }
    return filtered;
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
                  onTap: () async {
                    AppLogger.i('Tapped Download for Ep: ${episode.number}');

                    // 1. Close the sheet first
                    Navigator.pop(sheetContext);

                    // Check if widget is mounted before starting async work
                    if (!mounted) return;

                    final episodeNotifier =
                        ref.read(episodeDataProvider.notifier);

                    // 2. Do Async Work
                    final downloadSources = await episodeNotifier
                        .downloadSources(episode.number! - 1);
                    final path =
                        (await StorageProvider().getDefaultDirectory())?.path;

                    if (path == null) return;

                    final filePath =
                        "$path/${widget.mediaTitle.english ?? widget.mediaTitle.romaji ?? widget.mediaTitle.native}/${episode.number} - ${episode.title?.replaceAll(RegExp(r'[:\\/\?\*\"\<\>\|]'), '_') ?? "Episode ${episode.number}"}";

                    // 3. Do heavier async work
                    final Map<String, String> headers =
                        downloadSources?.headers != null
                            ? Map<String, String>.from(downloadSources!.headers)
                            : {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                              };

                    final qualities =
                        ((downloadSources!.sources.first.url ?? '')
                                .endsWith('.m3u8'))
                            ? await extractQualities(
                                downloadSources.sources.first.url!, headers)
                            : downloadSources.sources
                                .map((s) => {
                                      'url': s.url,
                                      'quality': s.quality,
                                      'headers': s.headers
                                    })
                                .toList();
                    AppLogger.w(qualities.last['url']);

                    if (!context.mounted) return;

                    await showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Download'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: qualities
                              .map((quality) => InkWell(
                                  onTap: () {
                                    final downloadItem = DownloadItem(
                                        downloadUrl:
                                            quality['url'] as String? ?? '',
                                        episodeTitle: episode.title ??
                                            'Episode ${episode.number}',
                                        thumbnail: episode.thumbnail ?? '',
                                        state: DownloadStatus.queued,
                                        progress: 0,
                                        quality:
                                            quality['quality'] as String? ??
                                                'Unknown',
                                        episodeNumber: episode.number!,
                                        animeTitle:
                                            (widget.mediaTitle.english ??
                                                widget.mediaTitle.romaji ??
                                                widget.mediaTitle.native)!,
                                        filePath: filePath,
                                        headers: quality['headers']
                                                as Map<String, String>? ??
                                            headers);
                                    ref
                                        .read(downloadsProvider.notifier)
                                        .addDownload(downloadItem);
                                    // Close the Alert Dialog
                                    Navigator.pop(dialogContext);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(quality['quality'] as String? ??
                                        'Unknown'),
                                  )))
                              .toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // ListTile(
                //   leading: const Icon(Icons.playlist_add_rounded),
                //   title: const Text('Add to Playlist'),
                //   onTap: () {
                //     AppLogger.i(
                //         'Tapped Add to Playlist for Ep: ${episode.number}');
                //     Navigator.pop(sheetContext); // Pop first

                //     // Use parent context for snackbar
                //     if (!context.mounted) return;
                //     showAppSnackBar('Add to Playlist',
                //         'Functionality to add to playlist is not yet implemented.',
                //         type: ContentType.help);
                //     // TODO: Implement playlist logic
                //   },
                // ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Watch the episode list provider for updates
    final episodeListState = ref.watch(episodeListProvider);
    final episodes = episodeListState.episodes;
    final loading = episodeListState.isLoading;
    final error = episodeListState.error;

    // Calculate ranges dynamically
    final total = episodes.length;
    final ranges = <String>['All'];
    for (int i = 0; i < total; i += 50) {
      final start = i + 1;
      final end = (i + 50).clamp(0, total);
      ranges.add('$start–$end');
    }
    // Update local range options if changed (though regenerating lists in build is cheap enough here)
    if (!listEquals(_rangeOptions, ranges)) {
      // Defer to next frame or just update local var if we remove setState
      _rangeOptions = ranges;
    }

    final exposedName = ref.watch(_bestMatchNameProvider);
    final progress = ref.watch(watchProgressRepositoryProvider
        .select((w) => w.getProgress(widget.mediaId)));
    final theme = Theme.of(context);

    final visibleEpisodes = _getVisibleEpisodes(episodes);
    final totalEpisodes = episodes.length;

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
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
                    onPressed: () => _showSourceSelectionDialog(context, ref),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline_rounded,
                        color: theme.hintColor),
                    tooltip: 'Wrong match?',
                    onPressed: () => _handleWrongMatch(context, ref),
                  ),
                ],
              ),
            ),
          ),
          if (_isSearchingMatch)
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
          else if (loading && episodes.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && episodes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _handleWrongMatch(context, ref),
                            icon: const Icon(Icons.search),
                            label: const Text('Manual Selection'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _refresh(ref),
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
                              icon: Icon(_isSortedDescending
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded),
                              tooltip: _isSortedDescending
                                  ? 'Sort Ascending'
                                  : 'Sort Descending',
                              onPressed: () {
                                setState(() =>
                                    _isSortedDescending = !_isSortedDescending);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _rangeOptions.length,
                          itemBuilder: (context, index) {
                            final range = _rangeOptions[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(range),
                                selected: _selectedRange == range,
                                onSelected: (isSelected) {
                                  if (isSelected) {
                                    setState(() => _selectedRange = range);
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
                                fallbackUrl: widget.mediaCover),
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
                              animeId: animeIdForSource,
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

  @override
  bool get wantKeepAlive => true;

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
