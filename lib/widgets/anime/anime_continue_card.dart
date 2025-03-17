import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/screens/watchlist_screen.dart';

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
    return remaining > 0 ? '$remaining min left' : 'Completed';
  }

  double _calculateProgress() {
    final duration = episode.durationInSeconds ?? 1;
    return (episode.progressInSeconds ?? 0) / duration;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _calculateProgress().clamp(0.0, 1.0);
    final remainingTime = _formatRemainingTime(
        episode.progressInSeconds ?? 0, episode.durationInSeconds ?? 0);
    final isLoading = ref.watch(loadingProvider(index));

    final memoryImage = episode.episodeThumbnail != null
        ? base64Decode(episode.episodeThumbnail!)
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: multiSelectMode
            ? onTap
            : (isLoading ? null : () => _handleTap(context, ref)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                    ?.borderRadius ??
                BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: memoryImage != null
                      ? Image.memory(
                          memoryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ImageFallback(colorScheme: colorScheme),
                        )
                      : CachedNetworkImage(
                          imageUrl: anime.animeCover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _ImagePlaceholder(colorScheme: colorScheme),
                          errorWidget: (_, __, ___) =>
                              _ImageFallback(colorScheme: colorScheme),
                        ),
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (episode.isCompleted)
                          Text(
                            "Completed",
                            style:
                                TextStyle(color: colorScheme.primaryContainer),
                          ),
                        // Progress Percentage
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Anime Title
                        Text(
                          anime.animeTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Episode Title
                        Text(
                          episode.episodeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Episode Number, Remaining Time, and Play Button
                        Row(
                          children: [
                            // Episode Number Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'EP ${episode.episodeNumber}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Remaining Time
                            Text(
                              remainingTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),

                            // Play Button or Loading Indicator
                            if (!multiSelectMode)
                              isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => _handleTap(context, ref),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Iconsax.play5,
                                          size: 20,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation(colorScheme.primary),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Multi-select Overlay
                if (multiSelectMode)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
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
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    ref.read(loadingProvider(index).notifier).state = true;
    await providerAnimeMatchSearch(
      context: context,
      ref: ref,
      animeMedia: anime_media.Media(
        id: anime.animeId,
        coverImage: anime_media.CoverImage(
          large: anime.animeCover,
          medium: anime.animeCover,
        ),
        format: anime.animeFormat,
        title: anime_media.Title(
          romaji: anime.animeTitle,
          english: anime.animeTitle,
          native: anime.animeTitle,
        ),
      ),
      animeWatchProgressBox: AnimeWatchProgressBox()..init(),
      afterSearchCallback: () =>
          ref.read(loadingProvider(index).notifier).state = false,
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
