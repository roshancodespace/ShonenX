import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Info widget displaying anime statistics in a sleek horizontal row
class AnimeInfoCard extends StatelessWidget {
  final Media anime;
  final VoidCallback onShare;

  const AnimeInfoCard({
    super.key,
    required this.anime,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final mainStudio = anime.studios.firstWhere(
      (s) => s.isMain,
      orElse: () => anime.studios.isNotEmpty
          ? anime.studios.first
          : Studio(name: 'Unknown', isMain: true),
    );

    final stats = [
      if (anime.averageScore != null)
        _StatData(
          icon: Iconsax.star1,
          value: '${(anime.averageScore! / 10).toStringAsFixed(1)}',
          label: 'Rating',
          color: Colors.amber,
        ),
      if (anime.seasonYear != null)
        _StatData(
          icon: Iconsax.calendar_1,
          value: '${anime.seasonYear}',
          label: anime.season ?? 'Year',
          color: Colors.blueAccent,
        ),
      if (anime.episodes != null)
        _StatData(
          icon: Iconsax.layer,
          value: '${anime.episodes}',
          label: 'Episodes',
          color: Colors.purpleAccent,
        ),
      if (anime.format != null)
        _StatData(
          icon: Iconsax.monitor,
          value: anime.format!,
          label: 'Format',
          color: Colors.tealAccent,
        ),
      if (anime.duration != null)
        _StatData(
          icon: Iconsax.timer_1,
          value: '${anime.duration}m',
          label: 'Duration',
          color: Colors.orangeAccent,
        ),
      _StatData(
        icon: Iconsax.building_3,
        value: mainStudio.name.length > 20
            ? '${mainStudio.name.substring(0, 18)}...'
            : mainStudio.name,
        label: 'Studio',
        color: Colors.pinkAccent,
      ),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _StatItem(stat: stat);
        },
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _StatItem extends StatelessWidget {
  final _StatData stat;

  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(stat.icon, size: 16, color: stat.color),
              const SizedBox(width: 8),
              Text(
                stat.value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display next episode countdown
class NextEpisodeWidget extends StatelessWidget {
  final Media anime;

  const NextEpisodeWidget({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final nextEp = anime.nextAiringEpisode;
    if (nextEp == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeUntil = Duration(seconds: nextEp.timeUntilAiring ?? 0);
    final days = timeUntil.inDays;
    final hours = timeUntil.inHours % 24;
    final minutes = timeUntil.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.clock, color: colorScheme.onPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE ${nextEp.episode}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'Airing in '),
                      TextSpan(
                        text: '${days}d ${hours}h ${minutes}m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
