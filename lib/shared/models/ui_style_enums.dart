class ComponentLayout {
  final double width;
  final double height;

  const ComponentLayout({required this.width, required this.height});

  double get aspectRatio => width / height;
}

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
  }) : wide = wide ?? const ComponentLayout(width: 340, height: 114),
       wideContinue =
           wideContinue ?? const ComponentLayout(width: 360, height: 118);

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
      normal: ComponentLayout(width: 142, height: 244),
      continueWatching: ComponentLayout(width: 210, height: 178),
      continueReading: ComponentLayout(width: 142, height: 238),
    ),
  ),

  minimal(
    'Minimal',
    LayoutVariants(
      normal: ComponentLayout(width: 134, height: 204),
      continueWatching: ComponentLayout(width: 210, height: 138),
      continueReading: ComponentLayout(width: 136, height: 204),
    ),
  ),

  expressive(
    'Expressive',
    LayoutVariants(
      normal: ComponentLayout(width: 146, height: 248),
      wideContinue: ComponentLayout(width: 368, height: 122),
      continueWatching: ComponentLayout(width: 216, height: 184),
      continueReading: ComponentLayout(width: 146, height: 244),
    ),
  ),

  material(
    'Material',
    LayoutVariants(
      normal: ComponentLayout(width: 142, height: 240),
      continueWatching: ComponentLayout(width: 210, height: 178),
      continueReading: ComponentLayout(width: 142, height: 236),
    ),
  ),

  cinematic(
    'Cinematic',
    LayoutVariants(
      normal: ComponentLayout(width: 320, height: 118),
      wide: ComponentLayout(width: 356, height: 120),
      wideContinue: ComponentLayout(width: 372, height: 122),
      continueWatching: ComponentLayout(width: 320, height: 118),
      continueReading: ComponentLayout(width: 320, height: 118),
    ),
  ),

  neon(
    'Neon',
    LayoutVariants(
      normal: ComponentLayout(width: 140, height: 236),
      continueWatching: ComponentLayout(width: 210, height: 178),
      continueReading: ComponentLayout(width: 140, height: 232),
    ),
  ),

  compact(
    'Compact',
    LayoutVariants(
      normal: ComponentLayout(width: 118, height: 186),
      wide: ComponentLayout(width: 316, height: 96),
      wideContinue: ComponentLayout(width: 336, height: 100),
      continueWatching: ComponentLayout(width: 288, height: 94),
      continueReading: ComponentLayout(width: 288, height: 94),
    ),
  ),

  editorial(
    'Editorial',
    LayoutVariants(
      normal: ComponentLayout(width: 144, height: 246),
      wideContinue: ComponentLayout(width: 368, height: 122),
      continueWatching: ComponentLayout(width: 214, height: 186),
      continueReading: ComponentLayout(width: 144, height: 242),
    ),
  ),

  wideBanner(
    'Wide Banner',
    LayoutVariants(
      normal: ComponentLayout(width: 380, height: 122),
      wide: ComponentLayout(width: 416, height: 128),
      wideContinue: ComponentLayout(width: 424, height: 130),
      continueWatching: ComponentLayout(width: 380, height: 122),
      continueReading: ComponentLayout(width: 380, height: 122),
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
  material('Material You'),
  docked('Docked');

  final String displayName;
  const NavBarStyle(this.displayName);
}

enum HomeHeaderStyle {
  classic('Classic'),
  minimal('Minimal'),
  material('Material'),
  prominent('Prominent'),
  docked('Docked');

  final String displayName;
  const HomeHeaderStyle(this.displayName);
}
