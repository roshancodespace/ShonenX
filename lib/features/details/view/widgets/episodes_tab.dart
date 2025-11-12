import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/core/models/anilist/media.dart' as media;

final bestMatchNameProvider = StateProvider<String?>((ref) => null);

class EpisodesTab extends ConsumerStatefulWidget {
  final String mediaId;
  final media.Title mediaTitle;

  const EpisodesTab({
    super.key,
    required this.mediaId,
    required this.mediaTitle,
  });

  @override
  ConsumerState<EpisodesTab> createState() => _EpisodesTabState();
}

class _EpisodesTabState extends ConsumerState<EpisodesTab>
    with AutomaticKeepAliveClientMixin<EpisodesTab> {
  List<EpisodeDataModel> _episodes = [];
  String? animeIdForSource;
  bool _loading = false;
  String? _error;
  String? _bestMatchName;

  String _selectedRange = 'All';
  List<String> _rangeOptions = ['All'];
  bool _isSortedDescending = false;

  // In a real app, you'd get this from a database or state provider.
  final Set<int> _watchedEpisodes = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchEpisodes(ref));
  }

  Future<void> _fetchEpisodes(WidgetRef ref) async {
    if (_episodes.isNotEmpty || _loading) return;

    final useMangayomi = ref.read(experimentalProvider).useMangayomiExtensions;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final titles = [
        widget.mediaTitle.english,
        widget.mediaTitle.romaji,
        widget.mediaTitle.native,
      ].where((t) => t != null && t.trim().isNotEmpty).cast<String>().toList();

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
        return _fail('Anime Match', 'No suitable match found for any title.',
            ContentType.failure);
      }

      animeIdForSource = best["id"];

      if (mounted) {
        ref.read(bestMatchNameProvider.notifier).state = best["name"];
        setState(() => _bestMatchName = best?["name"]);
      }

      AppLogger.d(
          'High-confidence match found: ${best["name"]} (via "$usedTitle")');

      final episodes =
          await ref.read(episodeDataProvider.notifier).fetchEpisodes(
                animeTitle: best["name"]!,
                animeId: best["id"]!,
                play: false,
                force: false,
                mMangaUrl: useMangayomi ? best["id"]! : null,
              );

      if (!mounted) return;

      final total = episodes.length;
      final ranges = <String>['All'];
      for (int i = 0; i < total; i += 50) {
        final start = i + 1;
        final end = (i + 50).clamp(0, total);
        ranges.add('$start–$end');
      }

      setState(() {
        _episodes = episodes;
        _rangeOptions = ranges;
      });
    } catch (err, stack) {
      AppLogger.e(err, stack);
      _fail('Episodes', 'Failed to fetch episodes', ContentType.failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fail(String title, String message, ContentType type) {
    if (!mounted) return;
    showAppSnackBar(title, message, type: ContentType.failure);
    ref.read(bestMatchNameProvider.notifier).state = null;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.read(bestMatchNameProvider.notifier).state = null;
    setState(() {
      _episodes = [];
      _error = null;
      _bestMatchName = null;
      _selectedRange = 'All';
      _isSortedDescending = false;
      _watchedEpisodes.clear();
    });
    await _fetchEpisodes(ref);
  }

  void _handleWrongMatch() {
    AppLogger.i('User reported a wrong match. Best match was: $_bestMatchName');
    showAppSnackBar(
      'Wrong Match?',
      'Functionality to re-select anime is not yet implemented.',
      type: ContentType.help,
    );
  }

  List<EpisodeDataModel> _getVisibleEpisodes() {
    List<EpisodeDataModel> filtered;
    if (_selectedRange == 'All') {
      filtered = _episodes;
    } else {
      final parts = _selectedRange.split('–');
      if (parts.length != 2) {
        filtered = _episodes;
      } else {
        final start = int.tryParse(parts[0]) ?? 1;
        final end = int.tryParse(parts[1]) ?? _episodes.length;
        filtered = _episodes.sublist(start - 1, end.clamp(0, _episodes.length));
      }
    }

    if (_isSortedDescending) {
      return filtered.reversed.toList();
    }
    return filtered;
  }

  void _showEpisodeMenu(
      BuildContext context, EpisodeDataModel episode, bool isWatched) {
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
                    setState(() {
                      if (isWatched) {
                        _watchedEpisodes.remove(episode.number ?? -1);
                      } else {
                        _watchedEpisodes.add(episode.number ?? -1);
                      }
                    });
                    AppLogger.i(
                        'Tapped Mark as Watched for Ep: ${episode.number}');
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('Download'),
                  onTap: () {
                    AppLogger.i('Tapped Download for Ep: ${episode.number}');
                    Navigator.pop(sheetContext);
                    // TODO: Implement download logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: const Text('Add to Playlist'),
                  onTap: () {
                    AppLogger.i(
                        'Tapped Add to Playlist for Ep: ${episode.number}');
                    Navigator.pop(sheetContext);
                    // TODO: Implement playlist logic
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final exposedName = ref.watch(bestMatchNameProvider);

    if (_loading && _episodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _episodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _refresh(ref),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_episodes.isEmpty) {
      return const Center(child: Text('No episodes found'));
    }

    final visibleEpisodes = _getVisibleEpisodes();
    final totalEpisodes = _episodes.length;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        slivers: [
          if (exposedName != null)
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
                            'MATCHED ANIME',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exposedName,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline_rounded,
                          color: theme.hintColor),
                      tooltip: 'Wrong match?',
                      onPressed: _handleWrongMatch,
                    ),
                  ],
                ),
              ),
            ),
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
                  final isWatched = _watchedEpisodes.contains(ep.number ?? -1);
                  final double watchProgress = isWatched
                      ? 1.0
                      : (ep.number ?? 0) % 5 == 0
                          ? 0.3
                          : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          leading: _buildEpisodeThumbnail(context, ep, index,
                              isWatched: isWatched),
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
                            ref: ref,
                            context: context,
                            mMangaUrl: animeIdForSource,
                            episodes: _episodes,
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
                              color: isWatched ? Colors.green.shade600 : null,
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
      ),
    );
  }

  Widget _buildEpisodeThumbnail(
      BuildContext context, EpisodeDataModel ep, int index,
      {bool isWatched = false}) {
    final theme = Theme.of(context);
    final episodeNumber = ep.number ?? index + 1;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: theme.colorScheme.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                  size: 30,
                ),
              ),
            ),
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
