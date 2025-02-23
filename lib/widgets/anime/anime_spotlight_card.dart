import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

class AnimeSpotlightCard extends StatefulWidget {
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
  State<AnimeSpotlightCard> createState() => _AnimeSpotlightCardState();
}

class _AnimeSpotlightCardState extends State<AnimeSpotlightCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isSmallScreen ? 250 : 300,
        margin: EdgeInsets.only(
          top: isHovered ? 0 : 8,
          bottom: isHovered ? 8 : 0,
        ),
        child: Card(
          elevation: isHovered ? 8 : 2,
          shadowColor: theme.shadowColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.anime != null ? () => widget.onTap?.call(widget.anime!) : null,
            child: _buildCardContent(context, theme, isSmallScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme, bool isSmallScreen) {
    if (widget.anime == null) {
      return _buildSkeleton(theme);
    }

    if (widget.anime!.id == null) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    return _buildAnimeContent(context, theme, isSmallScreen);
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeContent(BuildContext context, ThemeData theme, bool isSmallScreen) {
    final imageUrl = widget.anime?.bannerImage?.isNotEmpty == true
        ? widget.anime!.bannerImage!
        : (widget.anime?.coverImage?.large ?? widget.anime!.coverImage?.medium ?? '');

    return Stack(
      children: [
        // Background Image
        Hero(
          tag: widget.heroTag,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: theme.colorScheme.surfaceVariant,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              color: theme.colorScheme.errorContainer,
              child: Icon(Icons.broken_image, color: theme.colorScheme.error),
            ),
          ),
        ),

        // Gradient Overlay
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isHovered ? 0.9 : 0.7,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Content
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(theme),
              const Spacer(),
              _buildBottomContent(theme, isSmallScreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow(ThemeData theme) {
    return Row(
      children: [
        if (widget.anime?.format != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.anime!.format.toString().split('.').last,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        const Spacer(),
        if (widget.anime?.averageScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.star1, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '${widget.anime!.averageScore}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomContent(ThemeData theme, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.anime?.title?.english ??
              widget.anime?.title?.romaji ??
              widget.anime?.title?.native ??
              'Unknown Title',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (widget.anime?.episodes != null)
              _InfoChip(
                icon: Icons.play_circle_outline,
                label: '${widget.anime!.episodes} Episodes',
              ),
            if (widget.anime?.duration != null) ...[
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${widget.anime!.duration}m',
              ),
            ],
          ],
        ),
        if (!isSmallScreen && widget.anime?.description != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.anime!.description!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}