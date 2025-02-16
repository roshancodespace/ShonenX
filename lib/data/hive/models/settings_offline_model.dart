import 'package:hive/hive.dart';

part 'settings_offline_model.g.dart';

@HiveType(typeId: 0)
class SettingsModel {
  @HiveField(0)
  final ProviderSettingsModel? providerSettings;

  @HiveField(1)
  final AppearanceSettingsModel? appearanceSettings;

  SettingsModel({this.providerSettings, this.appearanceSettings});

  SettingsModel copyWith({
    ProviderSettingsModel? providerSettings,
    AppearanceSettingsModel? appearanceSettings,
  }) {
    return SettingsModel(
      providerSettings: providerSettings ?? this.providerSettings,
      appearanceSettings: appearanceSettings ?? this.appearanceSettings,
    );
  }
}

@HiveType(typeId: 1)
class ProviderSettingsModel {
  @HiveField(0)
  final String selectedProviderName;

  ProviderSettingsModel({this.selectedProviderName = 'hianime'});

  // Copy method to create a new instance with the same values
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

  AppearanceSettingsModel({this.themeMode = 'system'});

  AppearanceSettingsModel copyWith({
    String? theme,
    bool? isDarkMode,
  }) {
    return AppearanceSettingsModel(
      themeMode: theme ?? themeMode,
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
    bool? isDarkMode,
  }) {
    return AnilistSettings(
      themeMode: theme ?? themeMode,
    );
  }
}
