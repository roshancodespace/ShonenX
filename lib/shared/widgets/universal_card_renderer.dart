import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class UniversalCardRenderer extends StatelessWidget {
  final String styleName;
  final double width;
  final double height;
  final bool isActive;
  final bool isLoading;
  final String title;
  final String? subtitle;
  final double? progress;
  final String? progressText;
  final String? badgeText;
  final Widget? topRightBadge;
  final String? bottomLeftBadgeText;
  final String? imageUrl;
  final Widget Function(BuildContext context, ColorScheme cs)? thumbnailBuilder;
  final String? heroTag;
  final IconData fallbackIcon;

  const UniversalCardRenderer({
    super.key,
    required this.styleName,
    required this.width,
    required this.height,
    required this.isActive,
    this.isLoading = false,
    required this.title,
    this.subtitle,
    this.progress,
    this.progressText,
    this.badgeText,
    this.topRightBadge,
    this.bottomLeftBadgeText,
    this.imageUrl,
    this.thumbnailBuilder,
    this.heroTag,
    this.fallbackIcon = Icons.image_not_supported_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (styleName) {
      'minimal' => _buildMinimal(theme),
      'expressive' => _buildExpressive(theme),
      'material' => _buildMaterial(theme),
      'cinematic' => _buildCinematic(theme),
      'neon' => _buildNeon(theme),
      'compact' => _buildCompact(theme),
      'editorial' => _buildEditorial(theme),
      'wideBanner' => _buildWideBanner(theme),
      _ => _buildClassic(theme),
    };
  }

  Widget _buildImage(
    ThemeData theme, {
    required double w,
    required double h,
    double? r,
  }) {
    final cs = theme.colorScheme;
    final radius = r ?? GlobalUI.uiRoundness;

    if (thumbnailBuilder != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: w,
          height: h,
          child: Builder(builder: (context) => thumbnailBuilder!(context, cs)),
        ),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      Widget img = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholderFadeInDuration: const Duration(milliseconds: 120),
        errorWidget: (_, __, ___) => _buildFallback(cs, w, h),
      );
      if (heroTag != null && heroTag!.isNotEmpty) {
        img = Hero(tag: heroTag!, child: img);
      }
      return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: _buildFallback(cs, w, h),
    );
  }

  Widget _buildFallback(ColorScheme cs, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: cs.onSurfaceVariant, size: 28),
    );
  }

  Widget _buildBadgeOverlay(ThemeData theme) {
    if (badgeText == null && topRightBadge == null) {
      return const SizedBox.shrink();
    }
    final cs = theme.colorScheme;
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  fontSize: 10,
                ),
              ),
            ),
          const Spacer(),
          if (topRightBadge != null) topRightBadge!,
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    ColorScheme cs, {
    double height = 4,
    BorderRadius? radius,
  }) {
    if (progress == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress!.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: cs.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
      ),
    );
  }

  // 1. CLASSIC
  Widget _buildClassic(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * (progress != null ? 0.65 : 0.74);

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.tertiary : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildImage(theme, w: width, h: imgH),
              _buildBadgeOverlay(theme),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildProgressBar(cs),
            ),
          ],
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: progress != null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null || progressText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (progressText != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          progressText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. MINIMAL
  Widget _buildMinimal(ThemeData theme) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(theme, w: width, h: height, r: 0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    cs.scrim.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            _buildBadgeOverlay(theme),
            Positioned(
              left: 10,
              right: 10,
              bottom: progress != null ? 14 : 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null || progressText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (subtitle != null)
                          Expanded(
                            child: Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        if (progressText != null)
                          Text(
                            progressText!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (progress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildProgressBar(
                  cs,
                  height: 3.5,
                  radius: BorderRadius.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 3. EXPRESSIVE
  Widget _buildExpressive(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * 0.64;

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: width,
        height: height,
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
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(
                  theme,
                  w: double.maxFinite,
                  h: imgH,
                  r: GlobalUI.uiRoundness * 0.8,
                ),
                _buildBadgeOverlay(theme),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                maxLines: progress != null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (subtitle != null || progress != null) ...[
              const Spacer(),
              if (progress != null) ...[
                _buildProgressBar(cs),
                const SizedBox(height: 4),
              ],
              if (subtitle != null || progressText != null)
                Row(
                  children: [
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (progressText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          progressText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. MATERIAL
  Widget _buildMaterial(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * (progress != null ? 0.65 : 0.72);

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.tertiary : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildImage(theme, w: width, h: imgH, r: GlobalUI.uiRoundness),
              _buildBadgeOverlay(theme),
            ],
          ),
          if (progress != null)
            _buildProgressBar(cs, height: 3, radius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: progress != null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null || progressText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (progressText != null)
                        Text(
                          progressText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. CINEMATIC
  Widget _buildCinematic(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbWidth = width * 0.42;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Row(
          children: [
            Stack(
              children: [
                _buildImage(theme, w: thumbWidth, h: height, r: 0),
                if (badgeText != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText!.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (topRightBadge != null) topRightBadge!,
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (progress != null) ...[
                      _buildProgressBar(cs),
                      const SizedBox(height: 4),
                    ],
                    if (progressText != null || bottomLeftBadgeText != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (bottomLeftBadgeText != null)
                            Text(
                              bottomLeftBadgeText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (progressText != null)
                            Text(
                              progressText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
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
      ),
    );
  }

  // 6. NEON
  Widget _buildNeon(ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final imgH = height * 0.64;

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0E14) : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
          border: Border.all(
            color: isActive ? cs.primary : cs.primary.withValues(alpha: 0.65),
            width: isActive ? 2.5 : 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: isActive ? 0.48 : 0.22),
              blurRadius: isActive ? 20 : 10,
              spreadRadius: isActive ? 1 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(
                  theme,
                  w: double.maxFinite,
                  h: imgH,
                  r: GlobalUI.uiRoundness * 0.8,
                ),
                _buildBadgeOverlay(theme),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                maxLines: progress != null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : cs.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            if (subtitle != null || progress != null) ...[
              const Spacer(),
              if (progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 4.0,
                      backgroundColor: cs.primary.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (subtitle != null || progressText != null)
                Row(
                  children: [
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (progressText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Text(
                          progressText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // 7. COMPACT
  Widget _buildCompact(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = height * 1.4;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.0 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _buildImage(
            theme,
            w: thumbW,
            h: height,
            r: GlobalUI.uiRoundness * 0.7,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (topRightBadge != null) topRightBadge!,
                  ],
                ),
                if (subtitle != null || badgeText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? badgeText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildProgressBar(cs, height: 3)),
                      if (progressText != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          progressText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. EDITORIAL
  Widget _buildEditorial(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * (progress != null ? 0.68 : 0.76);

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(
          color: isActive ? cs.tertiary : Colors.transparent,
          width: isActive ? 2.5 : 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildImage(theme, w: width, h: imgH, r: GlobalUI.uiRoundness),
              _buildBadgeOverlay(theme),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bottomLeftBadgeText != null || badgeText != null)
                  Text(
                    (bottomLeftBadgeText ?? badgeText!).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                Text(
                  title,
                  maxLines: progress != null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  _buildProgressBar(cs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. WIDE BANNER
  Widget _buildWideBanner(ThemeData theme) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: width,
      height: height,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(theme, w: width, h: height, r: 0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.1, 0.65, 1.0],
                  colors: [
                    cs.surface.withValues(alpha: 0.95),
                    cs.surface.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        if (progress != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildProgressBar(cs)),
                              if (progressText != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  progressText!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  if (topRightBadge != null)
                    Align(alignment: Alignment.topRight, child: topRightBadge!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
