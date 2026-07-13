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
  liquidGlass(ComponentLayout(width: 140, height: 210)),
  experimentalLiquid(ComponentLayout(width: 145, height: 220)),
  cinematic(ComponentLayout(width: 320, height: 120)),
  frosted(ComponentLayout(width: 135, height: 215)),
  neon(ComponentLayout(width: 130, height: 200)),
  compact(ComponentLayout(width: 200, height: 80)),
  editorial(ComponentLayout(width: 140, height: 220)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const MediaCardStyle(this._baseLayout);

  ComponentLayout get baseLayout => _baseLayout;

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalUI.uiScaleFactor,
      height: _baseLayout.height * GlobalUI.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: _baseLayout.width * scale,
      height: _baseLayout.height * scale,
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
      case MediaCardStyle.liquidGlass:
        return 'Liquid Glass';
      case MediaCardStyle.experimentalLiquid:
        return 'Experimental Liquid';
      case MediaCardStyle.cinematic:
        return 'Cinematic';
      case MediaCardStyle.frosted:
        return 'Frosted';
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

enum ContinueWatchingStyle {
  classic(ComponentLayout(width: 180, height: 180)),
  minimal(ComponentLayout(width: 180, height: 180)),
  expressive(ComponentLayout(width: 200, height: 200)),
  material(ComponentLayout(width: 190, height: 190)),
  liquidGlass(ComponentLayout(width: 200, height: 200)),
  experimentalLiquid(ComponentLayout(width: 200, height: 200)),
  cinematic(ComponentLayout(width: 320, height: 120)),
  frosted(ComponentLayout(width: 320, height: 125)),
  neon(ComponentLayout(width: 300, height: 110)),
  compact(ComponentLayout(width: 280, height: 90)),
  editorial(ComponentLayout(width: 200, height: 200)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const ContinueWatchingStyle(this._baseLayout);

  ComponentLayout get baseLayout => _baseLayout;

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalUI.uiScaleFactor,
      height: _baseLayout.height * GlobalUI.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: _baseLayout.width * scale,
      height: _baseLayout.height * scale,
    );
  }

  String get displayName {
    switch (this) {
      case ContinueWatchingStyle.classic:
        return 'Classic';
      case ContinueWatchingStyle.minimal:
        return 'Minimal';
      case ContinueWatchingStyle.expressive:
        return 'Expressive';
      case ContinueWatchingStyle.material:
        return 'Material';
      case ContinueWatchingStyle.liquidGlass:
        return 'Liquid Glass';
      case ContinueWatchingStyle.experimentalLiquid:
        return 'Experimental Liquid';
      case ContinueWatchingStyle.cinematic:
        return 'Cinematic';
      case ContinueWatchingStyle.frosted:
        return 'Frosted';
      case ContinueWatchingStyle.neon:
        return 'Neon';
      case ContinueWatchingStyle.compact:
        return 'Compact';
      case ContinueWatchingStyle.editorial:
        return 'Editorial';
      case ContinueWatchingStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

enum ContinueReadingStyle {
  classic(ComponentLayout(width: 140, height: 210)),
  minimal(ComponentLayout(width: 140, height: 210)),
  expressive(ComponentLayout(width: 160, height: 230)),
  material(ComponentLayout(width: 150, height: 220)),
  liquidGlass(ComponentLayout(width: 160, height: 230)),
  experimentalLiquid(ComponentLayout(width: 160, height: 230)),
  cinematic(ComponentLayout(width: 320, height: 120)),
  frosted(ComponentLayout(width: 320, height: 125)),
  neon(ComponentLayout(width: 300, height: 110)),
  compact(ComponentLayout(width: 280, height: 90)),
  editorial(ComponentLayout(width: 170, height: 220)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const ContinueReadingStyle(this._baseLayout);

  ComponentLayout get baseLayout => _baseLayout;

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalUI.uiScaleFactor,
      height: _baseLayout.height * GlobalUI.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: _baseLayout.width * scale,
      height: _baseLayout.height * scale,
    );
  }

  String get displayName {
    switch (this) {
      case ContinueReadingStyle.classic:
        return 'Classic';
      case ContinueReadingStyle.minimal:
        return 'Minimal';
      case ContinueReadingStyle.expressive:
        return 'Expressive';
      case ContinueReadingStyle.material:
        return 'Material';
      case ContinueReadingStyle.liquidGlass:
        return 'Liquid Glass';
      case ContinueReadingStyle.experimentalLiquid:
        return 'Experimental Liquid';
      case ContinueReadingStyle.cinematic:
        return 'Cinematic';
      case ContinueReadingStyle.frosted:
        return 'Frosted';
      case ContinueReadingStyle.neon:
        return 'Neon';
      case ContinueReadingStyle.compact:
        return 'Compact';
      case ContinueReadingStyle.editorial:
        return 'Editorial';
      case ContinueReadingStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

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
