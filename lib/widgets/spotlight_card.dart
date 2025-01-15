import 'package:flutter/material.dart';
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

    return GestureDetector(
      onTap: () => context.pushTransparentRoute(
        DetailsScreen(
          name: anime.name,
          id: anime.id,
          image: anime.poster,
          tag: tag,
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 240, // Adjusted height for better layout
        margin: const EdgeInsets.only(
            right: 1, bottom: 24, left: 1), // Adjust spacing between cards
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: theme.colorScheme.onSurface.withOpacity(0.8),
          //     blurRadius: 2,
          //     offset: Offset(0, 2), // Soft shadow for depth
          //   ),
          // ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                      theme.colorScheme.surface.withOpacity(0.7),
                      theme.colorScheme.surface.withOpacity(0.2),
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
                        color: theme.colorScheme.primary.withOpacity(0.8),
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
                        color: theme.colorScheme.onSurface,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Anime description
                    Text(
                      anime.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
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
