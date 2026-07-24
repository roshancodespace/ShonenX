import 'package:shonenx/shared/models/component_layout.dart';

class GlobalUI {
  static double uiScaleFactor = 1.0;
  static double uiRoundness = 6.0;
}

class LayoutVariants {
  final ComponentLayout normal;
  final ComponentLayout wide;
  final ComponentLayout wideContinue;
  final ComponentLayout continueWatching;
  final ComponentLayout continueReading;

  const LayoutVariants({
    required this.normal,
    ComponentLayout? wide,
    ComponentLayout? wideContinue,
    required this.continueWatching,
    required this.continueReading,
  }) : wide = wide ?? const ComponentLayout(width: 340, height: 115),
       wideContinue =
           wideContinue ?? const ComponentLayout(width: 360, height: 120);

  ComponentLayout resolve({
    bool isContinueWatching = false,
    bool isContinueReading = false,
    bool isWideMode = false,
  }) {
    if (isWideMode) {
      if (isContinueWatching || isContinueReading) return wideContinue;
      return wide;
    }
    if (isContinueWatching) return continueWatching;
    if (isContinueReading) return continueReading;
    return normal;
  }
}

enum MediaCardStyle {
  classic(
    'Classic',
    LayoutVariants(
      normal: ComponentLayout(width: 140, height: 230),
      continueWatching: ComponentLayout(width: 180, height: 180),
      continueReading: ComponentLayout(width: 140, height: 210),
    ),
  ),

  minimal(
    'Minimal',
    LayoutVariants(
      normal: ComponentLayout(width: 120, height: 180),
      continueWatching: ComponentLayout(width: 180, height: 180),
      continueReading: ComponentLayout(width: 140, height: 210),
    ),
  ),

  expressive(
    'Expressive',
    LayoutVariants(
      normal: ComponentLayout(width: 140, height: 230),
      wideContinue: ComponentLayout(width: 370, height: 125),
      continueWatching: ComponentLayout(width: 200, height: 200),
      continueReading: ComponentLayout(width: 160, height: 230),
    ),
  ),

  material(
    'Material',
    LayoutVariants(
      normal: ComponentLayout(width: 135, height: 210),
      continueWatching: ComponentLayout(width: 190, height: 190),
      continueReading: ComponentLayout(width: 150, height: 220),
    ),
  ),

  cinematic(
    'Cinematic',
    LayoutVariants(
      normal: ComponentLayout(width: 320, height: 120),
      wide: ComponentLayout(width: 360, height: 125),
      wideContinue: ComponentLayout(width: 380, height: 125),
      continueWatching: ComponentLayout(width: 320, height: 120),
      continueReading: ComponentLayout(width: 320, height: 120),
    ),
  ),

  neon(
    'Neon',
    LayoutVariants(
      normal: ComponentLayout(width: 130, height: 200),
      continueWatching: ComponentLayout(width: 180, height: 180),
      continueReading: ComponentLayout(width: 130, height: 200),
    ),
  ),

  compact(
    'Compact',
    LayoutVariants(
      normal: ComponentLayout(width: 200, height: 80),
      wide: ComponentLayout(width: 320, height: 95),
      wideContinue: ComponentLayout(width: 340, height: 100),
      continueWatching: ComponentLayout(width: 280, height: 90),
      continueReading: ComponentLayout(width: 280, height: 90),
    ),
  ),

  editorial(
    'Editorial',
    LayoutVariants(
      normal: ComponentLayout(width: 140, height: 220),
      wideContinue: ComponentLayout(width: 370, height: 125),
      continueWatching: ComponentLayout(width: 200, height: 250),
      continueReading: ComponentLayout(width: 170, height: 250),
    ),
  ),

  wideBanner(
    'Wide Banner',
    LayoutVariants(
      normal: ComponentLayout(width: 390, height: 125),
      wide: ComponentLayout(width: 430, height: 135),
      wideContinue: ComponentLayout(width: 440, height: 135),
      continueWatching: ComponentLayout(width: 390, height: 125),
      continueReading: ComponentLayout(width: 390, height: 125),
    ),
  );

  final String displayName;
  final LayoutVariants _variants;

  const MediaCardStyle(this.displayName, this._variants);

  ComponentLayout get baseLayout => _variants.normal;
  ComponentLayout get layout => getScaledLayout(GlobalUI.uiScaleFactor);

  ComponentLayout getBaseLayout({
    bool isContinueWatching = false,
    bool isContinueReading = false,
    bool isWideMode = false,
  }) {
    return _variants.resolve(
      isContinueWatching: isContinueWatching,
      isContinueReading: isContinueReading,
      isWideMode: isWideMode,
    );
  }

  ComponentLayout getLayout({
    bool isContinueWatching = false,
    bool isContinueReading = false,
    bool isWideMode = false,
  }) {
    return getScaledLayout(
      GlobalUI.uiScaleFactor,
      isContinueWatching: isContinueWatching,
      isContinueReading: isContinueReading,
      isWideMode: isWideMode,
    );
  }

  ComponentLayout getScaledLayout(
    double scale, {
    bool isContinueWatching = false,
    bool isContinueReading = false,
    bool isWideMode = false,
  }) {
    final base = getBaseLayout(
      isContinueWatching: isContinueWatching,
      isContinueReading: isContinueReading,
      isWideMode: isWideMode,
    );
    return ComponentLayout(
      width: base.width * scale,
      height: base.height * scale,
    );
  }
}

typedef ContinueWatchingStyle = MediaCardStyle;
typedef ContinueReadingStyle = MediaCardStyle;

enum NavBarStyle {
  classic('Classic'),
  minimal('Minimal'),
  frosted('Frosted Glass'),
  material('Material You');

  final String displayName;
  const NavBarStyle(this.displayName);
}
