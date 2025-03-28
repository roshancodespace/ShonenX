import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class SettingsBox {
  Box<SettingsModel>? _settingsBox;
  final String boxName = 'local_settings';

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        _settingsBox = await Hive.openBox<SettingsModel>(boxName);
      } else {
        _settingsBox = Hive.box<SettingsModel>(boxName);
      }

      final settings = _settingsBox?.get(0);
      await migrateSettings(settings);
    } catch (e, stackTrace) {
      log('Error initializing SettingsBox: $e', name: 'settingsBox', error: e, stackTrace: stackTrace);
      rethrow; // Optionally handle or rethrow based on your app's needs
    }
  }

  Future<void> migrateSettings(SettingsModel? oldSettings) async {
    log("Migrating settings...", name: "settingsBox");

    // Define default settings with all fields populated
    final defaultSettings = SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );

    if (oldSettings == null) {
      log("No existing settings found, initializing with defaults: $defaultSettings", name: "settingsBox");
      await saveSettings(defaultSettings);
      return;
    }

    // Merge old settings with defaults to ensure all fields are present
    final newSettings = SettingsModel(
      providerSettings: oldSettings.providerSettings.copyWith(), // Ensure deep copy
      themeSettings: oldSettings.themeSettings.copyWith(),
      playerSettings: oldSettings.playerSettings.copyWith(),
      uiSettings: oldSettings.uiSettings?.copyWith() ?? defaultSettings.uiSettings,
    );

    log("Migrated settings: $newSettings", name: "settingsBox");
    await saveSettings(newSettings);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await _settingsBox?.put(0, settings);
    } catch (e, stackTrace) {
      log('Error saving settings: $e', name: 'settingsBox', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  ValueListenable<Box<SettingsModel>> get settingsBoxListenable {
    if (_settingsBox == null) {
      throw StateError('SettingsBox not initialized. Call init() first.');
    }
    return _settingsBox!.listenable();
  }

  Future<void> updateProviderSettings(ProviderSettingsModel providerSettings) async {
    final currentSettings = getSettings() ?? _createDefaultSettings();
    final updatedSettings = currentSettings.copyWith(providerSettings: providerSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updateThemeSettings(ThemeSettingsModel themeSettings) async {
    final currentSettings = getSettings() ?? _createDefaultSettings();
    final updatedSettings = currentSettings.copyWith(themeSettings: themeSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updatePlayerSettings(PlayerSettingsModel playerSettings) async {
    final currentSettings = getSettings() ?? _createDefaultSettings();
    final updatedSettings = currentSettings.copyWith(playerSettings: playerSettings);
    await saveSettings(updatedSettings);
  }

  Future<void> updateUISettings(UISettingsModel uiSettings) async {
    final currentSettings = getSettings() ?? _createDefaultSettings();
    final updatedSettings = currentSettings.copyWith(uiSettings: uiSettings);
    await saveSettings(updatedSettings);
  }

  SettingsModel? getSettings() {
    return _settingsBox?.get(0);
  }

  ProviderSettingsModel getProviderSettings() {
    return getSettings()?.providerSettings ?? ProviderSettingsModel();
  }

  ThemeSettingsModel getAppearanceSettings() { // Renamed for consistency with your naming
    return getSettings()?.themeSettings ?? ThemeSettingsModel();
  }

  PlayerSettingsModel getPlayerSettings() {
    return getSettings()?.playerSettings ?? PlayerSettingsModel();
  }

  UISettingsModel getUISettings() {
    return getSettings()?.uiSettings ?? UISettingsModel();
  }

  // Helper method to avoid repetition
  SettingsModel _createDefaultSettings() {
    return SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
  }

  // Optional: Reset to defaults
  Future<void> resetToDefaults() async {
    final defaultSettings = _createDefaultSettings();
    await saveSettings(defaultSettings);
  }
}