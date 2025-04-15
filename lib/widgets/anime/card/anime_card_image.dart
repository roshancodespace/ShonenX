import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_shimmer.dart';

class AnimeImage extends StatelessWidget {
  final Media? anime;
  final String tag;
  final double height;

  const AnimeImage({
    super.key,
    required this.anime,
    required this.tag,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Hero(
      tag: tag,
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl:
                anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => ShimmerPlaceholder(height: height),
            errorWidget: (_, __, ___) => ShimmerPlaceholder(height: height),
            filterQuality: FilterQuality.high,
            useOldImageOnUrlChange: true,
          ),
        ),
      ),
    );
  }
}
