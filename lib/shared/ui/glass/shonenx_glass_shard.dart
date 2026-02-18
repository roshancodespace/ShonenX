import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shonenx/shared/ui/glass/shonenx_glass_painter.dart';

class ShonenXGlassShard extends StatelessWidget {
  final Widget child;

  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;
  final Offset offset;

  final ImageProvider imageProvider;
  final bool isDark;
  final bool isHovered;

  final double hoverScale;
  final double restScale;
  final Duration animationDuration;
  final double blurSigma;

  const ShonenXGlassShard({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.imageProvider,
    required this.isDark,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.isHovered = false,
    this.hoverScale = 1.1,
    this.restScale = 1.0,
    this.animationDuration = const Duration(milliseconds: 1400),
    this.blurSigma = 0.0,
  });

  factory ShonenXGlassShard.network({
    Key? key,
    required Widget child,
    required double width,
    required double height,
    required String imageUrl,
    required bool isDark,
    Alignment alignment = Alignment.center,
    Offset offset = Offset.zero,
    double borderRadius = 12,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    bool isHovered = false,
    double hoverScale = 1.1,
    double restScale = 1.0,
    Duration animationDuration = const Duration(milliseconds: 1400),
    double blurSigma = 0.0,
  }) {
    return ShonenXGlassShard(
      key: key,
      width: width,
      height: height,
      imageProvider: CachedNetworkImageProvider(imageUrl),
      isDark: isDark,
      alignment: alignment,
      offset: offset,
      borderRadius: borderRadius,
      padding: padding,
      isHovered: isHovered,
      hoverScale: hoverScale,
      restScale: restScale,
      animationDuration: animationDuration,
      blurSigma: blurSigma,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShonenXGlassRimPainter(radius: borderRadius, isDark: isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: OverflowBox(
                maxWidth: width,
                maxHeight: height,
                alignment: alignment,
                child: Transform.translate(
                  offset: offset,
                  child: RepaintBoundary(
                    child: AnimatedScale(
                      scale: isHovered ? hoverScale : restScale,
                      duration: animationDuration,
                      curve: Curves.easeOutExpo,
                      child: blurSigma > 0
                          ? ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: blurSigma,
                                sigmaY: blurSigma,
                              ),
                              child: Image(
                                image: imageProvider,
                                width: width,
                                height: height,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            )
                          : Image(
                              image: imageProvider,
                              width: width,
                              height: height,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            if (isDark)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withOpacity(0.6)),
              )
            else
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withOpacity(0.4)),
              ),

            Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
