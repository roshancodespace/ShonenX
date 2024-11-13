import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nekoflow/data/models/anime_interface.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final dynamic tag;

  const AnimeCard({super.key, required this.anime, required this.tag});

  Widget _buildShimmerPlaceholder(
      {required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            id: anime.id,
            image: anime.poster.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800'),
            title: anime.name,
            tag: tag,
            type: anime.type,
          ),
        ),
      ),
      child: Container(
        width: screenSize.width * 0.4,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Hero(
                transitionOnUserGestures: true,
                createRectTween: (begin, end) {
                  return CustomRectTween(begin: begin!, end: end!);
                },
                tag: 'poster-${anime.id}-$tag', // Ensure unique tag
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Same border radius
                  child: Image.network(
                    anime.poster.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800'),
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildShimmerPlaceholder(
                        width: screenSize.width * 0.4,
                        height: screenSize.width * 0.6,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Text('Image Not Available')),
                  ),
                ),
              ),
              // Gradient overlay for text readability
              Positioned(
                bottom: 0,
                child: Container(
                  width: screenSize.width * 0.4,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    anime.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Anime type and play icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        anime.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomRectTween extends RectTween {
  CustomRectTween({required Rect begin, required Rect end}) : super(begin: begin, end: end);
  @override
  Rect lerp(double t) {
    final lerped = super.lerp(t);
    // You can apply additional transformations to the lerped Rect here
    // E.g., you could scale or offset the rect
    return Rect.fromLTRB(
      lerped!.left,
      lerped.top,
      lerped.right * 1, // Example: scale width by 10%
      lerped.bottom * 1, // Example: scale height by 10%
    );
  }
}

