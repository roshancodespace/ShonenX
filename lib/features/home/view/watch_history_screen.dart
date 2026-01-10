import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:go_router/go_router.dart';

class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});
  @override
  ConsumerState<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(watchProgressRepositoryProvider).getAllProgress()
      ..sort((a, b) => (b.lastUpdated ?? DateTime(0))
          .compareTo(a.lastUpdated ?? DateTime(0)));

    final filtered = history
        .where((e) =>
            e.animeTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: () => context.pop()),
        title: const Text('Watch History',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SearchBar(
              hint: "Search history...",
              onChanged: (v) => setState(() => _searchQuery = v)),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(_searchQuery.isEmpty
                        ? "No history yet"
                        : "No matches found"))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _HistoryTile(entry: filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class AnimeHistoryDetailScreen extends ConsumerStatefulWidget {
  final String animeId;
  const AnimeHistoryDetailScreen({super.key, required this.animeId});
  @override
  ConsumerState<AnimeHistoryDetailScreen> createState() =>
      _AnimeHistoryDetailScreenState();
}

class _AnimeHistoryDetailScreenState
    extends ConsumerState<AnimeHistoryDetailScreen> {
  String _epQuery = "";

  void _play(AnimeWatchProgressEntry entry, int ep) {
    providerAnimeMatchSearch(
        context: context,
        ref: ref,
        animeMedia: UniversalMedia(
            id: entry.animeId,
            title: UniversalTitle(
                english: entry.animeTitle, romaji: entry.animeTitle),
            coverImage: UniversalCoverImage(large: entry.animeCover)),
        startAt: ep);
  }

  @override
  Widget build(BuildContext context) {
    final entry =
        ref.watch(watchProgressRepositoryProvider).getProgress(widget.animeId);
    if (entry == null) return const Scaffold();

    final episodes = entry.episodesProgress.values.toList()
      ..sort((a, b) =>
          (b.watchedAt ?? DateTime(0)).compareTo(a.watchedAt ?? DateTime(0)));

    final filtered = episodes
        .where((e) =>
            e.episodeNumber.toString().contains(_epQuery) ||
            (e.episodeTitle.toLowerCase().contains(_epQuery.toLowerCase())))
        .toList();

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () => context.pop()),
          title: Text(entry.animeTitle,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          _DetailHeader(
            entry: entry,
            currentEp: episodes.first.episodeNumber,
            onResume: () => _play(entry, episodes.first.episodeNumber),
            onNext: () => _play(entry, episodes.first.episodeNumber + 1),
          ),
          _SearchBar(
              hint: "Search episode number or title...",
              onChanged: (v) => setState(() => _epQuery = v)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _EpisodeRow(
                  episode: filtered[index],
                  onPlay: () => _play(entry, filtered[index].episodeNumber)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: onChanged,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: theme.colorScheme.outline, fontSize: 14),
            prefixIcon: Icon(Iconsax.search_normal,
                size: 20, color: theme.colorScheme.primary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final AnimeWatchProgressEntry entry;
  final int currentEp;
  final VoidCallback onResume;
  final VoidCallback onNext;

  const _DetailHeader(
      {required this.entry,
      required this.currentEp,
      required this.onResume,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
                imageUrl: entry.animeCover,
                width: 90,
                height: 130,
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CURRENTLY AT",
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text("Episode $currentEp",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                // Optimized Action Blade
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: theme.colorScheme.primary,
                          child: InkWell(
                            onTap: onResume,
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              child: Text("RESUME",
                                  style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 1),
                      Expanded(
                        flex: 1,
                        child: Material(
                          color: theme.colorScheme.primary,
                          child: InkWell(
                            onTap: onNext,
                            child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                child: Text("NEXT",
                                    style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AnimeWatchProgressEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AnimeHistoryDetailScreen(animeId: entry.animeId))),
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
              imageUrl: entry.animeCover,
              width: 44,
              height: 60,
              fit: BoxFit.cover)),
      title: Text(entry.animeTitle,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(
          "Ep ${entry.currentEpisode} • ${DateFormat.MMMd().format(entry.lastUpdated ?? DateTime.now())}",
          style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Iconsax.arrow_right_3, size: 14),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  final EpisodeProgress episode;
  final VoidCallback onPlay;
  const _EpisodeRow({required this.episode, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final progress = (episode.durationInSeconds ?? 0) > 0
        ? (episode.progressInSeconds ?? 0) / episode.durationInSeconds!
        : 0.0;
    return ListTile(
      onTap: onPlay,
      leading: SizedBox(
        width: 110,
        height: 62,
        child: Stack(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _Thumb(url: episode.episodeThumbnail)),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 2,
                    valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary))),
            const Center(
                child: Icon(Iconsax.play5, color: Colors.white70, size: 20)),
          ],
        ),
      ),
      title: Text("Episode ${episode.episodeNumber}",
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(episode.episodeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11)),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return Container(color: Colors.black12);
    return url!.startsWith('http')
        ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
        : Image.memory(base64Decode(url!.split(',').last), fit: BoxFit.cover);
  }
}
