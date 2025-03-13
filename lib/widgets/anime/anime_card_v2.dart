import 'dart:ui';

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
    this.mode = 'Card', // Default to your preferred mode
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = _getWidth(widget.mode);
    final height = _getHeight(widget.mode);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          margin: EdgeInsets.only(
              top: _isHovered ? 0 : 4, bottom: _isHovered ? 4 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getRadius(widget.mode)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: _isHovered ? 0.25 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 140.0 : 160.0,
      'Compact' => screenWidth < 600 ? 100.0 : 120.0,
      'Poster' => screenWidth < 600 ? 160.0 : 180.0,
      'Glass' => screenWidth < 600 ? 150.0 : 170.0,
      'Neon' => screenWidth < 600 ? 140.0 : 160.0,
      'Minimal' => screenWidth < 600 ? 130.0 : 150.0,
      'Cinematic' => screenWidth < 600 ? 200.0 : 240.0,
      _ => screenWidth < 600 ? 140.0 : 160.0, // Default to Card
    };
  }

  double _getHeight(String mode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 200.0 : 240.0,
      'Compact' => screenWidth < 600 ? 150.0 : 180.0,
      'Poster' => screenWidth < 600 ? 260.0 : 300.0,
      'Glass' => screenWidth < 600 ? 220.0 : 260.0,
      'Neon' => screenWidth < 600 ? 200.0 : 240.0,
      'Minimal' => screenWidth < 600 ? 180.0 : 220.0,
      'Cinematic' => screenWidth < 600 ? 140.0 : 160.0,
      _ => screenWidth < 600 ? 200.0 : 240.0, // Default to Card
    };
  }

  double _getRadius(String mode) {
    return switch (mode) {
      'Card' => 15.0,
      'Compact' => 12.0,
      'Poster' => 18.0,
      'Glass' => 20.0,
      'Neon' => 16.0,
      'Minimal' => 10.0,
      'Cinematic' => 14.0,
      _ => 15.0,
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
      'Glass' => _GlassCard(anime: anime, tag: tag, isHovered: isHovered),
      'Neon' => _NeonCard(anime: anime, tag: tag, isHovered: isHovered),
      'Minimal' => _MinimalCard(anime: anime, tag: tag, isHovered: isHovered),
      'Cinematic' =>
        _CinematicCard(anime: anime, tag: tag, isHovered: isHovered),
      'Card' || _ => _Card(anime: anime, tag: tag, isHovered: isHovered),
    };
  }
}

// Original Card Mode (Your Preferred Design)
// Modernized Card Mode
class _Card extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _Card(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          // Base image
          _AnimeImage(anime: anime, tag: tag, height: double.infinity),

          // Overlay gradient with improved colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.shadowColor.withValues(alpha: 0.5), // Lighter middle
                  theme.shadowColor.withValues(alpha: 0.9), // Darker bottom
                ],
                stops: const [
                  0.4,
                  0.75,
                  1.0
                ], // Adjusted stops for smoother transition
              ),
            ),
          ),

          // Content container with better padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with format badge
                if (anime?.format != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Tag(
                        text: anime!.format!.split('.').last,
                        color: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.85),
                        textColor: theme.colorScheme.onTertiaryContainer,
                        hasShadow: true,
                      ),
                    ],
                  ),

                const Spacer(),

                // Bottom content with improved spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score with improved badge
                    if (anime?.averageScore != null)
                      _Tag(
                        text: '${anime!.averageScore}',
                        color: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                        icon: Iconsax.star1,
                        hasShadow: true,
                      ),

                    const SizedBox(height: 8), // Increased spacing

                    // Title with enhanced styling
                    _AnimeTitle(
                      anime: anime,
                      maxLines: 2,
                      enhanced: true, // New property for enhanced styling
                    ),

                    const SizedBox(height: 6),

                    // Episode info with enhanced styling
                    _EpisodesInfo(
                      anime: anime,
                      enhanced: true, // New property for enhanced styling
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hover effect overlay
          if (isHovered)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                        ?.borderRadius ??
                    BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

// Modernized Compact Mode
class _CompactCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _CompactCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          // Base image
          _AnimeImage(anime: anime, tag: tag, height: double.infinity),

          // Overlay gradient with improved colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.shadowColor.withValues(alpha: 0.85),
                ],
                stops: const [0.65, 1.0],
              ),
            ),
          ),

          // Content with improved padding
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with score badge
                if (anime?.averageScore != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Tag(
                        text: '${anime!.averageScore}',
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        textColor: theme.colorScheme.onPrimary,
                        icon: Iconsax.star1,
                        hasShadow: true,
                      ),
                    ],
                  ),

                const Spacer(),

                // Bottom content with improved spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with enhanced styling
                    _AnimeTitle(
                      anime: anime,
                      maxLines: 1,
                      enhanced: true,
                    ),

                    const SizedBox(height: 4),

                    // Format and episode info in a row
                    Row(
                      children: [
                        if (anime?.format != null)
                          Text(
                            anime!.format!.split('.').last,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        if (anime?.format != null && anime?.episodes != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),

                        // Episodes with enhanced styling
                        if (anime?.episodes != null)
                          Text(
                            '${anime!.episodes} ep',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hover effect overlay
          if (isHovered)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
        ],
      ),
    );
  }
}

// Modernized Poster Mode
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isHovered ? 0.3 : 0.2),
            blurRadius: isHovered ? 15 : 10,
            spreadRadius: isHovered ? 2 : 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: Stack(
          children: [
            // Base image
            _AnimeImage(anime: anime, tag: tag, height: double.infinity),

            // Overlay with enhanced gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.5, 0.75, 1.0],
                ),
              ),
            ),

            // Content container with improved padding
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with adaptive opacity based on hover
                  Opacity(
                    opacity: isHovered ? 1.0 : 0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Score in top left
                        if (anime?.averageScore != null)
                          _Tag(
                            text: '${anime!.averageScore}%',
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.9),
                            textColor: theme.colorScheme.onPrimary,
                            icon: Iconsax.star1,
                            hasShadow: true,
                          ),

                        // Format in top right
                        if (anime?.format != null)
                          _Tag(
                            text: anime!.format!.split('.').last,
                            color: theme.colorScheme.tertiaryContainer
                                .withValues(alpha: 0.9),
                            textColor: theme.colorScheme.onTertiaryContainer,
                            hasShadow: true,
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom content with better spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with enhanced styling
                      _AnimeTitle(
                        anime: anime,
                        maxLines: 2,
                        enhanced: true,
                      ),

                      const SizedBox(height: 10),

                      // Episodes with improved badge
                      if (anime?.episodes != null)
                        _Tag(
                          text: '${anime!.episodes} Episodes',
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.9),
                          textColor: theme.colorScheme.onSecondary,
                          icon: Iconsax.play_circle,
                          hasShadow: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced hover effect with subtle glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.7)
                      : Colors.transparent,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modernized Glass Mode
class _GlassCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _GlassCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          // Base image
          _AnimeImage(anime: anime, tag: tag, height: double.infinity),

          // Blur overlay with better glass effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isHovered ? 3.0 : 1.5,
              sigmaY: isHovered ? 3.0 : 1.5,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface
                        .withValues(alpha: isHovered ? 0.2 : 0.15),
                    theme.colorScheme.surface
                        .withValues(alpha: isHovered ? 0.3 : 0.2),
                  ],
                ),
                border: Border.all(
                  color: isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                  width: isHovered ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              height: double.infinity,
              width: double.infinity,
            ),
          ),

          // Content container with improved padding
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with adaptive layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (anime?.format != null)
                      _GlassTag(
                        text: anime!.format!.split('.').last,
                        primaryColor: theme.colorScheme.primary,
                        textColor: Colors.white,
                      ),
                    if (anime?.averageScore != null)
                      _GlassTag(
                        text: '${anime!.averageScore}%',
                        primaryColor: theme.colorScheme.tertiary,
                        textColor: Colors.white,
                        icon: Iconsax.star1,
                      ),
                  ],
                ),

                const Spacer(),

                // Bottom content with enhanced styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with glass-appropriate styling
                    Text(
                      anime?.title?.english ??
                          anime?.title?.romaji ??
                          anime?.title?.native ??
                          'Unknown Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Episode information with glass styling
                    if (anime?.episodes != null)
                      _GlassTag(
                        text: '${anime!.episodes} Episodes',
                        primaryColor: theme.colorScheme.secondary,
                        textColor: Colors.white,
                        icon: Iconsax.play,
                        large: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// New Glass-specific Tag Component
class _GlassTag extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final Color textColor;
  final IconData? icon;
  final bool large;

  const _GlassTag({
    required this.text,
    required this.primaryColor,
    required this.textColor,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(large ? 10 : 8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 8,
            vertical: large ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.3),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(large ? 10 : 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: large ? 14 : 12,
                  color: textColor,
                ),
                SizedBox(width: large ? 6 : 4),
              ],
              Text(
                text,
                style: (large
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.labelSmall)
                    ?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Neon Mode - Glowing neon borders
class _NeonCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _NeonCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        border: Border.all(
          color: isHovered
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: isHovered ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isHovered)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: Stack(
          children: [
            _AnimeImage(anime: anime, tag: tag, height: double.infinity),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.shadowColor.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimeTitle(anime: anime, maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (anime?.episodes != null)
                        _Tag(
                          text: '${anime!.episodes} Ep',
                          color: Colors.transparent,
                          textColor: Colors.white,
                          icon: Iconsax.play,
                        ),
                      if (anime?.format != null) ...[
                        const SizedBox(width: 6),
                        _Tag(
                          text: anime!.format!.split('.').last,
                          color: Colors.transparent,
                          textColor: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Minimal Mode - Clean and flat
class _MinimalCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _MinimalCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          _AnimeImage(anime: anime, tag: tag, height: double.infinity),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimeTitle(anime: anime, maxLines: 1, minimal: true),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (anime?.episodes != null)
                        Text(
                          '${anime!.episodes} Ep',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (anime?.averageScore != null)
                        Text(
                          '${anime!.averageScore}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
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

// Cinematic Mode - Wide and dramatic
class _CinematicCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _CinematicCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          _AnimeImage(anime: anime, tag: tag, height: double.infinity),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.shadowColor.withValues(alpha: 0.8),
                  Colors.transparent,
                  theme.shadowColor.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnimeTitle(anime: anime, maxLines: 2),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (anime?.episodes != null)
                            _Tag(
                              text: '${anime!.episodes} Ep',
                              color: theme.colorScheme.secondary,
                              textColor: Colors.white,
                              icon: Iconsax.play,
                            ),
                          if (anime?.averageScore != null) ...[
                            const SizedBox(width: 6),
                            _Tag(
                              text: '${anime!.averageScore}%',
                              color: theme.colorScheme.primary,
                              textColor: Colors.white,
                              icon: Iconsax.star1,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (anime?.format != null)
                  _Tag(
                    text: anime!.format!.split('.').last,
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shared Components
class _AnimeImage extends StatelessWidget {
  final Media? anime;
  final String tag;
  final double height;

  const _AnimeImage({
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
            placeholder: (_, __) => _ShimmerPlaceholder(height: height),
            errorWidget: (_, __, ___) => _ErrorPlaceholder(height: height),
            filterQuality: FilterQuality.high,
            useOldImageOnUrlChange: true,
          ),
        ),
      ),
    );
  }
}

// Enhanced Anime Title Component
class _AnimeTitle extends StatelessWidget {
  final Media? anime;
  final int maxLines;
  final bool minimal;
  final bool enhanced;

  const _AnimeTitle({
    required this.anime,
    required this.maxLines,
    this.minimal = false,
    this.enhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = anime?.title?.english ??
        anime?.title?.romaji ??
        anime?.title?.native ??
        'Unknown Title';

    if (minimal) {
      return Text(
        title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    if (enhanced) {
      return Text(
        title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );
    }

    // Original style
    return Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

// Enhanced Episodes Info Component
class _EpisodesInfo extends StatelessWidget {
  final Media? anime;
  final bool compact;
  final bool enhanced;

  const _EpisodesInfo({
    required this.anime,
    this.compact = false,
    this.enhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (anime?.episodes == null) return const SizedBox.shrink();

    if (enhanced) {
      return Row(
        children: [
          Icon(
            Iconsax.play_circle,
            size: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            compact ? '${anime!.episodes}ep' : '${anime!.episodes} episodes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    // Original version
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    return Text(
      compact ? '${anime!.episodes}ep' : '${anime!.episodes} eps',
      style: textStyle,
    );
  }
}

// Enhanced Tag Component
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool hasShadow;

  const _Tag({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final double height;

  const _ShimmerPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
  final double height;

  const _ErrorPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
      child: Icon(
        Icons.broken_image,
        size: 40,
        color: theme.colorScheme.error,
      ),
    );
  }
}
