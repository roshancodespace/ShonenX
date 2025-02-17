// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hive/hive.dart';

part 'settings_offline_model.g.dart';

@HiveType(typeId: 0)
class SettingsModel {
  @HiveField(0)
  final ProviderSettingsModel? providerSettings;

  @HiveField(1)
  final AppearanceSettingsModel? appearanceSettings;

  @HiveField(2)
  final PlayerSettingsModel? playerSettings; // ✅ Added

  SettingsModel({
    this.providerSettings,
    this.appearanceSettings,
    this.playerSettings,
  });

  SettingsModel copyWith({
    ProviderSettingsModel? providerSettings,
    AppearanceSettingsModel? appearanceSettings,
    PlayerSettingsModel? playerSettings,
  }) {
    return SettingsModel(
      providerSettings: providerSettings ?? this.providerSettings,
      appearanceSettings: appearanceSettings ?? this.appearanceSettings,
      playerSettings: playerSettings ?? this.playerSettings,
    );
  }
}

@HiveType(typeId: 1)
class ProviderSettingsModel {
  @HiveField(0)
  final String selectedProviderName;

  ProviderSettingsModel({this.selectedProviderName = 'hianime'});

  ProviderSettingsModel copyWith({String? selectedProviderName}) {
    return ProviderSettingsModel(
      selectedProviderName: selectedProviderName ?? this.selectedProviderName,
    );
  }
}

@HiveType(typeId: 2)
class AppearanceSettingsModel {
  @HiveField(0)
  final String themeMode;
  @HiveField(1)
  final bool amoled;
  @HiveField(2)
  final FlexScheme colorScheme;

  AppearanceSettingsModel({this.themeMode = 'system', this.amoled = false, this.colorScheme = FlexScheme.red});


  AppearanceSettingsModel copyWith({
    String? themeMode,
    bool? amoled,
  }) {
    return AppearanceSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      amoled: amoled ?? this.amoled,
    );
  }
}

@HiveType(typeId: 3)
class AnilistSettings {
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

@HiveType(typeId: 4)
class PlayerSettingsModel {
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
