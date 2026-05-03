import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';

class MediaCard extends StatefulWidget {
  final String title;
  final String tag;
  final Widget? badge;
  final String imageUrl;
  final VoidCallback onTap;
  final MediaCardStyle style;

  const MediaCard({
    super.key,
    required this.title,
    required this.tag,
    required this.imageUrl,
    required this.onTap,
    this.style = MediaCardStyle.classic,
    this.badge,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard>
    with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 150),
          lowerBound: 0.0,
          upperBound: 0.05,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    final theme = Theme.of(context);

    Widget cardContent;
    switch (widget.style) {
      case MediaCardStyle.minimal:
        cardContent = _buildMinimal(theme);
        break;
      case MediaCardStyle.expressive:
        cardContent = _buildExpressive(theme);
        break;
      case MediaCardStyle.classic:
        cardContent = _buildClassic(theme);
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Transform.scale(scale: _scale, child: cardContent),
      ),
    );
  }

  Widget _buildClassic(ThemeData theme) {
    return SizedBox(
      width: widget.style.layout.width,
      height: widget.style.layout.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(
            theme,
            borderRadius: 8,
            heightOverride: widget.style.layout.height * 0.75,
          ),
          const SizedBox(height: 6),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimal(ThemeData theme) {
    return SizedBox(
      width: widget.style.layout.width,
      height: widget.style.layout.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(
              theme,
              borderRadius: 0,
              heightOverride: widget.style.layout.height,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressive(ThemeData theme) {
    return Container(
      width: widget.style.layout.width,
      height: widget.style.layout.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceTint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(
            theme,
            borderRadius: 18,
            heightOverride: widget.style.layout.height / 1.45,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(
    ThemeData theme, {
    required double borderRadius,
    double? heightOverride,
    double? widthOverride,
  }) {
    final h = heightOverride ?? widget.style.layout.height / 1.4;
    final w = widthOverride ?? widget.style.layout.width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Hero(
        tag: widget.tag,
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          height: h,
          width: w,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            height: h,
            width: w,
            color: theme.colorScheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_not_supported,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
