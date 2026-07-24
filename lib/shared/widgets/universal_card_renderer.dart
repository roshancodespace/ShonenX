import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';

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
  final bool isWideMode;
  final double? score;
  final String? year;
  final String? status;
  final List<String>? genres;

  const UniversalCardRenderer({
    super.key,
    required this.styleName,
    required this.width,
    required this.height,
    required this.isActive,
    this.isLoading = false,
    this.isWideMode = false,
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
    this.score,
    this.year,
    this.status,
    this.genres,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget card;
    if (isWideMode &&
        styleName != 'compact' &&
        styleName != 'cinematic' &&
        styleName != 'wideBanner') {
      card = _buildWideModeCard(theme);
    } else {
      card = switch (styleName) {
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
    return RepaintBoundary(child: card);
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
        httpHeaders: decodeUrlHeaders(imageUrl!),
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

  Widget _buildThumbnailWithProgressBorder(
    ThemeData theme, {
    required double w,
    required double h,
    double? r,
  }) {
    final cs = theme.colorScheme;
    final radius = r ?? GlobalUI.uiRoundness;
    if (progress == null) {
      return _buildImage(theme, w: w, h: h, r: radius);
    }
    final strokeW = isActive ? 3.5 : 2.8;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(strokeW * 0.5),
          child: _buildImage(
            theme,
            w: w == double.maxFinite ? w : w - strokeW,
            h: h - strokeW,
            r: radius - (strokeW * 0.5),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ThumbnailProgressBorderPainter(
              progress: progress!.clamp(0.0, 1.0),
              color: cs.primary,
              trackColor: cs.primary.withValues(alpha: 0.22),
              strokeWidth: strokeW,
              radius: radius,
            ),
          ),
        ),
      ],
    );
  }

  String? get _effectiveSubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle;
    final items = <String>[];
    if (year != null && year!.isNotEmpty) items.add(year!);
    if (status != null && status!.isNotEmpty) items.add(status!);
    if (genres != null && genres!.isNotEmpty) items.add(genres!.first);
    if (items.isEmpty) return null;
    return items.join(' • ');
  }

  Widget _buildBadgeOverlay(ThemeData theme) {
    final hasScore = score != null && score! > 0 && !isWideMode;
    final showBadgeText = badgeText != null;
    if (!showBadgeText && topRightBadge == null && !hasScore) {
      return const SizedBox.shrink();
    }
    final cs = theme.colorScheme;
    final formattedScore = score != null
        ? (score! > 10
              ? (score! / 10).toStringAsFixed(1)
              : score!.toStringAsFixed(1))
        : null;

    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBadgeText)
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
          if (topRightBadge != null)
            topRightBadge!
          else if (hasScore && formattedScore != null)
            _buildStyleRatingBadge(theme, formattedScore),
        ],
      ),
    );
  }

  Widget _buildStyleRatingBadge(ThemeData theme, String formattedScore) {
    final cs = theme.colorScheme;

    switch (styleName) {
      case 'expressive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 12, color: cs.onPrimaryContainer),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );

      case 'material':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 12, color: cs.primary),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );

      case 'minimal':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );

      case 'neon':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cs.primary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 12, color: cs.primary),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );

      case 'editorial':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Text(
            '$formattedScore ★',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
        );

      case 'cinematic':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFB703).withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );

      case 'classic':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFFB703).withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 11,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 3),
              Text(
                formattedScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPortraitMetadataRow(ThemeData theme) {
    final cs = theme.colorScheme;
    final hasYear = year != null && year!.isNotEmpty;
    final hasGenres = genres != null && genres!.isNotEmpty;
    final hasStatus = status != null && status!.isNotEmpty;

    if (subtitle != null && subtitle!.isNotEmpty) {
      return Text(
        subtitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    if (!hasYear && !hasGenres && !hasStatus) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasYear) ...[
          Text(
            year!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          if (hasStatus || hasGenres)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '•',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ),
        ],
        if (hasStatus && !hasGenres) ...[
          Expanded(
            child: Text(
              status!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
        if (hasGenres) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              genres!.first,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
              ),
            ),
          ),
          if (genres!.length > 1) ...[
            const SizedBox(width: 3),
            Text(
              '+${genres!.length - 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildWideMetadataColumn(ThemeData theme) {
    final cs = theme.colorScheme;
    final metaItems = <String>[];
    if (year != null && year!.isNotEmpty) metaItems.add(year!);
    if (status != null && status!.isNotEmpty) metaItems.add(status!);
    if (subtitle != null && subtitle!.isNotEmpty) metaItems.add(subtitle!);
    final metaText = metaItems.join(' • ');

    final formattedScore = (score != null && score! > 0)
        ? (score! > 10
              ? (score! / 10).toStringAsFixed(1)
              : score!.toStringAsFixed(1))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: MarqueeText(
                text: title,
                style:
                    theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.2,
                    ) ??
                    const TextStyle(),
              ),
            ),
            if (topRightBadge != null) topRightBadge!,
          ],
        ),
        if (formattedScore != null || metaText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (formattedScore != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFFB703).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Color(0xFFFFB703),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formattedScore,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (metaText.isNotEmpty) const SizedBox(width: 6),
              ],
              if (metaText.isNotEmpty)
                Expanded(
                  child: Text(
                    metaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (genres != null && genres!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: genres!.take(2).map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  g,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (progress != null || progressText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (progress != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ),
              if (progressText != null) ...[
                const SizedBox(width: 6),
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
    );
  }

  Widget _buildWideModeCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbW = width * 0.48;

    switch (styleName) {
      case 'classic':
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
          child: Row(
            children: [
              Stack(
                children: [
                  _buildThumbnailWithProgressBorder(
                    theme,
                    w: thumbW,
                    h: height,
                  ),
                  _buildBadgeOverlay(theme),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: _buildWideMetadataColumn(theme),
                ),
              ),
            ],
          ),
        );

      case 'minimal':
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
                _buildThumbnailWithProgressBorder(
                  theme,
                  w: width,
                  h: height,
                  r: GlobalUI.uiRoundness,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.1, 0.7, 1.0],
                      colors: [
                        cs.scrim.withValues(alpha: 0.9),
                        cs.scrim.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                _buildBadgeOverlay(theme),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (topRightBadge != null) topRightBadge!,
                        ],
                      ),
                      if (subtitle != null ||
                          progress != null ||
                          progressText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (progressText != null || progress != null)
                              Text(
                                progressText ??
                                    '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
              ],
            ),
          ),
        );

      case 'expressive':
        return AnimatedContainer(
          duration: Durations.short4,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.5),
            border: Border.all(
              color: isActive ? cs.primary : Colors.transparent,
              width: isActive ? 2.5 : 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildThumbnailWithProgressBorder(
                    theme,
                    w: thumbW,
                    h: height,
                    r: GlobalUI.uiRoundness * 1.2,
                  ),
                  _buildBadgeOverlay(theme),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      if (subtitle != null ||
                          progress != null ||
                          progressText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (progressText != null || progress != null)
                              Text(
                                progressText ??
                                    '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'material':
        return AnimatedContainer(
          duration: Durations.short4,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.3),
            border: Border.all(
              color: isActive
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: isActive ? 2.0 : 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildThumbnailWithProgressBorder(
                    theme,
                    w: thumbW,
                    h: height,
                    r: GlobalUI.uiRoundness,
                  ),
                  _buildBadgeOverlay(theme),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (topRightBadge != null) topRightBadge!,
                        ],
                      ),
                      if (subtitle != null ||
                          progress != null ||
                          progressText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (progressText != null || progress != null)
                              Text(
                                progressText ??
                                    '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'neon':
        final isDark = theme.brightness == Brightness.dark;
        return AnimatedContainer(
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
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildThumbnailWithProgressBorder(
                    theme,
                    w: thumbW,
                    h: height,
                    r: GlobalUI.uiRoundness * 0.8,
                  ),
                  _buildBadgeOverlay(theme),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : cs.onSurface,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (topRightBadge != null) topRightBadge!,
                        ],
                      ),
                      if (subtitle != null ||
                          progress != null ||
                          progressText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (progressText != null || progress != null)
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
                                  progressText ??
                                      '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
              ),
            ],
          ),
        );

      case 'editorial':
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
          child: Row(
            children: [
              Stack(
                children: [
                  _buildThumbnailWithProgressBorder(
                    theme,
                    w: thumbW,
                    h: height,
                    r: GlobalUI.uiRoundness,
                  ),
                  _buildBadgeOverlay(theme),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (bottomLeftBadgeText != null ||
                                    badgeText != null)
                                  Text(
                                    (bottomLeftBadgeText ?? badgeText!)
                                        .toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                    ),
                                  ),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onSurface,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (topRightBadge != null) topRightBadge!,
                        ],
                      ),
                      if (subtitle != null ||
                          progress != null ||
                          progressText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (progressText != null || progress != null)
                              Text(
                                progressText ??
                                    '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'compact':
        return _buildCompact(theme);
      case 'cinematic':
        return _buildCinematic(theme);
      case 'wideBanner':
      default:
        return _buildWideBanner(theme);
    }
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
              _buildThumbnailWithProgressBorder(theme, w: width, h: imgH),
              _buildBadgeOverlay(theme),
            ],
          ),
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
                if (_effectiveSubtitle != null ||
                    progress != null ||
                    progressText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_effectiveSubtitle != null)
                        Expanded(child: _buildPortraitMetadataRow(theme)),
                      if (progressText != null || progress != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          progressText ??
                              '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
            _buildThumbnailWithProgressBorder(
              theme,
              w: width,
              h: height,
              r: GlobalUI.uiRoundness,
            ),
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
              bottom: 10,
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
                  if (_effectiveSubtitle != null ||
                      progress != null ||
                      progressText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_effectiveSubtitle != null)
                          Expanded(child: _buildPortraitMetadataRow(theme)),
                        if (progressText != null || progress != null)
                          Text(
                            progressText ??
                                '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
                _buildThumbnailWithProgressBorder(
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
            if (_effectiveSubtitle != null ||
                progress != null ||
                progressText != null) ...[
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_effectiveSubtitle != null)
                    Expanded(child: _buildPortraitMetadataRow(theme)),
                  if (progressText != null || progress != null)
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
                        progressText ??
                            '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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

  // 4. MATERIAL (Material You / M3 Expressive)
  Widget _buildMaterial(ThemeData theme) {
    final cs = theme.colorScheme;
    final imgH = height * 0.62;

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isActive ? cs.surfaceContainerHighest : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness + 2),
          border: Border.all(
            color: isActive
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.35),
            width: isActive ? 2.5 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildThumbnailWithProgressBorder(
                  theme,
                  w: double.maxFinite,
                  h: imgH,
                  r: GlobalUI.uiRoundness - 2,
                ),
                _buildBadgeOverlay(theme),
              ],
            ),
            const SizedBox(height: 10),
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
            if (_effectiveSubtitle != null ||
                progress != null ||
                progressText != null) ...[
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_effectiveSubtitle != null)
                    Expanded(child: _buildPortraitMetadataRow(theme)),
                  if (progressText != null || progress != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        progressText ??
                            '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
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

  // 5. CINEMATIC
  Widget _buildCinematic(ThemeData theme) {
    final cs = theme.colorScheme;
    final thumbWidth = width * 0.44;

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
                _buildThumbnailWithProgressBorder(
                  theme,
                  w: thumbWidth,
                  h: height,
                  r: GlobalUI.uiRoundness * 0.6,
                ),
                _buildBadgeOverlay(theme),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _buildWideMetadataColumn(theme),
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
                _buildThumbnailWithProgressBorder(
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
            if (_effectiveSubtitle != null ||
                progress != null ||
                progressText != null) ...[
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_effectiveSubtitle != null)
                    Expanded(child: _buildPortraitMetadataRow(theme)),
                  if (progressText != null || progress != null)
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
                        progressText ??
                            '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
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
          Stack(
            children: [
              _buildThumbnailWithProgressBorder(
                theme,
                w: thumbW,
                h: height,
                r: GlobalUI.uiRoundness * 0.7,
              ),
              _buildBadgeOverlay(theme),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildWideMetadataColumn(theme)),
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
              _buildThumbnailWithProgressBorder(
                theme,
                w: width,
                h: imgH,
                r: GlobalUI.uiRoundness,
              ),
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
                if (_effectiveSubtitle != null ||
                    progress != null ||
                    progressText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_effectiveSubtitle != null)
                        Expanded(child: _buildPortraitMetadataRow(theme)),
                      if (progressText != null || progress != null)
                        Text(
                          progressText ??
                              '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
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
            _buildThumbnailWithProgressBorder(
              theme,
              w: width,
              h: height,
              r: GlobalUI.uiRoundness,
            ),
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
            _buildBadgeOverlay(theme),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildWideMetadataColumn(theme)),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double radius;

  _ThumbnailProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final halfWidth = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfWidth,
        halfWidth,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular((radius - halfWidth).clamp(0.0, 999.0)),
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, trackPaint);

    if (progress > 0.0) {
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        final extractLength = metric.length * progress.clamp(0.0, 1.0);
        final subPath = metric.extractPath(0.0, extractLength);

        final progressPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(subPath, progressPaint);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_ThumbnailProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
