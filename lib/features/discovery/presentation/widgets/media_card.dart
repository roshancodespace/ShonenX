import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/liquid_glass.dart';

class MediaCard extends StatefulWidget {
  final String title;
  final String tag;
  final String? format;
  final Widget? badge;
  final String imageUrl;
  final VoidCallback onTap;
  final MediaCardStyle style;

  const MediaCard({
    super.key,
    required this.title,
    required this.tag,
    this.format,
    this.badge,
    required this.imageUrl,
    required this.onTap,
    this.style = MediaCardStyle.classic,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0,
      upperBound: 0.035,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails _) => _controller.forward();

  void _tapEnd([dynamic _]) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _controller.value;
    final theme = Theme.of(context);

    final child = switch (widget.style) {
      MediaCardStyle.classic => _ClassicCard(widget: widget, theme: theme),
      MediaCardStyle.minimal => _MinimalCard(widget: widget, theme: theme),
      MediaCardStyle.expressive => _ExpressiveCard(
        widget: widget,
        theme: theme,
      ),
      MediaCardStyle.material => _MaterialCard(widget: widget, theme: theme),
      MediaCardStyle.liquidGlass => _LiquidGlassCard(
        widget: widget,
        theme: theme,
      ),
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _tapDown,
        onTapCancel: _tapEnd,
        onTapUp: _tapEnd,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: child,
        ),
      ),
    );
  }
}

Widget _buildImage(
  MediaCard widget,
  ThemeData theme, {
  required double width,
  required double height,
  double radius = 18,
  BoxFit fit = BoxFit.cover,
}) {
  final cs = theme.colorScheme;

  return Hero(
    tag: widget.tag,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholderFadeInDuration: const Duration(milliseconds: 120),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_rounded,
            color: cs.onSurfaceVariant,
            size: 26,
          ),
        ),
      ),
    ),
  );
}

class _FormatBadge extends StatelessWidget {
  final String format;

  const _FormatBadge(this.format);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        format.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  final String? format;
  final Widget? badge;

  const _TopOverlay({this.format, this.badge});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (format != null) _FormatBadge(format!),
          const Spacer(),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}

class _ClassicCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;

  const _ClassicCard({required this.widget, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final layout = widget.style.layout;
    final imageHeight = layout.height * 0.76;

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildImage(
                widget,
                theme,
                width: layout.width,
                height: imageHeight,
              ),
              _TopOverlay(format: widget.format, badge: widget.badge),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;

  const _MinimalCard({required this.widget, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final layout = widget.style.layout;

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 1],
                  colors: [
                    Colors.transparent,
                    cs.scrim.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            _TopOverlay(format: widget.format, badge: widget.badge),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;

  const _ExpressiveCard({required this.widget, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final layout = widget.style.layout;
    final imageHeight = layout.height * 0.7;

    return SizedBox(
      width: layout.width,
      child: Container(
        width: layout.width,
        height: layout.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(
                  widget,
                  theme,
                  width: double.maxFinite,
                  height: imageHeight,
                  radius: 22,
                ),
                _TopOverlay(format: widget.format, badge: widget.badge),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;

  const _MaterialCard({required this.widget, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final layout = widget.style.layout;
    final imageHeight = layout.height * 0.7;

    return Container(
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: _buildImage(
                  widget,
                  theme,
                  width: layout.width,
                  height: imageHeight,
                  radius: 0,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.scrim.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              _TopOverlay(format: widget.format, badge: widget.badge),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
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

class _LiquidGlassCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;

  const _LiquidGlassCard({required this.widget, required this.theme});

  @override
  Widget build(BuildContext context) {
    final layout = widget.style.layout;

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.format != null)
                    LiquidGlass(
                      image: CachedNetworkImageProvider(widget.imageUrl),
                      radius: 999,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      alignment: Alignment.topLeft,
                      isDark: true,
                      refraction: Offset.zero,
                      child: Text(
                        widget.format!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (widget.badge != null) widget.badge!,
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: LiquidGlass(
                image: CachedNetworkImageProvider(widget.imageUrl),
                radius: 28,
                alignment: Alignment.bottomCenter,
                isDark: true,
                refraction: Offset.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
