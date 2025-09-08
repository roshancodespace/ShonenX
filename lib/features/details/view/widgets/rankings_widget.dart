import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Rankings widget for displaying anime rankings
class AnimeRankings extends StatelessWidget {
  final List<MediaRanking> rankings;

  const AnimeRankings({
    super.key,
    required this.rankings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rankings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...rankings.map((ranking) => RankingCard(ranking: ranking)),
      ],
    );
  }
}

/// Individual ranking card widget
class RankingCard extends StatelessWidget {
  final MediaRanking ranking;

  const RankingCard({
    super.key,
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${ranking.rank}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ranking.context.replaceFirst(
                    ranking.context[0], ranking.context[0].toUpperCase()),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
