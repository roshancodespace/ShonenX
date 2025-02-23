import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class SettingsBox {
  Box<SettingsModel>? _settingsBox;
  final String boxName = 'local_settings';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _settingsBox = await Hive.openBox<SettingsModel>(boxName);
    } else {
      _settingsBox = Hive.box<SettingsModel>(boxName);
    }

    final settings = _settingsBox?.get(0);

    // Always migrate to the latest data structure
    await migrateSettings(settings);
  }

  Future<void> migrateSettings(SettingsModel? oldSettings) async {
    log("Migrating settings...");

    // Create a fully populated default SettingsModel to merge with old data
    final defaultSettings = SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(), // Include default UISettingsModel
    );

    // If no old settings exist, use the default and save it
    if (oldSettings == null) {
      log("No existing settings found, initializing with defaults: $defaultSettings");
      await saveSettings(defaultSettings);
      return;
    }

    // Merge old settings with defaults to ensure all fields are populated
    final newSettings = SettingsModel(
      providerSettings: oldSettings.providerSettings ?? defaultSettings.providerSettings,
      themeSettings: oldSettings.themeSettings ?? defaultSettings.themeSettings,
      playerSettings: oldSettings.playerSettings ?? defaultSettings.playerSettings,
      uiSettings: oldSettings.uiSettings ?? defaultSettings.uiSettings, // Handle null uiSettings
    );

    log("Migrated settings: $newSettings");

    await saveSettings(newSettings);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox?.put(0, settings);
  }

  ValueListenable<Box<SettingsModel>> get settingsBoxListenable =>
      _settingsBox!.listenable();

  Future<void> updateProviderSettings(ProviderSettingsModel providerSettings) async {
    final currentSettings = getSettings() ?? SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
    final updatedSettings = currentSettings.copyWith(providerSettings: providerSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updateThemeSettings(ThemeSettingsModel themeSettings) async {
    final currentSettings = getSettings() ?? SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
    final updatedSettings = currentSettings.copyWith(themeSettings: themeSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updatePlayerSettings(PlayerSettingsModel playerSettings) async {
    final currentSettings = getSettings() ?? SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
    final updatedSettings = currentSettings.copyWith(playerSettings: playerSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updateUISettings(UISettingsModel uiSettings) async {
    final currentSettings = getSettings() ?? SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
    final updatedSettings = currentSettings.copyWith(uiSettings: uiSettings);
    await saveSettings(updatedSettings);
  }

  SettingsModel? getSettings() {
    return _settingsBox?.get(0);
  }

  ProviderSettingsModel getProviderSettings() =>
      getSettings()?.providerSettings ?? ProviderSettingsModel();

  ThemeSettingsModel getAppearanceSettings() =>
      getSettings()?.themeSettings ?? ThemeSettingsModel();

  PlayerSettingsModel getPlayerSettings() =>
      getSettings()?.playerSettings ?? PlayerSettingsModel();

  UISettingsModel getUISettings() =>
      getSettings()?.uiSettings ?? UISettingsModel();
}