import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/component_layout.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/shared/widgets/liquid_glass.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/experimental_liquid_card.dart';

import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaCard extends ConsumerWidget {
  final String title;
  final String tag;
  final String? format;
  final Widget? badge;
  final String imageUrl;
  final VoidCallback onTap;
  final MediaCardStyle style;
  final Map<String, dynamic>? config;

  const MediaCard({
    super.key,
    required this.title,
    required this.tag,
    this.format,
    this.badge,
    required this.imageUrl,
    required this.onTap,
    this.style = MediaCardStyle.classic,
    this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final layout = style.getScaledLayout(scale);

    return FocusHoverDetector(
      onTap: onTap,

      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },

      builder: (context, isFocused, isHovered) {
        final isActive = isFocused || isHovered;
        final activeConfig =
            config ??
            (style == MediaCardStyle.experimentalLiquid
                ? ref.watch(uiPrefsProvider).experimentalConfig
                : null);

        final baseLayout = style.baseLayout;
        final child = switch (style) {
          MediaCardStyle.classic => _ClassicCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.minimal => _MinimalCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.expressive => _ExpressiveCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.material => _MaterialCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.liquidGlass => _LiquidGlassCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.experimentalLiquid => ExperimentalLiquidCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
            config: activeConfig,
          ),

          MediaCardStyle.cinematic => _CinematicCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.frosted => _FrostedCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.neon => _NeonCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.compact => _CompactCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.editorial => _EditorialCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),

          MediaCardStyle.wideBanner => _WideBannerCard(
            widget: this,
            theme: theme,
            isActive: isActive,
            layout: baseLayout,
          ),
        };

        final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
        final scaleFactor = layout.width / baseLayout.width;
        final normalizedChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(currentTextScale / scaleFactor),
          ),
          child: child,
        );

        return SizedBox(
          width: layout.width,
          height: layout.height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: baseLayout.width,
              height: baseLayout.height,
              child: normalizedChild,
            ),
          ),
        );
      },
    );
  }
}

Widget buildCardImage(
  MediaCard widget,
  ThemeData theme, {
  required double width,
  required double height,
  double? radius,
  BoxFit fit = BoxFit.cover,
}) {
  final cs = theme.colorScheme;
  final r = radius ?? GlobalUI.uiRoundness;

  return Hero(
    tag: widget.tag,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(r),
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
        borderRadius: BorderRadius.circular(10),
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
  final bool isActive;
  final ComponentLayout layout;

  const _ClassicCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final imageHeight = layout.height * 0.76;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.tertiary : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              buildCardImage(
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
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
  final bool isActive;
  final ComponentLayout layout;

  const _MinimalCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildCardImage(
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
  final bool isActive;
  final ComponentLayout layout;

  const _ExpressiveCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final imageHeight = layout.height * 0.7;

    return SizedBox(
      width: layout.width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: layout.width,
        height: layout.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
          border: Border.all(
            color: isActive
                ? cs.tertiary
                : cs.outlineVariant.withValues(alpha: 0.28),
            width: isActive ? 2.5 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                buildCardImage(
                  widget,
                  theme,
                  width: double.maxFinite,
                  height: imageHeight,
                  radius: GlobalUI.uiRoundness * 0.8,
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
  final bool isActive;
  final ComponentLayout layout;

  const _MaterialCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final imageHeight = layout.height * 0.7;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 1.0,
        ),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(GlobalUI.uiRoundness),
                ),
                child: buildCardImage(
                  widget,
                  theme,
                  width: layout.width,
                  height: imageHeight,
                  radius: 0,
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
  final bool isActive;
  final ComponentLayout layout;

  const _LiquidGlassCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.20),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildCardImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),

            // Bottom cinematic fade
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.65, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),

            // Format badge
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.format != null)
                    LiquidGlass(
                      radius: GlobalUI.uiRoundness * 0.4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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

            // Title liquid panel
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: LiquidGlass(
                radius: GlobalUI.uiRoundness * 0.6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
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

            // Active state border
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.transparent,
                      width: isActive ? 1.8 : 0,
                    ),
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

class _CinematicCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _CinematicCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 0.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 0.6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildCardImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),
            // Cinematic gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.45, 0.8, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content overlaid on the left
            Positioned(
              left: 14,
              top: 12,
              bottom: 12,
              width: layout.width * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.format != null || widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(widget.format ?? widget.badge ?? '')}'
                            .toUpperCase(),
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            // Active border
            if (isActive)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      GlobalUI.uiRoundness * 0.6,
                    ),
                    border: Border.all(color: cs.tertiary, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrostedCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _FrostedCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary.withValues(alpha: 0.85)
              : (theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : cs.outlineVariant.withValues(alpha: 0.2)),
          width: isActive ? 1.8 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: cs.tertiary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full image background
            buildCardImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),
            // Format badge
            _TopOverlay(format: widget.format, badge: widget.badge),
            // Frosted bottom panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.surface.withValues(alpha: 0.25),
                          cs.surface.withValues(alpha: 0.75),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.25,
                      ),
                    ),
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

class _NeonCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _NeonCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final primaryGlow = cs.primary;
    final secondaryGlow = cs.tertiary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: (isActive ? primaryGlow : secondaryGlow).withValues(
            alpha: isActive ? 0.95 : 0.45,
          ),
          width: isActive ? 2.5 : 1.5,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? primaryGlow : secondaryGlow).withValues(
              alpha: isActive ? 0.55 : 0.18,
            ),
            blurRadius: isActive ? 20 : 8,
            spreadRadius: isActive ? 2.5 : 0,
          ),
          if (isActive)
            BoxShadow(
              color: secondaryGlow.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildCardImage(
              widget,
              theme,
              width: layout.width,
              height: layout.height,
              radius: 0,
            ),
            // Cinematic bottom fade
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 0.75, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
            _TopOverlay(format: widget.format, badge: widget.badge),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 2,
                    color: isActive ? primaryGlow : secondaryGlow,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.25,
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
}

class _CompactCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _CompactCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final r = GlobalUI.uiRoundness;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: isActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(r * 0.7),
            child: SizedBox(
              width: layout.height - 12,
              height: layout.height - 12,
              child: buildCardImage(
                widget,
                theme,
                width: layout.height - 12,
                height: layout.height - 12,
                radius: 0,
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
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                if (widget.format != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.format!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _EditorialCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final imageHeight = layout.height * 0.65;
    final r = GlobalUI.uiRoundness;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.25),
          width: isActive ? 2.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
            child: Stack(
              children: [
                buildCardImage(
                  widget,
                  theme,
                  width: layout.width,
                  height: imageHeight,
                  radius: 0,
                ),
                _TopOverlay(format: widget.format, badge: widget.badge),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.2,
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

class _WideBannerCard extends StatelessWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;

  const _WideBannerCard({
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final r = GlobalUI.uiRoundness;

    return AnimatedContainer(
      duration: Durations.short4,
      width: layout.width,
      height: layout.height,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 0.0,
        ),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildCardImage(
                      widget,
                      theme,
                      width: double.infinity,
                      height: double.infinity,
                      radius: 0,
                    ),
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
                    if (widget.format != null || widget.badge != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${(widget.format ?? widget.badge ?? '')}'
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (widget.format != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.format!.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
