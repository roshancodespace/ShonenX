import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final Media? anime;
  final String tag;
  final VoidCallback? onTap;
  final String mode;

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = 'Classic',
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = _getWidth(widget.mode);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width,
          height: _getHeight(widget.mode),
          margin: EdgeInsets.only(
              top: _isHovered ? 0 : 4, bottom: _isHovered ? 4 : 0),
          child: _CardBuilder(
            mode: widget.mode,
            anime: widget.anime,
            tag: widget.tag,
            isHovered: _isHovered,
          ),
        ),
      ),
    );
  }

  double _getWidth(String mode) {
    return switch (mode) {
      'Compact' => 150.0,
      'Poster' || 'PosterV2' => 150.0,
      _ => 150.0,
    };
  }

  double _getHeight(String mode) {
    return switch (mode) {
      'Compact' => 180.0,
      'Poster' || 'PosterV2' => 180.0,
      _ => 180.0,
    };
  }
}

class _CardBuilder extends StatelessWidget {
  final String mode;
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _CardBuilder({
    required this.mode,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      'Compact' => _CompactCard(anime: anime, tag: tag, isHovered: isHovered),
      'Poster' => _PosterCard(anime: anime, tag: tag, isHovered: isHovered),
      'PosterV2' => _PosterV2Card(anime: anime, tag: tag, isHovered: isHovered),
      'Outlined' => _OutlinedCard(anime: anime, tag: tag, isHovered: isHovered),
      'Classic' ||
      _ =>
        _ClassicCard(anime: anime, tag: tag, isHovered: isHovered),
    };
  }
}

class _ClassicCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _ClassicCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withValues(alpha: isHovered ? 0.15 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimeImage(anime: anime, tag: tag, height: 180),
            _AnimeDetails(anime: anime),
          ],
        ),
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _CompactCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withValues(alpha: isHovered ? 0.1 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimeImage(anime: anime, tag: tag, height: 120),
            _AnimeDetails(anime: anime, padding: 6),
          ],
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _PosterCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withValues(alpha: isHovered ? 0.2 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            _AnimeImage(anime: anime, tag: tag, height: 260, showBadges: false),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.surface
                          .withValues(alpha: isHovered ? 0.7 : 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _AnimeTitle(anime: anime, maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterV2Card extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _PosterV2Card(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withValues(alpha: isHovered ? 0.2 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 180,
          height: 260,
          child: Stack(
            children: [
              _AnimeImage(
                  anime: anime, tag: tag, height: 260, showBadges: false),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface
                            .withValues(alpha: isHovered ? 0.7 : 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (anime != null && anime!.format != null)
                      _Tag(
                        text: anime!.format!.split('.').last,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(height: 4),
                    _AnimeTitle(anime: anime, maxLines: 2),
                    if (anime != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (anime!.episodes != null)
                            _Tag(
                              text: '${anime!.episodes} Ep',
                              color: theme.colorScheme.secondary,
                              icon: Iconsax.play,
                            ),
                          if (anime!.averageScore != null) ...[
                            const SizedBox(width: 6),
                            _Tag(
                              text: '${anime!.averageScore}%',
                              color: theme.colorScheme.secondary,
                              icon: Iconsax.star1,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _OutlinedCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHovered
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimeImage(anime: anime, tag: tag, height: 190),
            _AnimeDetails(anime: anime),
          ],
        ),
      ),
    );
  }
}

class _AnimeImage extends StatelessWidget {
  final Media? anime;
  final String tag;
  final double height;
  final bool showBadges;

  const _AnimeImage({
    required this.anime,
    required this.tag,
    required this.height,
    this.showBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Hero(
        tag: tag,
        child: CachedNetworkImage(
          imageUrl: anime?.coverImage?.large ?? '',
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 100),
          placeholder: (_, __) => const _ShimmerPlaceholder(),
          errorWidget: (_, __, ___) => const _ErrorPlaceholder(),
          memCacheHeight: height.toInt(),
        ),
      ),
    );
  }
}

class _AnimeDetails extends StatelessWidget {
  final Media? anime;
  final double padding;

  const _AnimeDetails({required this.anime, this.padding = 8});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimeTitle(anime: anime, maxLines: 2),
          if (anime?.episodes != null) ...[
            const SizedBox(height: 4),
            Text(
              '${anime!.episodes} Ep',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimeTitle extends StatelessWidget {
  final Media? anime;
  final int maxLines;

  const _AnimeTitle({required this.anime, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = anime?.title?.english ??
        anime?.title?.romaji ??
        anime?.title?.native ??
        'Unknown Title';
    return Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Tag({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
      child: Icon(
        Icons.broken_image,
        size: 32,
        color: theme.colorScheme.error,
      ),
    );
  }
}
