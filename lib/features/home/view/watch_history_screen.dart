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

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(watchProgressRepositoryProvider);
    final history = repository.getAllProgress();

    // Sort by most recently updated anime
    history.sort((a, b) =>
        (b.lastUpdated ?? DateTime(0)).compareTo(a.lastUpdated ?? DateTime(0)));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            title: const Text('Watch History'),
            centerTitle: false,
          ),
          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(theme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = history[index];
                    return _HistoryListTile(
                      entry: entry,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnimeHistoryDetailScreen(
                              animeId: entry.animeId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.clock,
            size: 64,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text("No watch history yet", style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  final AnimeWatchProgressEntry entry;
  final VoidCallback onTap;

  const _HistoryListTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastWatchedDiff =
        DateTime.now().difference(entry.lastUpdated ?? DateTime.now());

    String timeLabel = "";
    if (lastWatchedDiff.inMinutes < 60) {
      timeLabel = "${lastWatchedDiff.inMinutes}m ago";
    } else if (lastWatchedDiff.inHours < 24) {
      timeLabel = "${lastWatchedDiff.inHours}h ago";
    } else {
      timeLabel = DateFormat.MMMd().format(entry.lastUpdated ?? DateTime.now());
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: entry.animeCover,
                height: 70,
                width: 50,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainer,
                  child: const Icon(Iconsax.video),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.animeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "EP ${entry.currentEpisode}",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3,
                size: 16, color: theme.colorScheme.outline),
          ],
        ),
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
  void _playEpisode(AnimeWatchProgressEntry entry, int epNum) {
    providerAnimeMatchSearch(
      context: context,
      ref: ref,
      animeMedia: UniversalMedia(
        id: entry.animeId,
        title: UniversalTitle(english: entry.animeTitle),
        coverImage: UniversalCoverImage(
          large: entry.animeCover,
          medium: entry.animeCover,
        ),
      ),
      startAt: epNum,
    );
  }

  void _deleteEpisode(AnimeWatchProgressEntry entry, int epNum,
      WatchProgressRepository repo) async {
    await repo.deleteEpisodeProgress(entry.animeId, epNum);
    final updatedEntry = repo.getProgress(entry.animeId);
    if (updatedEntry == null || updatedEntry.episodesProgress.isEmpty) {
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  void _deleteAllHistory(
      AnimeWatchProgressEntry entry, WatchProgressRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: Text('Remove all progress for ${entry.animeTitle}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              repo.deleteProgress(entry.animeId);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = ref.watch(watchProgressRepositoryProvider);

    // Fetch fresh data
    final entry = repository.getProgress(widget.animeId);

    if (entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Most recently watched at top
    final episodes = entry.episodesProgress.values.toList()
      ..sort((a, b) =>
          (b.watchedAt ?? DateTime(0)).compareTo(a.watchedAt ?? DateTime(0)));

    final latestEpisode = episodes.isNotEmpty ? episodes.first : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(entry.animeTitle, style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Iconsax.trash, color: theme.colorScheme.error),
            onPressed: () => _deleteAllHistory(entry, repository),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context, entry, latestEpisode),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                return _EpisodeRowItem(
                  episode: episodes[index],
                  onTap: () =>
                      _playEpisode(entry, episodes[index].episodeNumber),
                  onDelete: () => _deleteEpisode(
                      entry, episodes[index].episodeNumber, repository),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AnimeWatchProgressEntry entry,
      EpisodeProgress? latest) {
    final theme = Theme.of(context);
    if (latest == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: entry.animeCover,
                  width: 80,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You watched ${entry.episodesProgress.length} episodes",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _playEpisode(entry, latest.episodeNumber),
                        icon: const Icon(Iconsax.play),
                        label: Text("Continue Ep ${latest.episodeNumber}"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeRowItem extends StatelessWidget {
  final EpisodeProgress episode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EpisodeRowItem({
    required this.episode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate progress percentage
    double progress = 0.0;
    if (episode.isCompleted) {
      progress = 1.0;
    } else if ((episode.durationInSeconds ?? 0) > 0) {
      progress = (episode.progressInSeconds ?? 0) / episode.durationInSeconds!;
    }
    progress = progress.clamp(0.0, 1.0);

    return Dismissible(
      key: ValueKey(episode.episodeNumber),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(Iconsax.trash, color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (direction) async {
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Episode?'),
            content:
                const Text('Are you sure you want to delete this episode?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onDelete();
                  Navigator.pop(context, true);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Episode Thumbnail with Progress Bar overlay
              SizedBox(
                width: 120,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _ThumbnailImage(
                          imageUrl: episode.episodeThumbnail,
                          fallbackIcon: Iconsax.video),
                    ),
                    // Progress Bar at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation(
                            episode.isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                    // Play overlay icon
                    const Center(
                      child: Icon(Icons.play_circle_fill,
                          color: Colors.white70, size: 28),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Episode ${episode.episodeNumber}",
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.watchedAt != null
                          ? DateFormat.yMMMd()
                              .add_jm()
                              .format(episode.watchedAt!)
                          : "Unknown date",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    if (progress > 0 && !episode.isCompleted)
                      Text(
                        "${(progress * 100).toInt()}% watched",
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;

  const _ThumbnailImage({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    if (imageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildPlaceholder(context),
      );
    } else {
      try {
        final bytes = base64Decode(imageUrl!.split(',').last);
        return Image.memory(bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context));
      } catch (e) {
        return _buildPlaceholder(context);
      }
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(fallbackIcon, color: Theme.of(context).colorScheme.outline),
    );
  }
}
