import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class ContinueCardLayout extends StatelessWidget {
  final bool isWideBanner;
  final double width;
  final double height;
  final bool isActive;
  final bool isLoading;
  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final String badgeText;
  final String? imageUrl;
  final Widget Function(BuildContext context, ColorScheme cs)? thumbnailBuilder;
  final IconData fallbackIcon;
  final String badgeType;

  const ContinueCardLayout({
    super.key,
    required this.isWideBanner,
    required this.width,
    required this.height,
    required this.isActive,
    required this.isLoading,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.badgeText,
    this.imageUrl,
    this.thumbnailBuilder,
    required this.fallbackIcon,
    required this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isWideBanner) {
      return _buildWideBanner(theme);
    } else {
      return _buildClassic(theme);
    }
  }

  Widget _buildClassic(ThemeData theme) {
    final cs = theme.colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildThumbnailStack(
              borderRadius: GlobalUI.uiRoundness,
              badge: _buildBadge(
                theme,
                text: badgeType,
                backgroundColor: cs.surfaceContainerHighest.withValues(
                  alpha: 0.92,
                ),
                textColor: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBanner(ThemeData theme) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 0.0,
        ),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildThumbnailStack(
                borderRadius: GlobalUI.uiRoundness,
                badge: _buildBadge(
                  theme,
                  text: badgeText,
                  backgroundColor: cs.primaryContainer,
                  textColor: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    ThemeData theme, {
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailStack({required double borderRadius, Widget? badge}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailBuilder != null)
                thumbnailBuilder!(context, cs)
              else if (imageUrl != null && imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildFallbackImage(cs),
                )
              else
                _buildFallbackImage(cs),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1],
                      colors: [
                        Colors.transparent,
                        cs.scrim.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: Colors.black26,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),

              if (badge != null) badge,

              AnimatedContainer(
                duration: Durations.short4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isActive ? cs.tertiary : Colors.transparent,
                    width: isActive ? 2.5 : 0.0,
                  ),
                ),
              ),

              if (isLoading)
                const ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackImage(ColorScheme cs) {
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Icon(fallbackIcon, color: cs.onSurfaceVariant),
    );
  }
}
