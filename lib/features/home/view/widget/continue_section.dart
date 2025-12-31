import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart' as m;
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';

class ContinueSection extends ConsumerWidget {
  final List<AnimeWatchProgressEntry> allProgress;
  const ContinueSection({super.key, required this.allProgress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Continue Watching', style: theme.textTheme.titleLarge),
            IconButton(
              onPressed: () => context.push('/settings/watch-history'),
              icon: const Icon(Iconsax.arrow_right_1),
              tooltip: 'View All History',
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allProgress.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = allProgress[index];
              final currentEp = entry.episodesProgress[entry.currentEpisode];
              final media = m.Media(
                id: int.tryParse(entry.animeId),
                title: m.Title(
                  romaji: entry.animeTitle,
                  english: entry.animeTitle,
                  native: entry.animeTitle,
                ),
                coverImage: m.CoverImage(
                    large: entry.animeCover, medium: entry.animeCover),
              );

              final colorScheme = theme.colorScheme;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  providerAnimeMatchSearch(
                      context: context,
                      ref: ref,
                      animeMedia: media,
                      startAt: entry.currentEpisode);
                },
                child: SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Section
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: AspectRatio(
                              aspectRatio: 16 / 8.5,
                              child: currentEp?.episodeThumbnail != null
                                  ? currentEp!.episodeThumbnail!
                                          .startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: currentEp.episodeThumbnail!,
                                          fit: BoxFit.cover,
                                          errorWidget:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(Icons.broken_image,
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                        )
                                      : Image.memory(
                                          base64Decode(
                                              currentEp.episodeThumbnail!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(Icons.broken_image,
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                        )
                                  : (entry.animeCover.isNotEmpty
                                      ? Image.network(
                                          entry.animeCover,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(Icons.broken_image,
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                        )
                                      : Container(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(Icons.image,
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                        )),
                            ),
                          ),
                          // Play Icon Overlay
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5)),
                                ),
                                child: const Icon(Iconsax.play,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          // Episode Badge
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'EP ${currentEp?.episodeNumber ?? entry.currentEpisode}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Info Section
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.animeTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentEp?.episodeTitle ?? 'Continue Watching',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Simple Progress Bar Visual
                            LinearProgressIndicator(
                              value:
                                  1.0, // entry.progress / entry.totalDuration if we had it
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                              minHeight: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
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
}
