import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'info_card_widget.dart';
import 'synopsis_widget.dart';
import 'rankings_widget.dart';

/// Content widget that composes all the detail sections
class DetailsContent extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const DetailsContent({
    super.key,
    required this.anime,
    required this.isFavourite,
    required this.onToggleFavorite,
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
            isFavourite: isFavourite,
            onToggleFavorite: onToggleFavorite,
          ),
          const SizedBox(height: 24),
          AnimeSynopsis(
            description: anime.description ?? 'No description available.',
          ),
          if (anime.rankings.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimeRankings(rankings: anime.rankings),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
