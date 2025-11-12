import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/view/widget/header_base_card.dart'; // Import the base card

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(15.0);

    return HeaderBaseCard(
      onTap: () => context.go('/browse'),
      // Apply the unique gradient here
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(0.2),
          theme.colorScheme.primary.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          // The prominent icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.9),
              borderRadius: borderRadius,
            ),
            child: Icon(
              Iconsax.discover_1,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Anime',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find your next favorite series',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}