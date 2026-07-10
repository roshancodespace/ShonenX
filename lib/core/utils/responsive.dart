// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum WidthTier { compact, medium, expanded, large, ultraLarge }

enum HeightTier { spacious, normal, compact, tight, cramped }

extension WidthTierX on WidthTier {
  bool get isAtMost_compact => index <= WidthTier.compact.index;
  bool get isAtMost_medium => index <= WidthTier.medium.index;
  bool get isAtMost_expanded => index <= WidthTier.expanded.index;
  bool get isAtLeast_medium => index >= WidthTier.medium.index;
  bool get isAtLeast_expanded => index >= WidthTier.expanded.index;
  bool get isAtLeast_large => index >= WidthTier.large.index;

  T pick<T>({
    required T compact,
    required T medium,
    required T expanded,
    required T large,
    required T ultraLarge,
  }) => switch (this) {
    WidthTier.compact => compact,
    WidthTier.medium => medium,
    WidthTier.expanded => expanded,
    WidthTier.large => large,
    WidthTier.ultraLarge => ultraLarge,
  };

  T pickOrFold<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
    T? ultraLarge,
  }) {
    if (this == WidthTier.ultraLarge && ultraLarge != null) return ultraLarge;
    if (index >= WidthTier.large.index && large != null) return large;
    if (index >= WidthTier.expanded.index && expanded != null) return expanded;
    if (index >= WidthTier.medium.index && medium != null) return medium;
    return compact;
  }
}

extension HeightTierX on HeightTier {
  bool get isAtLeast_normal => index <= HeightTier.normal.index;
  bool get isAtLeast_compact => index <= HeightTier.compact.index;
  bool get isBelowNormal => index > HeightTier.normal.index;
  bool get isBelowCompact => index > HeightTier.compact.index;
  bool get isBelowTight => index > HeightTier.tight.index;

  T pick<T>({
    required T spacious,
    required T normal,
    required T compact,
    required T tight,
    required T cramped,
  }) => switch (this) {
    HeightTier.spacious => spacious,
    HeightTier.normal => normal,
    HeightTier.compact => compact,
    HeightTier.tight => tight,
    HeightTier.cramped => cramped,
  };

  T pickOrFold<T>({
    required T spacious,
    T? normal,
    T? compact,
    T? tight,
    T? cramped,
  }) {
    if (this == HeightTier.cramped && cramped != null) return cramped;
    if (index >= HeightTier.tight.index && tight != null) return tight;
    if (index >= HeightTier.compact.index && compact != null) return compact;
    if (index >= HeightTier.normal.index && normal != null) return normal;
    return spacious;
  }
}

class ResponsiveBreakpoints {
  final double widthMedium;
  final double widthExpanded;
  final double widthLarge;
  final double widthUltraLarge;

  final double heightSpacious;
  final double heightNormal;
  final double heightCompact;
  final double heightTight;

  const ResponsiveBreakpoints({
    this.widthMedium = 600,
    this.widthExpanded = 840,
    this.widthLarge = 1200,
    this.widthUltraLarge = 1600,
    this.heightSpacious = 900,
    this.heightNormal = 750,
    this.heightCompact = 600,
    this.heightTight = 400,
  });

  static const ResponsiveBreakpoints defaults = ResponsiveBreakpoints();

  WidthTier resolveWidth(double width) {
    if (width >= widthUltraLarge) return WidthTier.ultraLarge;
    if (width >= widthLarge) return WidthTier.large;
    if (width >= widthExpanded) return WidthTier.expanded;
    if (width >= widthMedium) return WidthTier.medium;
    return WidthTier.compact;
  }

  HeightTier resolveHeight(double height) {
    if (height >= heightSpacious) return HeightTier.spacious;
    if (height >= heightNormal) return HeightTier.normal;
    if (height >= heightCompact) return HeightTier.compact;
    if (height >= heightTight) return HeightTier.tight;
    return HeightTier.cramped;
  }

  ResponsiveBreakpoints copyWith({
    double? widthMedium,
    double? widthExpanded,
    double? widthLarge,
    double? widthUltraLarge,
    double? heightSpacious,
    double? heightNormal,
    double? heightCompact,
    double? heightTight,
  }) {
    return ResponsiveBreakpoints(
      widthMedium: widthMedium ?? this.widthMedium,
      widthExpanded: widthExpanded ?? this.widthExpanded,
      widthLarge: widthLarge ?? this.widthLarge,
      widthUltraLarge: widthUltraLarge ?? this.widthUltraLarge,
      heightSpacious: heightSpacious ?? this.heightSpacious,
      heightNormal: heightNormal ?? this.heightNormal,
      heightCompact: heightCompact ?? this.heightCompact,
      heightTight: heightTight ?? this.heightTight,
    );
  }
}

class ResponsiveData {
  final double width;
  final double height;
  final double devicePixelRatio;
  final double textScaleFactor;
  final Orientation orientation;
  final TargetPlatform platform;
  final bool isPhysicalKeyboardConnected;
  final WidthTier widthTier;
  final HeightTier heightTier;
  final ResponsiveBreakpoints breakpoints;

  const ResponsiveData._({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.textScaleFactor,
    required this.orientation,
    required this.platform,
    required this.isPhysicalKeyboardConnected,
    required this.widthTier,
    required this.heightTier,
    required this.breakpoints,
  });

  factory ResponsiveData.from(
    BuildContext context, {
    ResponsiveBreakpoints breakpoints = ResponsiveBreakpoints.defaults,
  }) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final platform = Theme.of(context).platform;

    return ResponsiveData._(
      width: size.width,
      height: size.height,
      devicePixelRatio: mq.devicePixelRatio,
      textScaleFactor: mq.textScaler.scale(1.0),
      orientation: mq.orientation,
      platform: platform,
      isPhysicalKeyboardConnected: _hasPhysicalKeyboard(platform, mq),
      widthTier: breakpoints.resolveWidth(size.width),
      heightTier: breakpoints.resolveHeight(size.height),
      breakpoints: breakpoints,
    );
  }

  static bool _hasPhysicalKeyboard(TargetPlatform platform, MediaQueryData mq) {
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      return true;
    }
    return false;
  }

  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  bool get isPhone => widthTier == WidthTier.compact;
  bool get isTablet =>
      widthTier == WidthTier.medium || widthTier == WidthTier.expanded;
  bool get isDesktop =>
      widthTier == WidthTier.large || widthTier == WidthTier.ultraLarge;

  bool get isAndroid => platform == TargetPlatform.android;
  bool get isIOS => platform == TargetPlatform.iOS;
  bool get isMacOS => platform == TargetPlatform.macOS;
  bool get isWindows => platform == TargetPlatform.windows;
  bool get isLinux => platform == TargetPlatform.linux;
  bool get isMobile => isAndroid || isIOS;
  bool get isNativeDesktop => isMacOS || isWindows || isLinux;
  bool get isWeb => kIsWeb;

  bool get isPhoneLandscape => isPhone && isLandscape;
  bool get isTabletPortrait => isTablet && isPortrait;
  bool get isTabletLandscape => isTablet && isLandscape;

  bool get isHeightSpacious => heightTier == HeightTier.spacious;
  bool get isHeightCramped => heightTier == HeightTier.cramped;

  double get shortestSide => width < height ? width : height;
  double get longestSide => width > height ? width : height;
  double get aspectRatio => width / height;

  T pickWidth<T>({
    required T compact,
    required T medium,
    required T expanded,
    required T large,
    required T ultraLarge,
  }) => widthTier.pick(
    compact: compact,
    medium: medium,
    expanded: expanded,
    large: large,
    ultraLarge: ultraLarge,
  );

  T pickHeight<T>({
    required T spacious,
    required T normal,
    required T compact,
    required T tight,
    required T cramped,
  }) => heightTier.pick(
    spacious: spacious,
    normal: normal,
    compact: compact,
    tight: tight,
    cramped: cramped,
  );

  T when<T>({
    T Function()? phoneLandscape,
    T Function()? phonePortrait,
    T Function()? tabletPortrait,
    T Function()? tabletLandscape,
    T Function()? desktop,
    required T Function() orElse,
  }) {
    if (phoneLandscape != null && isPhone && isLandscape) {
      return phoneLandscape();
    }
    if (phonePortrait != null && isPhone && isPortrait) return phonePortrait();
    if (tabletPortrait != null && isTablet && isPortrait) {
      return tabletPortrait();
    }
    if (tabletLandscape != null && isTablet && isLandscape) {
      return tabletLandscape();
    }
    if (desktop != null && isDesktop) return desktop();
    return orElse();
  }
}

class _ResponsiveInherited extends InheritedWidget {
  final ResponsiveData data;

  const _ResponsiveInherited({required this.data, required super.child});

  @override
  bool updateShouldNotify(_ResponsiveInherited old) =>
      data.width != old.data.width ||
      data.height != old.data.height ||
      data.orientation != old.data.orientation ||
      data.platform != old.data.platform ||
      data.textScaleFactor != old.data.textScaleFactor;
}

class ResponsiveHandler extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveData r) builder;
  final ResponsiveBreakpoints breakpoints;

  const ResponsiveHandler({
    super.key,
    required this.builder,
    this.breakpoints = ResponsiveBreakpoints.defaults,
  });

  static ResponsiveData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ResponsiveInherited>();
    assert(
      inherited != null,
      'ResponsiveHandler.of called outside of a ResponsiveHandler subtree.',
    );
    return inherited!.data;
  }

  static ResponsiveData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ResponsiveInherited>()
        ?.data;
  }

  @override
  Widget build(BuildContext context) {
    final data = ResponsiveData.from(context, breakpoints: breakpoints);
    return _ResponsiveInherited(
      data: data,
      child: Builder(builder: (ctx) => builder(ctx, data)),
    );
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveData get responsive => ResponsiveHandler.of(this);
  ResponsiveData? get responsiveOrNull => ResponsiveHandler.maybeOf(this);
}

class SliverGridDelegateWithMinCrossAxisExtent extends SliverGridDelegate {
  const SliverGridDelegateWithMinCrossAxisExtent({
    required this.minCrossAxisExtent,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
  }) : assert(minCrossAxisExtent > 0),
       assert(mainAxisSpacing >= 0),
       assert(crossAxisSpacing >= 0),
       assert(childAspectRatio > 0);

  final double minCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final double? mainAxisExtent;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    int crossAxisCount = ((constraints.crossAxisExtent + crossAxisSpacing) /
            (minCrossAxisExtent + crossAxisSpacing))
        .floor();
    if (crossAxisCount < 1) {
      crossAxisCount = 1;
    }
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent =
        mainAxisExtent ?? childCrossAxisExtent / childAspectRatio;
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithMinCrossAxisExtent oldDelegate) {
    return oldDelegate.minCrossAxisExtent != minCrossAxisExtent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio ||
        oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}

