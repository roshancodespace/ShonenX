import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nekoflow/data/models/anime_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:dismissible_page/dismissible_page.dart';

class SpotlightCard extends StatelessWidget {
  final SpotlightAnime anime;
  final String tag;

  const SpotlightCard({
    super.key,
    required this.anime,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: GestureDetector(
        onTap: () => context.push(
            '/details?id=${anime.id}&tag=$tag&image=${anime.poster}&name=${anime.name}&type=${anime.type}'),
        child: SizedBox(
          width: double.infinity,
          height: 240, // Adjusted height for better layout
          child: Stack(
            children: [
              // Use CachedNetworkImage for better performance and caching
              CachedNetworkImage(
                imageUrl: anime.poster,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      // theme.colorScheme.surface.withValues(alpha:0.7),
                      // theme.colorScheme.surface.withValues(alpha:0.2),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Display Rank
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rank : #${anime.rank}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0), // Spacer between rank and name

                    // Anime name
                    Text(
                      anime.name,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: Offset(1, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Anime description
                    Text(
                      anime.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
