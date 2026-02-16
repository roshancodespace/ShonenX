import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/html_parser.dart';

class DefaultSpotlight extends StatefulWidget {
  final UniversalMedia? anime;
  final String heroTag;
  final Function(UniversalMedia)? onTap;

  const DefaultSpotlight({
    super.key,
    required this.anime,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<DefaultSpotlight> createState() => _DefaultSpotlightState();
}

class _DefaultSpotlightState extends State<DefaultSpotlight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.anime == null) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(28.0);

    final imageUrl = widget.anime!.bannerImage?.isNotEmpty == true
        ? widget.anime!.bannerImage!
        : (widget.anime!.coverImage.large ??
              widget.anime!.coverImage.medium ??
              '');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(widget.anime!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(_isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  child: Hero(
                    tag: widget.heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.8, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: _buildScoreBadge(context, widget.anime?.averageScore),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSlide(
                          offset: _isHovered
                              ? const Offset(0, 0)
                              : const Offset(0, 0.05),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          child: Text(
                            widget.anime!.title.english ??
                                widget.anime!.title.romaji ??
                                widget.anime!.title.native ??
                                'Unknown',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: isSmallScreen ? 24 : 36,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (!isSmallScreen &&
                            widget.anime!.description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            parseHtmlToString(widget.anime!.description!),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _SpotlightChip(
                              icon: Iconsax.video_play,
                              label:
                                  '${widget.anime?.episodes ?? "?"} Episodes',
                            ),
                            if (widget.anime?.duration != null)
                              _SpotlightChip(
                                icon: Iconsax.timer_1,
                                label: '${widget.anime!.duration} min',
                              ),
                            if (widget.anime?.format != null)
                              _SpotlightChip(
                                icon: Iconsax.monitor,
                                label: widget.anime!.format.toString(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(BuildContext context, dynamic score) {
    if (score == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.star1, size: 18, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            ((score ?? 0) / 10).toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpotlightChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
