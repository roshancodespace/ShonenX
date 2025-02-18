import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class SettingsBox {
  Box<SettingsModel>? _settingsBox; // Change to nullable to handle init checks
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

    final newSettings = SettingsModel(
      providerSettings:
          oldSettings?.providerSettings ?? ProviderSettingsModel(),
      appearanceSettings:
          oldSettings?.appearanceSettings ?? AppearanceSettingsModel(),
      playerSettings: oldSettings?.playerSettings ?? PlayerSettingsModel(),
    );

    log("Saving new settings: $newSettings");

    await saveSettings(newSettings);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox?.put(0, settings);
  }

  ValueListenable<Box<SettingsModel>> get settingsBoxListenable =>
      _settingsBox!.listenable();

  Future<void> updateProviderSettings(
      ProviderSettingsModel providerSettings) async {
    final currentSettings = getSettings();
    if (currentSettings != null) {
      final updatedSettings =
          currentSettings.copyWith(providerSettings: providerSettings);
      await saveSettings(updatedSettings);
    }
  }

  Future<void> updateAppearanceSettings(
      AppearanceSettingsModel appearanceSettings) async {
    final currentSettings = getSettings();
    if (currentSettings != null) {
      final updatedSettings =
          currentSettings.copyWith(appearanceSettings: appearanceSettings);
      await saveSettings(updatedSettings);
    }
  }

  Future<void> updatePlayerSettings(PlayerSettingsModel playerSettings) async {
    final currentSettings = getSettings();
    if (currentSettings != null) {
      final updatedSettings =
          currentSettings.copyWith(playerSettings: playerSettings);
      await saveSettings(updatedSettings);
    }
  }

  SettingsModel? getSettings() {
    return _settingsBox?.get(0);
  }

  ProviderSettingsModel getProviderSettings() =>
      getSettings()?.providerSettings ?? ProviderSettingsModel();

  AppearanceSettingsModel getAppearanceSettings() =>
      getSettings()?.appearanceSettings ?? AppearanceSettingsModel();

  PlayerSettingsModel getPlayerSettings() =>
      getSettings()?.playerSettings ?? PlayerSettingsModel();
}
