import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        Text('Continue Watching', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
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
              return InkWell(
                onTap: () {
                  providerAnimeMatchSearch(
                      context: context, ref: ref, animeMedia: media, startAt: entry.currentEpisode);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail with aspect ratio and loading state
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 130,
                        width: 230,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: currentEp?.episodeThumbnail != null
                            ? Image.memory(
                                base64Decode(currentEp!.episodeThumbnail!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.broken_image_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Icon(
                                Icons.image_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    SizedBox(
                      width: 220,
                      child: Text(
                        currentEp?.episodeTitle ?? entry.animeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Episode number
                    Text(
                      'Episode ${currentEp?.episodeNumber ?? '—'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
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
