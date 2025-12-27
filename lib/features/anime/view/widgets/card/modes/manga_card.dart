import 'package:cached_network_image/cached_network_image.dart';
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
        border: Border.all(color: borderColor, width: 3), // Thicker border
        borderRadius: BorderRadius.zero, // Sharp corners for manga panel look
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: Colors.black,
                  offset: const Offset(6, 6),
                  blurRadius: 0, // Hard shadow
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: tag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: CachedNetworkImage(
                        imageUrl: anime?.coverImage?.large ??
                            anime?.coverImage?.medium ??
                            '',
                        fit: BoxFit.cover,
                        memCacheHeight: 400,
                        placeholder: (_, __) =>
                            const AnimeCardShimmer(height: double.infinity),
                        errorWidget: (_, __, ___) =>
                            const AnimeCardShimmer(height: double.infinity),
                        imageBuilder: (context, imageProvider) {
                          if (isHovered) {
                            return Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            );
                          }
                          return ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                        useOldImageOnUrlChange: true,
                      ),
                    ),
                  ),

                  // Rating Badge (Comic Style)
                  if (anime?.averageScore != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            left: BorderSide(color: Colors.white, width: 2),
                            bottom: BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        child: Text(
                          '${anime!.averageScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (anime?.title?.english ?? anime?.title?.romaji ?? 'Unknown')
                      .toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily:
                        'Roboto', // Or a more comic-like font if available
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'VOL. ${anime?.episodes ?? "?"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
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
