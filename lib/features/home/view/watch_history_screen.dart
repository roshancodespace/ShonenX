import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(watchProgressRepositoryProvider);
    final history = repository.getAllProgress();

    // Sort by last updated (Newest first)
    history.sort((a, b) =>
        (b.lastUpdated ?? DateTime(0)).compareTo(a.lastUpdated ?? DateTime(0)));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Library',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            onPressed: () {}, // Optional: Add search or filter here
            icon: const Icon(Iconsax.search_normal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.video_play,
                      size: 48, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text("No history yet",
                      style:
                          GoogleFonts.outfit(color: theme.colorScheme.outline)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent:
                    160, // Responsive: Fits more on wider screens
                childAspectRatio: 0.7, // Poster aspect ratio
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return _AnimeHistoryCard(
                  entry: history[index],
                  onTap: () =>
                      _openDetailSheet(context, history[index], repository),
                );
              },
            ),
    );
  }

  void _openDetailSheet(BuildContext context, AnimeWatchProgressEntry entry,
      WatchProgressRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _DetailSheet(entry: entry, repository: repo),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. ANIME GRID CARD (Main Screen)
// -----------------------------------------------------------------------------
class _AnimeHistoryCard extends StatelessWidget {
  final AnimeWatchProgressEntry entry;
  final VoidCallback onTap;

  const _AnimeHistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(entry.animeCover),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient Overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7)
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Episode Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        "EP ${entry.currentEpisode}",
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            entry.animeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          // Meta
          Text(
            entry.lastUpdated != null
                ? _timeAgo(entry.lastUpdated!)
                : 'Recently',
            style: GoogleFonts.outfit(
                fontSize: 11, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat.MMMd().format(date);
  }
}

// -----------------------------------------------------------------------------
// 2. DETAIL SHEET (Bottom Sheet)
// -----------------------------------------------------------------------------
class _DetailSheet extends StatefulWidget {
  final AnimeWatchProgressEntry entry;
  final WatchProgressRepository repository;

  const _DetailSheet({required this.entry, required this.repository});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late AnimeWatchProgressEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  void _deleteEpisode(int epNum) async {
    await widget.repository.deleteEpisodeProgress(_entry.animeId, epNum);
    setState(() {
      final newMap = Map<int, EpisodeProgress>.from(_entry.episodesProgress);
      newMap.remove(epNum);
      if (newMap.isEmpty) {
        widget.repository.deleteProgress(_entry.animeId);
        Navigator.pop(context);
        return;
      }
      _entry = _entry.copyWith(episodesProgress: newMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodes = _entry.episodesProgress.values.toList()
      ..sort((a, b) =>
          (b.watchedAt ?? DateTime(0)).compareTo(a.watchedAt ?? DateTime(0)));

    final totalWatched = episodes.length;
    final lastWatchedDate =
        episodes.isNotEmpty && episodes.first.watchedAt != null
            ? DateFormat.yMMMd().format(episodes.first.watchedAt!)
            : "Unknown";

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // --- ANALYTICS SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        imageUrl: _entry.animeCover,
                        width: 45,
                        height: 65,
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_entry.animeTitle,
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Badge(
                                text: "$totalWatched Episodes",
                                color: theme.colorScheme.primaryContainer,
                                textColor:
                                    theme.colorScheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Text("Last: $lastWatchedDate",
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: theme.colorScheme.outline)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.repository.deleteProgress(_entry.animeId);
                      Navigator.pop(context);
                    },
                    icon: Icon(Iconsax.trash, color: theme.colorScheme.error),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            // --- EPISODES GRID ---
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Wider for episode thumbnails
                  childAspectRatio: 1.3, // Landscape-ish for episodes
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  return _EpisodeGridItem(
                    episode: episodes[index],
                    onDelete: () =>
                        _deleteEpisode(episodes[index].episodeNumber),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge(
      {required this.text, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. EPISODE GRID ITEM (Detail Sheet)
// -----------------------------------------------------------------------------
class _EpisodeGridItem extends StatelessWidget {
  final EpisodeProgress episode;
  final VoidCallback onDelete;

  const _EpisodeGridItem({required this.episode, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- PROGRESS LOGIC ---
    double progress = 0.0;
    if (episode.isCompleted) {
      progress = 1.0;
    } else if ((episode.durationInSeconds ?? 0) > 0) {
      progress = (episode.progressInSeconds ?? 0) / episode.durationInSeconds!;
    }
    progress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onLongPress: onDelete, // Long press to delete individual episode
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ThumbnailImage(
                      imageUrl: episode.episodeThumbnail,
                      fallbackIcon: Iconsax.video_play),

                  // Progress Bar Overlay
                  if (progress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation(episode.isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary),
                      ),
                    ),

                  // Completed Check
                  if (episode.isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 10, color: Colors.white),
                      ),
                    )
                ],
              ),
            ),

            // Meta Data
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Episode ${episode.episodeNumber}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.watchedAt != null
                        ? DateFormat.MMMd().format(episode.watchedAt!)
                        : '-',
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. SMART THUMBNAIL WIDGET (HTTP vs Base64)
// -----------------------------------------------------------------------------
class _ThumbnailImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;

  const _ThumbnailImage({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(fallbackIcon, color: Theme.of(context).colorScheme.outline),
      );
    }

    if (imageUrl!.startsWith('http')) {
      // Network Image
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.error_outline),
        ),
      );
    } else {
      // Assume Base64
      try {
        // Strip header if present (e.g. "data:image/png;base64,")
        String cleanBase64 = imageUrl!;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        Uint8List bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image),
          ),
        );
      } catch (e) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image),
        );
      }
    }
  }
}
