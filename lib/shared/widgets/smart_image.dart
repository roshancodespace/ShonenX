import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/core/network/session_manager.dart';
import 'package:shonenx/core/network/network_config.dart';

class SmartImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int maxWidthDiskCache;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
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
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Duration? placeholderFadeInDuration;
  final Map<String, String>? httpHeaders;
  final FilterQuality filterQuality;
  final Widget Function(BuildContext, ImageProvider)? imageBuilder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
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
    this.fadeInDuration = const Duration(milliseconds: 220),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.placeholderFadeInDuration = const Duration(milliseconds: 120),
    this.httpHeaders,
    this.filterQuality = FilterQuality.low,
    this.imageBuilder,
    this.progressIndicatorBuilder,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeWidth = width != null && width!.isFinite && width! > 0
        ? width
        : null;
    final safeHeight = height != null && height!.isFinite && height! > 0
        ? height
        : null;

    final fallback = errorWidget != null
        ? errorWidget!(
            context,
            imageUrl ?? '',
            Exception('SmartImage fallback'),
          )
        : Container(
            width: safeWidth,
            height: safeHeight,
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_rounded,
              color: cs.onSurfaceVariant,
              size: 28,
            ),
          );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _applyEffects(fallback);
    }

    final raw = imageUrl!.trim();

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final cleanUrl = raw.split('#').first;
      final encodedHeaders = decodeUrlHeaders(raw);

      // Fetch global cookies and user-agent dynamically
      final sessionManager = SessionManager();
      final cookies = sessionManager.getCookiesSync(cleanUrl);
      final userAgent =
          sessionManager.getUserAgentSync(cleanUrl) ??
          NetworkConfig.globalUserAgent;

      final finalHeaders = {
        'User-Agent': userAgent,
        if (cookies.isNotEmpty) 'Cookie': cookies,
        ...NetworkConfig.globalHeaders,
        ...?httpHeaders,
        ...encodedHeaders,
      };

      return _applyEffects(
        CachedNetworkImage(
          imageUrl: cleanUrl,
          httpHeaders: finalHeaders.isEmpty ? null : finalHeaders,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          alignment: alignment,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          maxWidthDiskCache: maxWidthDiskCache,
          fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 220),
          fadeOutDuration: fadeOutDuration,
          placeholderFadeInDuration: placeholderFadeInDuration,
          filterQuality: filterQuality,
          imageBuilder: imageBuilder,
          progressIndicatorBuilder: progressIndicatorBuilder,
          color: color,
          colorBlendMode: colorBlendMode,
          placeholder:
              placeholder ??
              (_, __) => Container(
                width: safeWidth,
                height: safeHeight,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
          errorWidget: errorWidget ?? (_, __, ___) => fallback,
        ),
      );
    }

    try {
      final base64String = raw.contains(',') ? raw.split(',').last.trim() : raw;
      final bytes = base64Decode(base64String);

      final img = Image.memory(
        bytes,
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        filterQuality: filterQuality,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (_, __, ___) => fallback,
      );

      if (imageBuilder != null) {
        return _applyEffects(imageBuilder!(context, img.image));
      }

      return _applyEffects(img);
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
