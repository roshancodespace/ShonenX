import 'package:flutter/material.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class TvMediaCard extends StatelessWidget {
  final String title;
  final String cover;
  final String? banner;
  final double? score;
  final int? progress;
  final int? totalEpisodes;
  final String? format;
  final String? status;
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
    this.progress,
    this.totalEpisodes,
    this.format,
    this.status,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = GlobalUI.uiRoundness;

    final hasProgress = progress != null && progress! > 0;
    final progressFraction =
        (hasProgress && totalEpisodes != null && totalEpisodes! > 0)
        ? (progress! / totalEpisodes!).clamp(0.0, 1.0)
        : null;

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
                  child: TvSmartImage(
                    key: ValueKey(bgImage),
                    imageUrl: bgImage,
                    fit: BoxFit.cover,
                    memCacheWidth: active ? 800 : 400,
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
                      vertical: 18,
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
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.3, 0.65],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            (radius * 0.6).clamp(0.0, 16.0),
                          ),
                          child: TvSmartImage(
                            imageUrl: cover,
                            width: 70,
                            height: 100,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
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
                              const SizedBox(height: 5),
                              _buildMetadataRow(),
                              if (description != null &&
                                  description!.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-Left Badges (Progress / Format)
              if (hasProgress)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _ProgressBadge(
                    progress: progress!,
                    total: totalEpisodes,
                    radius: radius,
                    active: active,
                  ),
                )
              else if (format != null && format!.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _FormatBadge(format: format!, radius: radius),
                ),

              // Top-Right Score Badge
              if (score != null && score! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ScoreBadge(score: score!, radius: radius),
                ),

              // Bottom Progress Bar
              if (hasProgress && progressFraction != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: active ? 4.0 : 3.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),

              // Focus Outline Border
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: active
                        ? Colors.white.withValues(alpha: 0.85)
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

  Widget _buildMetadataRow() {
    final metaTokens = <String>[];

    if (format != null && format!.isNotEmpty) {
      metaTokens.add(format!.toUpperCase());
    }

    if (progress != null && progress! > 0) {
      metaTokens.add(
        'EP $progress${totalEpisodes != null ? ' / $totalEpisodes' : ''}',
      );
    } else if (totalEpisodes != null && totalEpisodes! > 0) {
      metaTokens.add('$totalEpisodes eps');
    }

    if (year != null) {
      metaTokens.add(year.toString());
    }

    if (genres != null && genres!.isNotEmpty) {
      metaTokens.add(genres!.take(2).join(', '));
    }

    if (metaTokens.isEmpty) return const SizedBox.shrink();

    return Text(
      metaTokens.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.65),
        fontSize: 11,
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int progress;
  final int? total;
  final double radius;
  final bool active;

  const _ProgressBadge({
    required this.progress,
    this.total,
    required this.radius,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final badgeRadius = (radius * 0.4).clamp(0.0, 10.0);
    final text = total != null ? 'EP $progress / $total' : 'EP $progress';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(badgeRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_filled_rounded,
            size: 11,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final String format;
  final double radius;

  const _FormatBadge({required this.format, required this.radius});

  @override
  Widget build(BuildContext context) {
    final badgeRadius = (radius * 0.4).clamp(0.0, 10.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(badgeRadius),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Text(
        format.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
