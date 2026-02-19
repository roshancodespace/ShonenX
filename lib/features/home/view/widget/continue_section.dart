import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/anime_match_search.dart';

class ContinueSection extends ConsumerWidget {
  final List<AnimeWatchProgressEntry> allProgress;

  const ContinueSection({super.key, required this.allProgress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validEntries = allProgress
        .where((e) => e.episodesProgress.isNotEmpty)
        .toList();

    if (validEntries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = (screenWidth * 0.6).clamp(180.0, 280.0);
    final imageHeight = itemWidth * (9 / 16);
    final listHeight = imageHeight + 60.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("Continue", style: theme.textTheme.titleLarge),
            ),
            IconButton(
              onPressed: () => context.push('/settings/watch-history'),
              icon: const Icon(Iconsax.arrow_right_3, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: validEntries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final entry = validEntries[index];
              final currentEp = entry.episodesProgress[entry.currentEpisode];

              double progressValue = 0.0;
              if (currentEp != null) {
                final p = currentEp.progressInSeconds?.toDouble() ?? 0.0;
                final d = currentEp.durationInSeconds?.toDouble() ?? 0.0;
                if (d > 0) progressValue = (p / d).clamp(0.0, 1.0);
              }

              final thumb = currentEp?.episodeThumbnail;
              Widget imageWidget;

              if (thumb != null && thumb.startsWith('http')) {
                imageWidget = CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildFallback(colorScheme),
                );
              } else if (thumb != null) {
                try {
                  imageWidget = Image.memory(
                    base64Decode(thumb),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(colorScheme),
                  );
                } catch (_) {
                  imageWidget = _buildFallback(colorScheme);
                }
              } else if (entry.animeCover.isNotEmpty) {
                imageWidget = Image.network(
                  entry.animeCover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallback(colorScheme),
                );
              } else {
                imageWidget = _buildFallback(colorScheme);
              }

              return RepaintBoundary(
                child: SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => providerAnimeMatchSearch(
                      context: context,
                      ref: ref,
                      animeMedia: UniversalMedia(
                        id: entry.animeId,
                        title: UniversalTitle(
                          romaji: entry.animeTitle,
                          english: entry.animeTitle,
                          native: entry.animeTitle,
                        ),
                        coverImage: UniversalCoverImage(
                          large: entry.animeCover,
                          medium: entry.animeCover,
                        ),
                      ),
                      startAt: entry.currentEpisode,
                      withAnimeMatch: true,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              children: [
                                Positioned.fill(child: imageWidget),
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Iconsax.play5,
                                        color: colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'EP ${currentEp?.episodeNumber ?? entry.currentEpisode}',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 3,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.animeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentEp?.episodeTitle ?? 'Continue Watching',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Iconsax.video_play,
          size: 28,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}
