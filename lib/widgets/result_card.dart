import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ResultCard extends StatelessWidget {
  final AnimeResult anime;

  const ResultCard({super.key, required this.anime});

  // Reusable badge widget
  Widget _buildBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  // Optimized shimmer placeholder widget
  Widget _buildShimmerPlaceholder({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
    );
  }

  // Build badges for types (subtitles, dub, nsfw, etc.)
  List<Widget> _buildBadges() {
    final badges = <Widget>[
      _buildBadge(label: anime.type, color: Colors.grey),
      if (anime.nsfw == true)
        _buildBadge(label: 'NSFW', color: Colors.red),
      if (anime.episodes.sub != null)
        _buildBadge(
          label: anime.episodes.sub.toString(),
          color: Colors.lightGreen,
          icon: Icons.subtitles,
        ),
      if (anime.episodes.dub != null)
        _buildBadge(
          label: anime.episodes.dub.toString(),
          color: Colors.lightBlue,
          icon: Icons.mic,
        ),
    ];
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              name: anime.name,
              id: anime.id,
              image: anime.poster.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800'),
              tag: "result",
            ),
          ),
        ),
        splashColor: Colors.pink.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).hoverColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: "poster-${anime.id}-result",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: anime.poster.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800'),
                        height: screenSize.width * 0.35,
                        width: screenSize.width * 0.25,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildShimmerPlaceholder(
                          width: screenSize.width * 0.35,
                          height: screenSize.width * 0.3,
                        ),
                        errorWidget: (context, url, error) => _buildShimmerPlaceholder(
                          width: screenSize.width * 0.35,
                          height: screenSize.width * 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (anime.japaneseTitle != null)
                          Text(
                            anime.japaneseTitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: _buildBadges(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 25,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Watch Now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
