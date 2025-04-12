import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/utils/html_parser.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: anime != null ? () => onTap?.call(anime!) : null,
      child: Container(
        height: isSmallScreen ? 200 : 300, // Slightly reduced heights
        width: double.infinity, // Ensure it takes full width
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
      color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerEffect(child: _SkeletonBar(width: 100, height: 20)),
          const SizedBox(height: 8),
          const _ShimmerEffect(child: _SkeletonBar(width: 140, height: 14)),
          const Spacer(),
          const _ShimmerEffect(
              child: _SkeletonBar(width: double.infinity, height: 20)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              const _ShimmerEffect(child: _SkeletonBar(width: 60, height: 24)),
              const _ShimmerEffect(child: _SkeletonBar(width: 60, height: 24)),
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
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.repeated,
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
        Hero(
          tag: heroTag,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImageError(),
            filterQuality: FilterQuality.high,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.shadow.withValues(alpha: 0.3),
                colorScheme.shadow.withValues(alpha: 0.7),
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TopDetails(anime: anime),
              _BottomDetails(anime: anime, isSmallScreen: isSmallScreen),
            ],
          ),
        ),
        if (anime.averageScore != null)
          Positioned(
            top: 12,
            left: 12,
            child: _ScoreIndicator(
              score: anime.averageScore?.toInt() ?? 0,
              isSmallScreen: isSmallScreen,
            ),
          ),
      ],
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  final bool isSmallScreen;

  const _ScoreIndicator({required this.score, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = score >= 80
        ? colorScheme.primary
        : score >= 60
            ? colorScheme.secondary
            : colorScheme.error;

    return Container(
      width: isSmallScreen ? 40 : 48,
      height: isSmallScreen ? 40 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 34 : 42,
            height: isSmallScreen ? 34 : 42,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: scoreColor,
            ),
          ),
          Text(
            '$score',
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
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
          _InfoTag(
            text: anime.format!.split('.').last,
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.8),
            textColor: colorScheme.onTertiaryContainer,
            isGlass: true,
            isSmallScreen: MediaQuery.of(context).size.width < 600,
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

    Color statusColor = colorScheme.primaryContainer;
    if (anime.status != null) {
      final status = anime.status!.split('.').last.toLowerCase();
      statusColor = switch (status) {
        'airing' => Colors.green.shade700,
        'completed' => Colors.blue.shade700,
        'cancelled' => Colors.red.shade700,
        'releasing' => Colors.orange.shade700,
        'not_yet_released' => Colors.amber.shade300,
        _ => colorScheme.primaryContainer,
      };
    }

    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            anime.title?.english ??
                anime.title?.romaji ??
                anime.title?.native ??
                'Unknown Title',
            maxLines: isSmallScreen ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: colorScheme.shadow.withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!isSmallScreen) // Hide description on small screens
            Text(
              parseHtmlToString(anime.description ?? ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.2,
              ),
            ),
          if (!isSmallScreen) const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (anime.episodes != null)
                _InfoTag(
                  icon: Iconsax.video_play,
                  text: '${anime.episodes} eps',
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  textColor: colorScheme.onSurface,
                  isSmallScreen: isSmallScreen,
                ),
              if (anime.duration != null)
                _InfoTag(
                  icon: Iconsax.timer_1,
                  text: '${anime.duration}m',
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  textColor: colorScheme.onSurface,
                  isSmallScreen: isSmallScreen,
                ),
              if (anime.status != null)
                _InfoTag(
                  icon: Iconsax.timer,
                  text: anime.status!.split('.').last,
                  color: statusColor.withValues(alpha: 0.9),
                  textColor: Colors.white,
                  isSmallScreen: isSmallScreen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool isGlass;
  final bool isSmallScreen;

  const _InfoTag({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
    this.isGlass = false,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isGlass
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmallScreen ? 12 : 16, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    return isGlass
        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: container)
        : container;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
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
            Icon(Icons.broken_image_rounded,
                size: 36, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: GoogleFonts.montserrat(
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
