import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'info_card_widget.dart';
import 'synopsis_widget.dart';
import 'rankings_widget.dart';
import 'related_entries_widget.dart';
import 'similar_anime_widget.dart';

/// Content widget that composes all the detail sections
class DetailsContent extends StatelessWidget {
  final Media anime;
  final bool isLoading;
  final Function(Media)? onMediaTap;

  const DetailsContent({
    super.key,
    required this.anime,
    this.isLoading = false,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimeInfoCard(
            anime: anime,
            onShare: () {},
          ),
          const SizedBox(height: 24),
          AnimeSynopsis(
            description: anime.description ?? '',
            isLoading: isLoading && (anime.description?.isEmpty ?? true),
          ),
          if (anime.rankings.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimeRankings(rankings: anime.rankings),
          ],
          const SizedBox(height: 24),
          RelatedEntriesWidget(
            relations: anime.relations,
            isLoading: isLoading,
            onMediaTap: onMediaTap,
          ),
          const SizedBox(height: 24),
          SimilarAnimeWidget(
            recommendations: anime.recommendations,
            isLoading: isLoading,
            onMediaTap: onMediaTap,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
