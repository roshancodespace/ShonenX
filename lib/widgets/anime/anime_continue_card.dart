import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

final loadingProvider = StateProvider.family<bool, int>((ref, index) => false);

class ContinueWatchingCard extends ConsumerWidget {
  final AnimeWatchProgressEntry anime;
  final EpisodeProgress episode;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final bool multiSelectMode;

  const ContinueWatchingCard({
    super.key,
    required this.anime,
    required this.episode,
    required this.index,
    this.isSelected = false,
    required this.onTap,
    this.multiSelectMode = false,
  });

  String _formatRemainingTime(int current, int total) {
    final remaining = (total - current).clamp(0, double.infinity) ~/ 60;
    return remaining > 0 ? '$remaining min' : 'Done';
  }

  double _calculateProgress() {
    final duration = episode.durationInSeconds ?? 1;
    return (episode.progressInSeconds ?? 0) / duration;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = _calculateProgress().clamp(0.0, 1.0);
    final remainingTime = _formatRemainingTime(
        episode.progressInSeconds ?? 0, episode.durationInSeconds ?? 0);
    final isLoading = ref.watch(loadingProvider(index));

    final memoryImage = episode.episodeThumbnail != null
        ? base64Decode(episode.episodeThumbnail!)
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: multiSelectMode
                ? onTap
                : (isLoading ? null : () => _handleTap(context, ref)),
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: memoryImage != null
                        ? Image.memory(
                            memoryImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ImageFallback(colorScheme: theme.colorScheme),
                          )
                        : CachedNetworkImage(
                            imageUrl: anime.animeCover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ImagePlaceholder(
                                colorScheme: theme.colorScheme),
                            errorWidget: (_, __, ___) =>
                                _ImageFallback(colorScheme: theme.colorScheme),
                          ),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.surface.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(),
                          ),
                          Text(
                            anime.animeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            episode.episodeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'EP ${episode.episodeNumber}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                remainingTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              // if (!multiSelectMode && !isLoading)
                              //   Container(
                              //     padding: const EdgeInsets.all(8),
                              //     decoration: BoxDecoration(
                              //       color: theme.colorScheme.primaryContainer,
                              //       borderRadius: BorderRadius.circular(6),
                              //     ),
                              //     child: Text(
                              //       "Continue",
                              //       style: theme.textTheme.labelSmall?.copyWith(
                              //       color: theme.colorScheme.onPrimaryContainer,
                              //       fontWeight: FontWeight.bold,
                              //     ),
                              //     ),
                              //   ),
                              // if (!multiSelectMode && !isLoading)
                              // Container(
                              //   padding: const EdgeInsets.all(8),
                              //   decoration: BoxDecoration(
                              //     color: theme.colorScheme.primaryContainer,
                              //     shape: BoxShape.circle,
                              //   ),
                              //   child: Icon(
                              //     Iconsax.play,
                              //     size: 16,
                              //     color: theme.colorScheme.onPrimaryContainer,
                              //   ),
                              // ),
                              if (isLoading)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: theme
                                  .colorScheme.primaryContainer
                                  .withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.primaryContainer),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (multiSelectMode)
                    Positioned.fill(
                      child: Container(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        child: isSelected
                            ? Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Keep existing methods (_handleTap, _showErrorSnackBar, _navigateToWatch, _showSelectionDialog)...
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    ref.read(loadingProvider(index).notifier).state = true;
    final animeProvider = getAnimeProvider(ref);
    final title = anime.animeTitle;

    if (title.isEmpty || animeProvider == null) {
      ref.read(loadingProvider(index).notifier).state = false;
      return;
    }

    final response = await animeProvider.getSearch(
        title.replaceAll(' ', '+'), anime.animeFormat, 1);

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
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Anime Not Found',
          message: 'We couldn\'t locate the anime with the selected provider.',
          contentType: ContentType.failure,
          color: theme.colorScheme.error,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child:
            _SelectionDialog(content: results, episode: episode, anime: anime),
      ),
    );
  }
}

class _SelectionDialog extends StatelessWidget {
  final List<dynamic> content;
  final EpisodeProgress episode;
  final AnimeWatchProgressEntry anime;

  const _SelectionDialog(
      {required this.content, required this.episode, required this.anime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 450),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Select Anime',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: content.length,
              itemBuilder: (context, index) => _DialogItem(
                result: content[index],
                episode: episode,
                anime: anime,
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

  const _DialogItem(
      {required this.result, required this.episode, required this.anime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: result.poster != null
            ? CachedNetworkImage(
                imageUrl: result.poster!,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _ImagePlaceholder(colorScheme: theme.colorScheme),
                errorWidget: (_, __, ___) =>
                    _ImageFallback(colorScheme: theme.colorScheme),
              )
            : _ImageFallback(
                colorScheme: theme.colorScheme, width: 50, height: 75),
      ),
      title: Text(
        result.name ?? 'Unknown',
        style: theme.textTheme.titleMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.releaseDate != null
          ? Text(
              result.releaseDate!,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing:
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () => _handleTap(context),
    );
  }

  void _handleTap(BuildContext context) {
    Navigator.of(context).pop();
    context.push(
      '/watch/${result.id}?animeName=${result.name}&episode=${episode.episodeNumber}&startAt=${episode.progressInSeconds}',
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
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;
  final double? width;
  final double? height;

  const _ImagePlaceholder({required this.colorScheme, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ColorScheme colorScheme;
  final double? width;
  final double? height;

  const _ImageFallback({required this.colorScheme, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
    );
  }
}
