import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

class ContinueWatchingCard extends ConsumerWidget {
  final AnimeWatchProgressEntry anime;
  final EpisodeProgress episode;
  final int index;

  const ContinueWatchingCard({
    super.key,
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

    return SizedBox(
      width: 280,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(
                child: episode.episodeThumbnail != null
                    ? Image.memory(
                        base64Decode(episode.episodeThumbnail!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.image,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: anime.animeCover,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.image,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : () => _handleTap(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'EP ${episode.episodeNumber}',
                                style: GoogleFonts.montserrat(
                                  color: colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              remainingTime,
                              style: GoogleFonts.montserrat(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Iconsax.play_circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 28,
                                  ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          anime.animeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor:
                              AlwaysStoppedAnimation(colorScheme.primary),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    ref.read(loadingProvider(index).notifier).state = true;
    final animeProvider = getAnimeProvider(ref);
    final title = anime.animeTitle;

    if (title.isNotEmpty || animeProvider == null) {
      ref.read(loadingProvider(index).notifier).state = false;
      return;
    }

    final response = await animeProvider.getSearch(
      title.replaceAll(' ', '+'),
      anime.animeFormat,
      1,
    );

    if (response.results.isEmpty && context.mounted) {
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

final loadingProvider = StateProvider.family<bool, int>((ref, index) => false);

// Assuming _SelectionDialog and _DialogItem remain unchanged
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
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 450),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'Select Anime',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Iconsax.close_circle, color: colorScheme.error),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
            padding: const EdgeInsets.all(12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        hoverColor: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (result.poster != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: result.poster!,
                    width: 50,
                    height: 75,
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
                )
              else
                Container(
                  width: 50,
                  height: 75,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 24),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name ?? 'Unknown',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.releaseDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.releaseDate!,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3,
                  size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
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
