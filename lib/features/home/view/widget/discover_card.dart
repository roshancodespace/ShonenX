import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/view/widget/header_base_card.dart';
import 'package:shonenx/features/news/view/news_screen.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';

class DiscoverCard extends ConsumerWidget {
  const DiscoverCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(15.0);
    final newsState = ref.watch(newsProvider);

    final unreadCount = newsState.hasValue
        ? newsState.value!.where((n) => !n.isRead).length
        : 0;

    return HeaderBaseCard(
      onTap: () => context.go('/browse'),
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
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NewsScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              label: Text('$unreadCount', style: TextStyle(fontSize: 14)),
              backgroundColor: theme.colorScheme.errorContainer,
              textColor: theme.colorScheme.onErrorContainer,
              child: const Icon(Icons.newspaper_rounded),
            ),
            tooltip: 'News',
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
