import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Rankings widget for displaying anime rankings horizontally
class AnimeRankings extends StatelessWidget {
  final List<MediaRanking> rankings;

  const AnimeRankings({
    super.key,
    required this.rankings,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Achievements', // Renamed from Rankings for flair
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rankings.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                RankingPill(ranking: rankings[index]),
          ),
        ),
      ],
    );
  }
}

class RankingPill extends StatelessWidget {
  final MediaRanking ranking;

  const RankingPill({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTop100 = (ranking.rank ?? 999) <= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTop100
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop100
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTop100 ? Iconsax.cup : Iconsax.ranking_1,
            size: 16,
            color: isTop100
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '#${ranking.rank} ${ranking.context} ${ranking.year ?? ''}'.trim(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTop100
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
