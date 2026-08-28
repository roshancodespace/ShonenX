import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/image_headers.dart';

class TvSmartImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int maxWidthDiskCache;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool fadeFromBottom;
  final bool fadeFromLeft;
  final List<double>? fadeStops;
  final ShaderCallback? shaderCallback;
  final BlendMode blendMode;
  final ImageFilter? imageFilter;
  final ColorFilter? colorFilter;

  const TvSmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache = 800,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.borderRadius,
    this.fadeFromBottom = false,
    this.fadeFromLeft = false,
    this.fadeStops,
    this.shaderCallback,
    this.blendMode = BlendMode.dstIn,
    this.imageFilter,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeWidth = width != null && width!.isFinite ? width : null;
    final safeHeight = height != null && height!.isFinite ? height : null;

    final fallback =
        errorWidget ??
        Container(
          width: safeWidth,
          height: safeHeight,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Center(
            child: Icon(
              Icons.movie_outlined,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              size: 28,
            ),
          ),
        );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _applyEffects(fallback);
    }

    final raw = imageUrl!.trim();

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final cleanUrl = raw.split('#').first;
      final headers = decodeUrlHeaders(raw);

      return _applyEffects(
        CachedNetworkImage(
          imageUrl: cleanUrl,
          httpHeaders: headers.isEmpty ? null : headers,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          maxWidthDiskCache: maxWidthDiskCache,
          fadeInDuration: const Duration(milliseconds: 220),
          placeholderFadeInDuration: const Duration(milliseconds: 120),
          placeholder: (_, __) =>
              placeholder ??
              Container(
                width: safeWidth,
                height: safeHeight,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }

    try {
      final base64String = raw.contains(',') ? raw.split(',').last.trim() : raw;
      final bytes = base64Decode(base64String);

      return _applyEffects(
        Image.memory(
          bytes,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } catch (_) {
      return _applyEffects(fallback);
    }
  }

  Widget _applyEffects(Widget child) {
    Widget result = child;

    if (imageFilter != null) {
      result = ImageFiltered(imageFilter: imageFilter!, child: result);
    }

    if (colorFilter != null) {
      result = ColorFiltered(colorFilter: colorFilter!, child: result);
    }

    if (shaderCallback != null) {
      result = ShaderMask(
        shaderCallback: shaderCallback!,
        blendMode: blendMode,
        child: result,
      );
    }

    if (fadeFromBottom) {
      result = ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: fadeStops ?? const [0.0, 0.15, 0.42, 0.70, 0.85, 1.0],
            colors: const [
              Colors.white,
              Colors.white,
              Color(0x99FFFFFF),
              Color(0x22FFFFFF),
              Colors.transparent,
              Colors.transparent,
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: result,
      );
    }

    if (fadeFromLeft) {
      result = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 0.15, 0.45, 1.0],
            colors: [
              Colors.transparent,
              Color(0x33FFFFFF),
              Color(0xDDFFFFFF),
              Colors.white,
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: result,
      );
    }

    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }

    return result;
  }
}
