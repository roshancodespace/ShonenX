import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class MangaCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const MangaCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    // Manga style is typically high contrast, black and white
    final borderColor = Colors.black;
    final bgColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.zero, // Sharp corners for manga panel look
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: Colors.black,
                  offset: const Offset(4, 4),
                  blurRadius: 0, // Hard shadow
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
              ),
              child:
                  AnimeImage(anime: anime, tag: tag, height: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (anime?.title?.english ?? anime?.title?.romaji ?? 'Unknown')
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontFamily:
                        'Roboto', // Or a more comic-like font if available
                  ),
                ),
                Text(
                  'VOL. ${anime?.episodes ?? "?"}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
