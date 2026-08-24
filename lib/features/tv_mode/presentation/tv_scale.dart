import 'package:flutter/material.dart';

/// TV-specific responsive scaling helper for 10-foot UI design.
/// Base reference resolution is Full HD (1920 x 1080).
extension TvScaleExtension on BuildContext {
  /// Base scaling factor calculated from viewport dimensions.
  double get tvScale {
    final size = MediaQuery.sizeOf(this);
    final scaleW = size.width / 1920.0;
    final scaleH = size.height / 1080.0;
    // Use the smaller ratio to ensure UI never overflows vertically
    final scale = (scaleW < scaleH ? scaleW : scaleH).clamp(0.85, 2.0);
    return scale;
  }

  /// Scale a specific dimension proportionally according to TV screen size.
  double scale(double value) => value * tvScale;

  /// Clamped responsive padding based on screen width.
  EdgeInsets get tvPadding {
    final w = MediaQuery.sizeOf(this).width;
    final horizontal = (w * 0.025).clamp(32.0, 64.0);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}
