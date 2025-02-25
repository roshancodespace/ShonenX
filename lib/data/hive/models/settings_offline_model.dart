// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hive/hive.dart';

part 'settings_offline_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  final ProviderSettingsModel providerSettings;

  @HiveField(1)
  final ThemeSettingsModel themeSettings;

  @HiveField(2)
  final PlayerSettingsModel playerSettings;

  @HiveField(3)
  final UISettingsModel? uiSettings; // New UI Settings field

  SettingsModel({
    required this.providerSettings,
    required this.themeSettings,
    required this.playerSettings,
    this.uiSettings,
  });

  SettingsModel copyWith({
    ProviderSettingsModel? providerSettings,
    ThemeSettingsModel? themeSettings,
    PlayerSettingsModel? playerSettings,
    UISettingsModel? uiSettings,
  }) {
    return SettingsModel(
      providerSettings: providerSettings ?? this.providerSettings,
      themeSettings: themeSettings ?? this.themeSettings,
      playerSettings: playerSettings ?? this.playerSettings,
      uiSettings: uiSettings ?? this.uiSettings,
    );
  }
}

@HiveType(typeId: 2)
class ProviderSettingsModel extends HiveObject {
  @HiveField(0)
  final String selectedProviderName;

  ProviderSettingsModel({this.selectedProviderName = 'hianime'});

  ProviderSettingsModel copyWith({String? selectedProviderName}) {
    return ProviderSettingsModel(
      selectedProviderName: selectedProviderName ?? this.selectedProviderName,
    );
  }
}

@HiveType(typeId: 3)
class ThemeSettingsModel extends HiveObject {
  @HiveField(0)
  final String themeMode;
  @HiveField(1)
  final bool amoled;
  @HiveField(2)
  final String colorScheme;
  @HiveField(3)
  final bool useMaterial3;
  @HiveField(4)
  final bool useSubThemes;
  @HiveField(5)
  final double surfaceModeLight;
  @HiveField(6)
  final double surfaceModeDark;
  @HiveField(7)
  final bool useKeyColors;
  @HiveField(8)
  final bool useAppbarColors;
  @HiveField(9)
  final bool swapLightColors;
  @HiveField(10)
  final bool swapDarkColors;
  @HiveField(11)
  final bool useTertiary;
  @HiveField(12)
  final int blendLevel;
  @HiveField(13)
  final double appBarOpacity;
  @HiveField(14)
  final bool transparentStatusBar;
  @HiveField(15)
  final double tabBarOpacity;
  @HiveField(16)
  final double bottomBarOpacity;
  @HiveField(17)
  final bool tooltipsMatchBackground;
  @HiveField(18)
  final double defaultRadius;
  @HiveField(19)
  final bool useTextTheme;
  @HiveField(20)
  final String tabBarStyle;

  ThemeSettingsModel({
    this.themeMode = 'system',
    this.amoled = false,
    this.colorScheme = 'red',
    this.useMaterial3 = true,
    this.useSubThemes = true,
    this.surfaceModeLight = 0,
    this.surfaceModeDark = 0,
    this.useKeyColors = true,
    this.useAppbarColors = false,
    this.swapLightColors = false,
    this.swapDarkColors = false,
    this.useTertiary = true,
    this.blendLevel = 0,
    this.appBarOpacity = 1.0,
    this.transparentStatusBar = false,
    this.tabBarOpacity = 1.0,
    this.bottomBarOpacity = 1.0,
    this.tooltipsMatchBackground = false,
    this.defaultRadius = 12.0,
    this.useTextTheme = true,
    this.tabBarStyle = 'forBackground',
  });

  ThemeSettingsModel copyWith({
    String? themeMode,
    bool? amoled,
    String? colorScheme,
    bool? useMaterial3,
    bool? useSubThemes,
    double? surfaceModeLight,
    double? surfaceModeDark,
    bool? useKeyColors,
    bool? useAppbarColors,
    bool? swapLightColors,
    bool? swapDarkColors,
    bool? useTertiary,
    int? blendLevel,
    double? appBarOpacity,
    bool? transparentStatusBar,
    double? tabBarOpacity,
    double? bottomBarOpacity,
    bool? tooltipsMatchBackground,
    double? defaultRadius,
    bool? useTextTheme,
    String? tabBarStyle,
  }) {
    return ThemeSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      amoled: amoled ?? this.amoled,
      colorScheme: colorScheme ?? this.colorScheme,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      useSubThemes: useSubThemes ?? this.useSubThemes,
      surfaceModeLight: surfaceModeLight ?? this.surfaceModeLight,
      surfaceModeDark: surfaceModeDark ?? this.surfaceModeDark,
      useKeyColors: useKeyColors ?? this.useKeyColors,
      useAppbarColors: useAppbarColors ?? this.useAppbarColors,
      swapLightColors: swapLightColors ?? this.swapLightColors,
      swapDarkColors: swapDarkColors ?? this.swapDarkColors,
      useTertiary: useTertiary ?? this.useTertiary,
      blendLevel: blendLevel ?? this.blendLevel,
      appBarOpacity: appBarOpacity ?? this.appBarOpacity,
      transparentStatusBar: transparentStatusBar ?? this.transparentStatusBar,
      tabBarOpacity: tabBarOpacity ?? this.tabBarOpacity,
      bottomBarOpacity: bottomBarOpacity ?? this.bottomBarOpacity,
      tooltipsMatchBackground:
          tooltipsMatchBackground ?? this.tooltipsMatchBackground,
      defaultRadius: defaultRadius ?? this.defaultRadius,
      useTextTheme: useTextTheme ?? this.useTextTheme,
      tabBarStyle: tabBarStyle ?? this.tabBarStyle,
    );
  }

  FlexScheme get flexSchemeEnum => FlexScheme.values.firstWhere(
        (e) => e.name == colorScheme,
        orElse: () => FlexScheme.red,
      );

  FlexTabBarStyle get flexTabBarStyleEnum => FlexTabBarStyle.values.firstWhere(
        (e) => e.name == tabBarStyle,
        orElse: () => FlexTabBarStyle.forBackground,
      );
}

@HiveType(typeId: 4)
class AnilistSettings extends HiveObject {
  @HiveField(0)
  final String themeMode;

  AnilistSettings({this.themeMode = 'system'});

  AnilistSettings copyWith({
    String? theme,
  }) {
    return AnilistSettings(
      themeMode: theme ?? themeMode,
    );
  }
}

@HiveType(typeId: 5)
class PlayerSettingsModel extends HiveObject {
  @HiveField(0)
  final double episodeCompletionThreshold;

  @HiveField(1)
  final bool autoPlayNextEpisode;

  @HiveField(2)
  final bool preferSubtitles;

  PlayerSettingsModel({
    this.episodeCompletionThreshold = 0.9,
    this.autoPlayNextEpisode = true,
    this.preferSubtitles = false,
  });

  PlayerSettingsModel copyWith({
    double? episodeCompletionThreshold,
    bool? autoPlayNextEpisode,
    bool? preferSubtitles,
  }) {
    return PlayerSettingsModel(
      episodeCompletionThreshold:
          episodeCompletionThreshold ?? this.episodeCompletionThreshold,
      autoPlayNextEpisode: autoPlayNextEpisode ?? this.autoPlayNextEpisode,
      preferSubtitles: preferSubtitles ?? this.preferSubtitles,
    );
  }
}

@HiveType(typeId: 6)
class UISettingsModel extends HiveObject {
  @HiveField(0)
  final bool compactMode;

  @HiveField(1)
  final String defaultTab;

  @HiveField(2)
  final bool showThumbnails;

  @HiveField(3)
  final String cardStyle;

  @HiveField(4)
  final String layoutStyle;

  UISettingsModel({
    this.compactMode = false,
    this.defaultTab = 'Home',
    this.showThumbnails = true,
    this.cardStyle = 'Classic',
    this.layoutStyle = 'Grid',
  });

  UISettingsModel copyWith({
    bool? compactMode,
    String? defaultTab,
    bool? showThumbnails,
    String? cardStyle,
    String? layoutStyle,
  }) {
    return UISettingsModel(
      compactMode: compactMode ?? this.compactMode,
      defaultTab: defaultTab ?? this.defaultTab,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      cardStyle: cardStyle ?? this.cardStyle,
      layoutStyle: layoutStyle ?? this.layoutStyle,
    );
  }
}
