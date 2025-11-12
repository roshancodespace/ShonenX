import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/utils/html_parser.dart';

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
        height: isSmallScreen ? 180 : 250,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
      color: colorScheme.surfaceContainerLow,
      child: Stack(
        children: [
          // Shimmer background
          const _ShimmerEffect(
            child: SizedBox.expand(),
          ),
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ShimmerEffect(
                    child: _SkeletonBar(width: 200, height: 24),
                  ),
                  const SizedBox(height: 12),
                  const _ShimmerEffect(
                    child: _SkeletonBar(width: 140, height: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const _ShimmerEffect(
                        child: _SkeletonBar(width: 70, height: 28),
                      ),
                      const SizedBox(width: 8),
                      const _ShimmerEffect(
                        child: _SkeletonBar(width: 60, height: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade50,
                Colors.grey.shade200,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
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
        color: colorScheme.surfaceContainerHighest,
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
    // final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = anime.bannerImage?.isNotEmpty == true
        ? anime.bannerImage!
        : (anime.coverImage?.large ?? anime.coverImage?.medium ?? '');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Hero(
          tag: heroTag,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 400),
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImageError(),
            filterQuality: FilterQuality.high,
          ),
        ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  anime.title?.english ??
                      anime.title?.romaji ??
                      anime.title?.native ??
                      'Unknown Title',
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                ),

                const SizedBox(height: 8),

                // Description (only on larger screens)
                if (!isSmallScreen && anime.description != null) ...[
                  Text(
                    parseHtmlToString(anime.description!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 12),

                // Info Tags
                Row(
                  children: [
                    if (anime.episodes != null)
                      _ModernInfoChip(
                        text: '${anime.episodes} EP',
                        icon: Iconsax.video_play,
                        isSmallScreen: isSmallScreen,
                      ),
                    if (anime.episodes != null && anime.duration != null)
                      const SizedBox(width: 8),
                    if (anime.duration != null)
                      _ModernInfoChip(
                        text: '${anime.duration}MIN',
                        icon: Iconsax.timer_1,
                        isSmallScreen: isSmallScreen,
                      ),
                    const Spacer(),
                    if (anime.averageScore != null)
                      _ScoreChip(
                        score: anime.averageScore!.toInt(),
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Status Badge
        if (anime.status != null)
          Positioned(
            top: 12,
            right: 12,
            child: _StatusBadge(
              status: anime.status!,
              isSmallScreen: isSmallScreen,
            ),
          ),

        // Format Badge
        if (anime.format != null)
          Positioned(
            top: 12,
            left: 12,
            child: _FormatBadge(
              format: anime.format!,
              isSmallScreen: isSmallScreen,
            ),
          ),
      ],
    );
  }
}

class _ModernInfoChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSmallScreen;

  const _ModernInfoChip({
    required this.text,
    required this.icon,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 12 : 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int score;
  final bool isSmallScreen;

  const _ScoreChip({
    required this.score,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star1,
            size: isSmallScreen ? 12 : 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmallScreen;

  const _StatusBadge({
    required this.status,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = status.split('.').last.toUpperCase();
    final Color statusColor = switch (status.split('.').last.toLowerCase()) {
      'airing' => const Color(0xFF4CAF50),
      'completed' => const Color(0xFF2196F3),
      'cancelled' => const Color(0xFFF44336),
      'releasing' => const Color(0xFFFF9800),
      'not_yet_released' => const Color(0xFFFFEB3B),
      _ => const Color(0xFF9E9E9E),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final String format;
  final bool isSmallScreen;

  const _FormatBadge({
    required this.format,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        format.split('.').last.toUpperCase(),
        style: TextStyle(
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 0.5,
        ),
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
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.image,
              size: 32,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
