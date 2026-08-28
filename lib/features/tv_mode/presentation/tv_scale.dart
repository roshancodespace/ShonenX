import 'package:flutter/material.dart';

extension TvScaleExtension on BuildContext {
  double get tvScale {
    final size = MediaQuery.sizeOf(this);
    final scaleW = size.width / 1920.0;
    final scaleH = size.height / 1080.0;
    final scale = (scaleW < scaleH ? scaleW : scaleH).clamp(0.85, 2.0);
    return scale;
  }

  double scale(double value) => value * tvScale;

  EdgeInsets get tvPadding {
    final w = MediaQuery.sizeOf(this).width;
    final horizontal = (w * 0.025).clamp(32.0, 64.0);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}
