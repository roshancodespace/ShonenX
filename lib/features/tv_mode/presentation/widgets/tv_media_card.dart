import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class TvMediaCard extends StatelessWidget {
  final String title;
  final String cover;
  final String? banner;
  final double? score;
  final String? description;
  final int? year;
  final List<String>? genres;
  final VoidCallback? onTap;
  final VoidCallback? onFocused;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvMediaCard({
    super.key,
    required this.title,
    required this.cover,
    this.banner,
    this.score,
    this.description,
    this.year,
    this.genres,
    this.onTap,
    this.onFocused,
    this.onFocusChange,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final radius = GlobalUI.uiRoundness;

    return TvFocusable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      onFocusChange: (focused) {
        if (focused) onFocused?.call();
        onFocusChange?.call(focused);
      },
      onHoverChange: (hovered) {
        if (hovered) onFocused?.call();
      },
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        final bgImage = (active && banner != null && banner!.isNotEmpty)
            ? banner!
            : cover;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: active ? 420 : 150,
          height: active ? 220 : 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.6 : 0.3),
                blurRadius: active ? 24 : 8,
                spreadRadius: active ? 2 : 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: CachedNetworkImage(
                    key: ValueKey(bgImage),
                    imageUrl: bgImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, __, ___) => CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: active ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                width: 420,
                child: AnimatedOpacity(
                  opacity: active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 260),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.3, 0.6],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            (radius * 0.6).clamp(0.0, 16.0),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: cover,
                            width: 70,
                            height: 100,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 70,
                              height: 100,
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (year != null || (genres?.isNotEmpty ?? false))
                                Text(
                                  [
                                    if (year != null) year.toString(),
                                    if (genres?.isNotEmpty ?? false)
                                      genres!.join(' · '),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              if (year != null || (genres?.isNotEmpty ?? false))
                                const SizedBox(height: 6),
                              if (description != null)
                                Text(
                                  description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (score != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    opacity: active ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: _ScoreBadge(score: score!, radius: radius),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: active
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final double radius;

  const _ScoreBadge({required this.score, required this.radius});

  @override
  Widget build(BuildContext context) {
    final color = score >= 7
        ? Colors.greenAccent
        : score >= 5
        ? Colors.amberAccent
        : Colors.redAccent;

    final badgeRadius = (radius * 0.4).clamp(0.0, 10.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
