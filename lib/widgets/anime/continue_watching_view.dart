import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

class ContinueWatchingView extends StatelessWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueWatchingView({super.key, required this.animeWatchProgressBox});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: animeWatchProgressBox.boxValueListenable,
      builder: (context, box, child) {
        final entries =
            animeWatchProgressBox.getAllMostRecentWatchedEpisodesWithAnime();
        return entries.isEmpty
            ? _EmptyWatchingState()
            : _WatchingContent(entries: entries);
      },
    );
  }
}

class _EmptyWatchingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video_circle, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No shows in progress',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/browse'),
            icon: Icon(
              Iconsax.discover,
              color: colorScheme.onPrimary,
            ),
            label: const Text('Discover Shows'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

final loadingProvider = StateProvider.family<bool, int>((ref, index) => false);

class _WatchingContent extends StatelessWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      entries;

  const _WatchingContent({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        SizedBox(
          height: 200, // Increased height for better spacing
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ContinueWatchingCard(
                  anime: entries[index].anime,
                  episode: entries[index].episode,
                  index: index,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _header(context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.play_circle,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Continue Watching',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                context.go('/continue-all'), // New route for all items
            icon: const Icon(Iconsax.arrow_right_3, size: 24),
            tooltip: 'View all',
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingCard extends ConsumerWidget {
  final AnimeWatchProgressEntry anime;
  final EpisodeProgress episode;
  final int index;

  const _ContinueWatchingCard({
    required this.anime,
    required this.episode,
    required this.index,
  });

  String _formatRemainingTime(int current, int total) {
    final remaining = (total - current).clamp(0, double.infinity) ~/ 60;
    return remaining > 0 ? '$remaining min left' : 'Almost done';
  }

  double _calculateProgress() {
    final duration = episode.durationInSeconds ?? 1;
    return (episode.progressInSeconds ?? 0) / duration;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _calculateProgress().clamp(0.0, 1.0);
    final remainingTime = _formatRemainingTime(
      episode.progressInSeconds ?? 0,
      episode.durationInSeconds ?? 0,
    );
    final isLoading = ref.watch(loadingProvider(index));

    return Container(
      width: 240,
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // Background image
          Image.memory(
            base64Decode(episode.episodeThumbnail),
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: colorScheme.surfaceVariant,
              child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
            ),
          ),
          
          // Dark overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),

          // Content
          Material(
            color: Colors.black.withValues(alpha: 0.2),
            child: InkWell(
              onTap: isLoading ? null : () => _handleTap(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'EP ${episode.episodeNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          remainingTime,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.play,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anime.animeTitle ?? 'Unknown Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      minHeight: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    ref.read(loadingProvider(index).notifier).state = true;
    final animeProvider = getAnimeProvider(ref);
    final title = anime.animeTitle;

    if (title == null || animeProvider == null) {
      ref.read(loadingProvider(index).notifier).state = false;
      return;
    }

    final response = await animeProvider.getSearch(
      title.replaceAll(' ', '+'),
      anime.animeFormat,
      1,
    );

    if (response == null) {
      ref.read(loadingProvider(index).notifier).state = false;
      return;
    }

    final matchedResults = response.results
        .map((result) => (
              result,
              calculateSimilarity(
                  result.name?.toLowerCase() ?? '', title.toLowerCase())
            ))
        .where((pair) => pair.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (matchedResults.isEmpty && response.results.isEmpty && context.mounted) {
      _showErrorSnackBar(context);
      ref.read(loadingProvider(index).notifier).state = false;
      return;
    }

    if (matchedResults.isNotEmpty &&
        matchedResults.first.$2 >= 0.8 &&
        context.mounted) {
      final bestMatch = matchedResults.first.$1;
      ref.read(loadingProvider(index).notifier).state = false;
      _navigateToWatch(context, bestMatch);
      return;
    }

    final results = matchedResults.isEmpty
        ? response.results
        : matchedResults.map((r) => r.$1).toList();
    if (context.mounted) {
      ref.read(loadingProvider(index).notifier).state = false;
      _showSelectionDialog(context, results);
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Anime Not Found',
          message: 'We couldn\'t locate the anime with the selected provider.',
          contentType: ContentType.failure,
        ),
      ),
    );
  }

  void _navigateToWatch(BuildContext context, dynamic bestMatch) {
    context.push(
      '/watch/${bestMatch.id}?animeName=${bestMatch.name}&episode=${episode.episodeNumber}&startAt=${episode.progressInSeconds}',
      extra: anime_media.Media(
        id: anime.animeId,
        title: anime_media.Title(
            english: anime.animeTitle, romaji: anime.animeTitle),
        format: anime.animeFormat,
        coverImage: anime_media.CoverImage(
            large: anime.animeCover, medium: anime.animeCover),
        episodes: episode.episodeNumber,
        duration: episode.durationInSeconds,
      ),
    );
  }

  void _showSelectionDialog(BuildContext context, List<dynamic> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: _SelectionDialog(
              content: results, episode: episode, anime: anime),
        );
      },
    );
  }
}

class _SelectionDialog extends StatelessWidget {
  final List<dynamic> content;
  final EpisodeProgress episode;
  final AnimeWatchProgressEntry anime;

  const _SelectionDialog({
    required this.content,
    required this.episode,
    required this.anime,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(context),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: content.length,
              itemBuilder: (context, index) {
                final result = content[index];
                return _DialogItem(
                  result: result,
                  episode: episode,
                  anime: anime,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Text('Select Anime', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DialogItem extends StatelessWidget {
  final dynamic result;
  final EpisodeProgress episode;
  final AnimeWatchProgressEntry anime;

  const _DialogItem({
    required this.result,
    required this.episode,
    required this.anime,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (result.poster != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: result.poster!,
                  width: 60,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.errorContainer,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.releaseDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.releaseDate!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    Navigator.of(context).pop();
    context.push(
      '/watch/${result.id}?animeName=${result.name}&episode=${episode.episodeNumber}&startAt=${episode.progressInSeconds}',
      extra: anime_media.Media(
        id: anime.animeId,
        title: anime_media.Title(
          english: anime.animeTitle,
          romaji: anime.animeTitle,
        ),
        format: anime.animeFormat,
        coverImage: anime_media.CoverImage(
          large: anime.animeCover,
          medium: anime.animeCover,
        ),
        episodes: episode.episodeNumber,
        duration: episode.durationInSeconds,
      ),
    );
  }
}

// void _handleTap(BuildContext context) {
//     Navigator.of(context).pop();
//     context.push(
//       '/watch/${result.id}?animeName=${result.name}&episode=${episode.episodeNumber}&startAt=${episode.progressInSeconds}',
//       extra: anime_media.Media(
//         id: anime.animeId,
//         title: anime_media.Title(
//             english: anime.animeTitle, romaji: anime.animeTitle!),
//         format: anime.animeFormat,
//         coverImage: anime_media.CoverImage(
//             large: anime.animeCover!, medium: anime.animeCover!),
//         episodes: episode.episodeNumber,
//         duration: episode.durationInSeconds,
//       ),
//     );
//   }
