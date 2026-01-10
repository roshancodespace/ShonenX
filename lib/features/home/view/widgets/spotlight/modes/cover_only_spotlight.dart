import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class CoverOnlySpotlight extends StatelessWidget {
  final UniversalMedia? anime;
  final String heroTag;
  final Function(UniversalMedia)? onTap;

  const CoverOnlySpotlight({
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
        : (anime!.coverImage.large ?? anime!.coverImage.medium ?? '');

    return GestureDetector(
      onTap: () => onTap?.call(anime!),
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
              top: 12,
              right: 12,
              child: Tag(
                text: '${anime!.averageScore}',
                icon: Iconsax.star1,
                hasShadow: true,
              ),
            ),
        ],
      ),
    );
  }
}
