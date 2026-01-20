import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/features/news/view/news_detail_screen.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';

class NewsCompactCard extends ConsumerWidget {
  final UniversalNews news;

  const NewsCompactCard({super.key, required this.news});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: news.isRead ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ref.read(newsProvider.notifier).markAsRead(news);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailScreen(news: news),
              ),
            );
          },
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                // Image Section
                SizedBox(
                  width: 100,
                  height: double.infinity,
                  child: news.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: news.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: scheme.surfaceContainerHighest,
                            child: const Icon(Iconsax.image),
                          ),
                        )
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Iconsax.image),
                        ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          news.title ?? 'No Title',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if (news.date != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            news.date!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
