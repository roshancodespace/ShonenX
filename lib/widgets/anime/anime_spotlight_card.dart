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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerEffect(child: _SkeletonBar(width: 120, height: 24)),
          const SizedBox(height: 8),
          const _ShimmerEffect(child: _SkeletonBar(width: 180, height: 16)),
          const Spacer(),
          const _ShimmerEffect(child: _SkeletonBar(width: double.infinity, height: 24)),
          const SizedBox(height: 8),
          Row(
            children: [
              const _ShimmerEffect(child: _SkeletonBar(width: 80, height: 32)),
              const SizedBox(width: 8),
              const _ShimmerEffect(child: _SkeletonBar(width: 80, height: 32)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerEffect extends StatelessWidget {
  final Widget child;
  
  const _ShimmerEffect({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: child,
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
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
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
        // Base image with frosted glass effect
        Hero(
          tag: heroTag,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholderFadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImageError(),
            filterQuality: FilterQuality.high,
            useOldImageOnUrlChange: true,
          ),
        ),
        // Custom gradient with blur effect
        ClipRect(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colorScheme.shadow.withValues(alpha: 0.5),
                  colorScheme.shadow.withValues(alpha: 0.9),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopDetails(anime: anime),
              const Spacer(),
              _BottomDetails(anime: anime, isSmallScreen: isSmallScreen),
            ],
          ),
        ),
        // Score indicator
        if (anime.averageScore != null)
          Positioned(
            top: 16,
            left: 16,
            child: _ScoreIndicator(score: anime.averageScore?.toInt() ?? 0),
          ),
      ],
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  
  const _ScoreIndicator({required this.score});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color scoreColor = score >= 80 
        ? colorScheme.primary // Use theme color for high score
        : score >= 60 
            ? colorScheme.secondary // Use theme color for medium score
            : colorScheme.error; // Use theme color for low score
            
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface.withOpacity(0.9), // Use withOpacity for theming
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 3,
                backgroundColor: colorScheme.surfaceVariant,
                color: scoreColor,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
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
            color: colorScheme.tertiaryContainer,
            textColor: colorScheme.onTertiaryContainer,
            isGlass: true,
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
    
    // Create status chip with appropriate color
    Color statusColor = colorScheme.primaryContainer;
    if (anime.status != null) {
      final status = anime.status!.split('.').last.toLowerCase();
      if (status == 'airing') {
        statusColor = Colors.green.shade700;
      } else if (status == 'completed') {
        statusColor = Colors.blue.shade700;
      } else if (status == 'cancelled') {
        statusColor = Colors.red.shade700;
      } else if (status == 'hiatus') {
        statusColor = Colors.orange.shade700;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          anime.title?.english ??
              anime.title?.romaji ??
              anime.title?.native ??
              'Unknown Title',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Info row
        Row(
          children: [
            if (anime.episodes != null)
              _InfoChip(
                icon: Iconsax.play_circle,
                label: '${anime.episodes} eps',
                color: colorScheme.surface.withValues(alpha: 0.7),
              ),
            const SizedBox(width: 8),
            if (anime.duration != null)
              _InfoChip(
                icon: Iconsax.timer_1,
                label: '${anime.duration}m',
                color: colorScheme.surface.withValues(alpha: 0.7),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Status chip
        if (anime.status != null)
          _Tag(
            text: anime.status!.split('.').last,
            color: statusColor.withValues(alpha: 0.8),
            textColor: Colors.white,
            icon: Iconsax.timer,
            iconSize: 14,
          ),
        if (!isSmallScreen &&
            anime.genres != null &&
            anime.genres!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: anime.genres!.length > 3 ? 3 : anime.genres!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _Tag(
                text: anime.genres![index],
                color: colorScheme.surface.withValues(alpha: 0.5),
                textColor: Colors.white,
                isGlass: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 14, 
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool isGlass;
  final double? iconSize;

  const _Tag({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
    this.isGlass = false,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: isGlass ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: iconSize ?? 14, 
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    
    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: container,
      );
    }
    
    return container;
  }
}

class ImageFilter {
  final double blur;
  final double opacity;
  final double? saturation;
  final double? brightness;
  
  const ImageFilter({
    required this.blur,
    required this.opacity,
    this.saturation,
    this.brightness,
  });
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
      color: colorScheme.errorContainer.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 36,
              color: colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}