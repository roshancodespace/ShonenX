import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/core/models/anilist/media.dart' as media;

class EpisodesTab extends ConsumerStatefulWidget {
  final media.Title animeTitle;
  final String animeId;

  const EpisodesTab({
    super.key,
    required this.animeTitle,
    required this.animeId,
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
      // prepare possible titles in priority order
      final titles = [
        widget.animeTitle.english,
        widget.animeTitle.romaji,
        widget.animeTitle.native,
      ].where((t) => t != null && t.trim().isNotEmpty).cast<String>().toList();

      if (titles.isEmpty) {
        throw Exception("No valid title available.");
      }

      List<Map<String, String>>? candidates;
      Map<String, String>? best;
      String? usedTitle;

      // loop through possible titles until success
      for (final title in titles) {
        // Step 1: run search
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

        if (candidates.isEmpty) {
          // try next title
          continue;
        }

        // Step 2: similarity check
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

      // no matches at all
      if (best == null) {
        return _fail('Anime Match', 'No suitable match found for any title.',
            ContentType.failure);
      }

      if (!useMangayomi) {
        animeIdForSource = best["id"];
      }
      AppLogger.d(
          'High-confidence match found: ${best["name"]} (via "$usedTitle")');

      // Step 3: fetch episodes
      final episodes =
          await ref.read(episodeDataProvider.notifier).fetchEpisodes(
                animeTitle: best["name"]!,
                animeId: best["id"]!,
                play: false,
                force: false,
                mMangaUrl: useMangayomi ? best["id"]! : null,
              );

      if (!mounted) return;
      setState(() => _episodes = episodes);
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

    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _refresh(WidgetRef ref) async {
    setState(() {
      _episodes = [];
      _error = null;
    });
    await _fetchEpisodes(ref);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          final ep = _episodes[index];
          return ListTile(
            onLongPress: () {
              AppLogger.w(animeIdForSource);
            },
            onTap: () => navigateToWatch(
                animeId: animeIdForSource!,
                animeName: widget.animeTitle.english!,
                ref: ref,
                context: context,
                episodes: _episodes),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(ep.title ?? 'Episode ${index + 1}'),
            subtitle: ep.isFiller == null ? Text('FILLER') : null,
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
