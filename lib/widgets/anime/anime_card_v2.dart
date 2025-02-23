import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final Media? anime;
  final String tag;
  final VoidCallback? onTap;
  final String mode; // New mode parameter

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = 'Classic', // Default to 'Classic'
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _getWidth(widget.mode),
          margin: EdgeInsets.only(
            top: isHovered ? 0 : 8,
            bottom: isHovered ? 8 : 0,
          ),
          child: _buildCardByMode(context, colorScheme),
        ),
      ),
    );
  }

  double _getWidth(String mode) {
    switch (mode) {
      case 'Compact':
        return 150;
      case 'Poster':
        return 180;
      case 'Minimal':
      case 'Outlined':
      case 'Classic':
      default:
        return 200;
    }
  }

  Widget _buildCardByMode(BuildContext context, ColorScheme colorScheme) {
    switch (widget.mode) {
      case 'Minimal':
        return _buildMinimalCard(context, colorScheme);
      case 'Compact':
        return _buildCompactCard(context, colorScheme);
      case 'Poster':
        return _buildPosterCard(context, colorScheme);
      case 'Outlined':
        return _buildOutlinedCard(context, colorScheme);
      case 'Classic':
      default:
        return _buildClassicCard(context, colorScheme);
    }
  }

  // Classic (Original) Style
  Widget _buildClassicCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isHovered ? 8 : 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(height: 180),
          _buildDetails(context, fontSize: 14),
        ],
      ),
    );
  }

  // Minimal Style
  Widget _buildMinimalCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(height: 180, showBadges: false),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              widget.anime?.title?.english ??
                  widget.anime?.title?.romaji ??
                  widget.anime?.title?.native ??
                  'Unknown Title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Style
  Widget _buildCompactCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isHovered ? 6 : 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(height: 120),
          _buildDetails(context, fontSize: 12, padding: 8),
        ],
      ),
    );
  }

  // Poster Style
  Widget _buildPosterCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isHovered ? 10 : 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          _buildImage(height: 260, showBadges: false),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Text(
                widget.anime?.title?.english ??
                    widget.anime?.title?.romaji ??
                    widget.anime?.title?.native ??
                    'Unknown Title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Outlined Style
  Widget _buildOutlinedCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isHovered ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isHovered
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(height: 190),
          _buildDetails(context, fontSize: 13),
        ],
      ),
    );
  }

  Widget _buildImage({
    required double height,
    bool showBadges = true,
  }) {
    return Stack(
      children: [
        Hero(
          tag: widget.tag,
          child: CachedNetworkImage(
            imageUrl: widget.anime?.coverImage?.large ?? '',
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => ShimmerPlaceholder(height: height),
            errorWidget: (context, url, error) =>
                ErrorPlaceholder(height: height),
          ),
        ),
        if (widget.anime != null && showBadges) ...[
          _buildGradientOverlay(),
          _buildScore(),
          if (widget.anime?.format != null) _buildFormatBadge(),
        ],
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isHovered ? 0.8 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScore() {
    if (widget.anime?.averageScore == null) return const SizedBox.shrink();

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.star1, size: 14, color: Colors.amber),
            const SizedBox(width: 6),
            Text(
              '${widget.anime!.averageScore}%',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.anime!.format.toString().split('.').last,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context,
      {required double fontSize, double padding = 12}) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.anime?.title?.english ??
                widget.anime?.title?.romaji ??
                widget.anime?.title?.native ??
                'Unknown Title',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (widget.anime?.episodes != null) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.anime!.episodes} Episodes',
              style: GoogleFonts.montserrat(
                fontSize: fontSize - 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShimmerPlaceholder extends StatelessWidget {
  final double height;
  const ShimmerPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class ErrorPlaceholder extends StatelessWidget {
  final double height;
  const ErrorPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 32,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
