import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart' as m;
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class PolaroidSpotlight extends StatelessWidget {
  final m.Media? anime;
  final String heroTag;
  final Function(m.Media)? onTap;

  const PolaroidSpotlight({
    super.key,
    required this.anime,
    required this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (anime == null) return const SizedBox.shrink();

    final imageUrl = anime!.bannerImage?.isNotEmpty == true
        ? anime!.bannerImage!
        : (anime!.coverImage?.large ?? anime!.coverImage?.medium ?? '');

    return GestureDetector(
      onTap: () => onTap?.call(anime!),
      child: Container(
        transform: Matrix4.identity()..rotateZ(-0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (anime!.averageScore != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Tag(
                          text: '${anime!.averageScore}',
                          icon: Iconsax.star1,
                          color: Colors.white.withOpacity(0.9),
                          textColor: Colors.black87,
                          hasShadow: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              anime!.title?.english ?? anime!.title?.romaji ?? 'Unknown Title',
              style: const TextStyle(
                color: Colors.black87,
                fontFamily: 'Caveat',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
