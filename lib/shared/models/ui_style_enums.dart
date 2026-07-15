import 'package:shonenx/shared/models/component_layout.dart';

class GlobalUI {
  static double uiScaleFactor = 1.0;
  static double uiRoundness = 6.0;
}

enum MediaCardStyle {
  classic(ComponentLayout(width: 125, height: 215)),
  minimal(ComponentLayout(width: 120, height: 180)),
  expressive(ComponentLayout(width: 140, height: 230)),
  material(ComponentLayout(width: 135, height: 210)),
  cinematic(ComponentLayout(width: 320, height: 120)),
  neon(ComponentLayout(width: 130, height: 200)),
  compact(ComponentLayout(width: 200, height: 80)),
  editorial(ComponentLayout(width: 140, height: 220)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const MediaCardStyle(this._baseLayout);

  ComponentLayout get baseLayout => _baseLayout;

  ComponentLayout getBaseLayout({
    bool isContinueWatching = false,
    bool isContinueReading = false,
    bool isWideMode = false,
  }) {
    if (isWideMode) {
      if (isContinueWatching || isContinueReading) {
        return switch (this) {
          MediaCardStyle.cinematic => const ComponentLayout(
            width: 380,
            height: 135,
          ),
          MediaCardStyle.wideBanner => const ComponentLayout(
            width: 440,
            height: 135,
          ),
          MediaCardStyle.compact => const ComponentLayout(
            width: 340,
            height: 125,
          ),
          MediaCardStyle.editorial => const ComponentLayout(
            width: 370,
            height: 135,
          ),
          MediaCardStyle.expressive => const ComponentLayout(
            width: 370,
            height: 135,
          ),
          _ => const ComponentLayout(width: 370, height: 160),
        };
      }
      return switch (this) {
        MediaCardStyle.cinematic => const ComponentLayout(
          width: 360,
          height: 150,
        ),
        MediaCardStyle.wideBanner => const ComponentLayout(
          width: 430,
          height: 155,
        ),
        MediaCardStyle.compact => const ComponentLayout(
          width: 320,
          height: 115,
        ),
        _ => const ComponentLayout(width: 340, height: 145),
      };
    }

    if (isContinueWatching) {
      return switch (this) {
        MediaCardStyle.classic ||
        MediaCardStyle.minimal ||
        MediaCardStyle.neon => const ComponentLayout(width: 180, height: 180),
        MediaCardStyle.expressive => const ComponentLayout(
          width: 200,
          height: 200,
        ),
        MediaCardStyle.material => const ComponentLayout(
          width: 190,
          height: 190,
        ),
        MediaCardStyle.cinematic => const ComponentLayout(
          width: 320,
          height: 120,
        ),
        MediaCardStyle.compact => const ComponentLayout(width: 280, height: 90),
        MediaCardStyle.editorial => const ComponentLayout(
          width: 200,
          height: 250,
        ),
        MediaCardStyle.wideBanner => const ComponentLayout(
          width: 390,
          height: 125,
        ),
      };
    } else if (isContinueReading) {
      return switch (this) {
        MediaCardStyle.classic || MediaCardStyle.minimal =>
          const ComponentLayout(width: 140, height: 210),
        MediaCardStyle.expressive => const ComponentLayout(
          width: 160,
          height: 230,
        ),
        MediaCardStyle.material => const ComponentLayout(
          width: 150,
          height: 220,
        ),
        MediaCardStyle.neon => const ComponentLayout(width: 130, height: 200),
        MediaCardStyle.cinematic => const ComponentLayout(
          width: 320,
          height: 120,
        ),
        MediaCardStyle.compact => const ComponentLayout(width: 280, height: 90),
        MediaCardStyle.editorial => const ComponentLayout(
          width: 170,
          height: 250,
        ),
        MediaCardStyle.wideBanner => const ComponentLayout(
          width: 390,
          height: 125,
        ),
      };
    }
    return _baseLayout;
  }

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalUI.uiScaleFactor,
      height: _baseLayout.height * GlobalUI.uiScaleFactor,
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

  String get displayName {
    switch (this) {
      case MediaCardStyle.classic:
        return 'Classic';
      case MediaCardStyle.minimal:
        return 'Minimal';
      case MediaCardStyle.expressive:
        return 'Expressive';
      case MediaCardStyle.material:
        return 'Material';
      case MediaCardStyle.cinematic:
        return 'Cinematic';
      case MediaCardStyle.neon:
        return 'Neon';
      case MediaCardStyle.compact:
        return 'Compact';
      case MediaCardStyle.editorial:
        return 'Editorial';
      case MediaCardStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

typedef ContinueWatchingStyle = MediaCardStyle;
typedef ContinueReadingStyle = MediaCardStyle;

enum NavBarStyle {
  classic,
  minimal,
  frosted,
  material;

  String get displayName {
    switch (this) {
      case NavBarStyle.classic:
        return 'Classic';
      case NavBarStyle.minimal:
        return 'Minimal';
      case NavBarStyle.frosted:
        return 'Frosted Glass';
      case NavBarStyle.material:
        return 'Material You';
    }
  }
}
