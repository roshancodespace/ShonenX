import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

class AnimeSpotlightCard extends StatelessWidget {
  final Media? anime;
  final Function(Media)? onTap;
  final String heroTag;

  const AnimeSpotlightCard({
    super.key,
    required this.anime,
    this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: anime != null ? () => onTap?.call(anime!) : null,
      child: Container(
        height: isSmallScreen ? 260 : 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), // Match 'Card' mode
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1), // Match 'Card' shadow
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15), // Match 'Card' mode
          child: _CardContent(
            anime: anime,
            heroTag: heroTag,
            isSmallScreen: isSmallScreen,
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Media? anime;
  final String heroTag;
  final bool isSmallScreen;

  const _CardContent({
    required this.anime,
    required this.heroTag,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return anime == null || anime!.id == null
        ? const _Skeleton()
        : _AnimeContent(
            anime: anime!,
            heroTag: heroTag,
            isSmallScreen: isSmallScreen,
          );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3), // Match AnimatedAnimeCard
      padding: const EdgeInsets.all(8), // Match padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBar(width: 100, height: 16),
          const SizedBox(height: 4),
          const _SkeletonBar(width: 150, height: 12),
          const Spacer(),
          const _SkeletonBar(width: double.infinity, height: 20),
          const SizedBox(height: 4),
          const _SkeletonBar(width: double.infinity, height: 32),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _AnimeContent extends StatelessWidget {
  final Media anime;
  final String heroTag;
  final bool isSmallScreen;

  const _AnimeContent({
    required this.anime,
    required this.heroTag,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = anime.bannerImage?.isNotEmpty == true
        ? anime.bannerImage!
        : (anime.coverImage?.large ?? anime.coverImage?.medium ?? '');

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: heroTag,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150), // Match AnimatedAnimeCard
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImageError(),
            filterQuality: FilterQuality.high, // Match AnimatedAnimeCard
            useOldImageOnUrlChange: true, // Match AnimatedAnimeCard
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.shadow.withOpacity(0.8), // Match 'Card' gradient
                colorScheme.shadow,
              ],
              stops: const [0.3, 0.9, 1.0], // Match 'Card' gradient stops
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // Adjusted padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopDetails(anime: anime),
              const Spacer(),
              _BottomDetails(anime: anime, isSmallScreen: isSmallScreen),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopDetails extends StatelessWidget {
  final Media anime;

  const _TopDetails({required this.anime});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (anime.format != null)
          _Tag(
            text: anime.format!.split('.').last,
            color: colorScheme.tertiaryContainer, // Match 'Card' format tag
            textColor: colorScheme.onTertiaryContainer,
          ),
      ],
    );
  }
}

class _BottomDetails extends StatelessWidget {
  final Media anime;
  final bool isSmallScreen;

  const _BottomDetails({required this.anime, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anime.averageScore != null)
          _Tag(
            text: '${anime.averageScore}',
            color: colorScheme.primary, // Match 'Card' score tag
            textColor: colorScheme.onPrimary,
          ),
        const SizedBox(height: 4),
        Text(
          anime.title?.english ?? anime.title?.romaji ?? anime.title?.native ?? 'Unknown Title',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold, // Match 'Card' boldness
            color: Colors.white, // Match 'Card' color
            shadows: const [
              Shadow(
                color: Colors.black54, // Match 'Card' shadow
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (anime.episodes != null)
              Text(
                '${anime.episodes} eps', // Match 'Card' episode style
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // Match 'Card'
                ),
              ),
            if (anime.duration != null)
              _Tag(
                text: '${anime.duration}m',
                color: colorScheme.secondaryContainer.withOpacity(0.2),
                textColor: colorScheme.onPrimaryContainer,
                icon: Iconsax.timer,
              ),
            if (anime.status != null)
              _Tag(
                text: anime.status!.split('.').last,
                color: colorScheme.primaryContainer.withOpacity(0.2),
                textColor: colorScheme.onPrimaryContainer,
              ),
          ],
        ),
        if (!isSmallScreen && anime.genres != null && anime.genres!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: anime.genres!.take(3).map((genre) => _Tag(
              text: genre,
              color: colorScheme.onSurfaceVariant.withOpacity(0.2),
              textColor: Colors.white,
            )).toList(),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Tag({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Match 'Card' padding
      decoration: BoxDecoration(
        color: color, // Match 'Card' solid background
        borderRadius: BorderRadius.circular(8), // Match 'Card' radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor), // Match 'Card' icon size
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12, // Match 'Card' font size
              fontWeight: FontWeight.bold, // Match 'Card' boldness
              color: textColor, // Match 'Card' color
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3), // Match AnimatedAnimeCard
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.errorContainer.withOpacity(0.6), // Match AnimatedAnimeCard
      child: Icon(
        Icons.broken_image,
        size: 40, // Match AnimatedAnimeCard
        color: colorScheme.error,
      ),
    );
  }
}