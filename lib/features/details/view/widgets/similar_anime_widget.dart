import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';

class SimilarAnimeWidget extends StatelessWidget {
  final List<Media> recommendations;
  final bool isLoading;
  final Function(Media)? onMediaTap;

  const SimilarAnimeWidget({
    super.key,
    required this.recommendations,
    this.isLoading = false,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'More Like This',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: isLoading && recommendations.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => _buildShimmerItem(context),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final media = recommendations[index];
                    return _buildItem(context, media);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Media media) {
    return GestureDetector(
      onTap: () => onMediaTap?.call(media),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  media.coverImage?.large ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              media.title?.english ?? media.title?.romaji ?? 'Unknown',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
