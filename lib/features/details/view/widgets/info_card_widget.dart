import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Info card widget displaying anime statistics and action buttons
class AnimeInfoCard extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const AnimeInfoCard({
    super.key,
    required this.anime,
    required this.isFavourite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InfoItem(
                  icon: Iconsax.star_1,
                  value: anime.averageScore != null
                      ? '${(anime.averageScore! / 10).toStringAsFixed(1)}/10'
                      : '?/10',
                  label: 'Rating',
                ),
                InfoItem(
                  icon: Iconsax.timer_1,
                  value: '${anime.duration ?? "?"} min',
                  label: 'Duration',
                ),
                InfoItem(
                  icon: Iconsax.video_play,
                  value: '${anime.episodes ?? "?"} eps',
                  label: 'Episodes',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: isFavourite ? Iconsax.heart5 : Iconsax.heart,
                    label: isFavourite ? 'Favourited' : 'Favourite',
                    onTap: onToggleFavorite,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                ActionButton(
                  icon: Iconsax.share,
                  label: 'Share',
                  onTap: () {}, // Add sharing logic
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual info item widget for displaying statistics
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const InfoItem({
    super.key,
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

/// Action button widget for favorite and share actions
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OutlinedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isPrimary ? colorScheme.onPrimaryContainer : colorScheme.primary,
        backgroundColor:
            isPrimary ? colorScheme.primaryContainer : Colors.transparent,
        side: isPrimary
            ? BorderSide.none
            : BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
