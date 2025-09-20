import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Info card widget displaying anime statistics and a share button
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Iconsax.star_1,
                  value: anime.averageScore != null
                      ? '${(anime.averageScore! / 10).toStringAsFixed(1)}/10'
                      : '?/10',
                  label: 'Rating',
                ),
                _InfoItem(
                  icon: Iconsax.timer_1,
                  value: '${anime.duration ?? "?"} min',
                  label: 'Duration',
                ),
                _InfoItem(
                  icon: Iconsax.video_play,
                  value: '${anime.episodes ?? "?"} eps',
                  label: 'Episodes',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ShareButton(onShare: onShare),
          ],
        ),
      ),
    );
  }
}

/// Individual info item widget for displaying statistics
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Minimal share button
class _ShareButton extends StatelessWidget {
  final VoidCallback onShare;

  const _ShareButton({required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Iconsax.share, size: 20),
        label: const Text('Share'),
        onPressed: onShare,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
