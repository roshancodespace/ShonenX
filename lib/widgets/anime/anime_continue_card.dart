import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';

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
      episode.progressInSeconds ?? 0,
      episode.durationInSeconds ?? 0,
    );
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
          width: 290,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
                          Colors.transparent,
                          colorScheme.scrim.withValues(alpha: 0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Progress Percentage or Completed
                      Text(
                        episode.isCompleted
                            ? 'Completed'
                            : '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: episode.isCompleted
                              ? colorScheme.primary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Anime Title
                      Text(
                        anime.animeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Episode Title
                      Text(
                        episode.episodeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Info Row
                      Row(
                        children: [
                          // Episode Number
                          _Tag(
                            text: 'EP ${episode.episodeNumber}',
                            color: colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: 8),

                          // Remaining Time
                          Text(
                            remainingTime,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const Spacer(),

                          // Play Button or Loading
                          if (!multiSelectMode)
                            isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : episode.isCompleted
                                    ? _IconButton(
                                        icon: Iconsax.next5,
                                        onPressed: () => _handleTap(
                                            context, ref,
                                            plusEpisode: 1),
                                      )
                                    : _IconButton(
                                        icon: Iconsax.play5,
                                        onPressed: () =>
                                            _handleTap(context, ref),
                                      ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              AlwaysStoppedAnimation(colorScheme.primary),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Multi-select Overlay
                if (multiSelectMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Iconsax.tick_circle,
                              color: colorScheme.primary,
                              size: 32,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref,
      {int plusEpisode = 0}) async {
    ref.read(loadingProvider(index).notifier).state = true;
    await providerAnimeMatchSearch(
      context: context,
      ref: ref,
      animeMedia: anilist_media.Media(
        id: anime.animeId,
        coverImage: anilist_media.CoverImage(
          large: anime.animeCover,
          medium: anime.animeCover,
        ),
        format: anime.animeFormat,
        title: anilist_media.Title(
          romaji: anime.animeTitle,
          english: anime.animeTitle,
          native: anime.animeTitle,
        ),
      ),
      animeWatchProgressBox: AnimeWatchProgressBox()..init(),
      plusEpisode: plusEpisode,
      afterSearchCallback: () =>
          ref.read(loadingProvider(index).notifier).state = false,
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ImagePlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainerLow,
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

  const _ImageFallback({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Iconsax.gallery_slash,
          size: 32,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
