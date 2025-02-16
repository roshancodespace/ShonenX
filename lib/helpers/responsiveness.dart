
import 'dart:io';

import 'package:flutter/material.dart';

const int maxMobileWidth = 600;

bool getIsWideScreen(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return size.width > 900; // Adjust breakpoint as needed
}

// Thanks to https://github.com/RyanYuuki/AnymeX
double getResponsiveSize(context,
    {required double mobileSize,
    required double dektopSize,
    bool isStrict = false}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (isStrict) {
    if (Platform.isAndroid || Platform.isIOS) {
      return mobileSize;
    } else {
      return dektopSize;
    }
  } else {
    if (currentWidth > maxMobileWidth) {
      return dektopSize;
    } else {
      return mobileSize;
    }
  }
}

dynamic getResponsiveValue(context,
    {required dynamic mobileValue, required dynamic desktopValue}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (currentWidth > maxMobileWidth) {
    return desktopValue;
  } else {
    return mobileValue;
  }
}

int getResponsiveCrossAxisCount(
  BuildContext context, {
  int baseColumns = 2,
  int maxColumns = 6,
  int mobileBreakpoint = 600,
  int tabletBreakpoint = 1200,
  int mobileItemWidth = 200,
  int tabletItemWidth = 200,
  int desktopItemWidth = 200,
}) {
  final currentWidth = MediaQuery.of(context).size.width;
  const mobileBreakpoint = 600;
  const tabletBreakpoint = 1200;

  int crossAxisCount;
  if (currentWidth < mobileBreakpoint) {
    crossAxisCount = (currentWidth / mobileItemWidth).floor();
  } else if (currentWidth < tabletBreakpoint) {
    crossAxisCount = (currentWidth / tabletItemWidth).floor();
  } else {
    crossAxisCount = (currentWidth / desktopItemWidth).floor();
  }

  return crossAxisCount.clamp(baseColumns, maxColumns);
}