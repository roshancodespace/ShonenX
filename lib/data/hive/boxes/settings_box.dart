import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class SettingsBox {
  static const String _boxName = 'local_settings';
  static const int _settingsKey = 0;
  Box<SettingsModel>? _settingsBox;

  /// Initializes the Hive box for settings.
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _settingsBox = await Hive.openBox<SettingsModel>(_boxName);
      } else {
        _settingsBox = Hive.box<SettingsModel>(_boxName);
      }
      final settings = _settingsBox?.get(_settingsKey);
      await _migrateSettings(settings);
    } catch (e, stackTrace) {
      log('Error initializing SettingsBox: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Migrates old settings to the current format, or initializes with defaults if none exist.
  Future<void> _migrateSettings(SettingsModel? oldSettings) async {
    log('Migrating settings...', name: 'SettingsBox');

    final defaultSettings = _createDefaultSettings();

    if (oldSettings == null) {
      log('No existing settings found, initializing with defaults: $defaultSettings',
          name: 'SettingsBox');
      await _saveSettings(defaultSettings);
      return;
    }

    // Merge old settings with defaults to ensure all fields are present
    final newSettings = SettingsModel(
      providerSettings: oldSettings.providerSettings.copyWith(),
      themeSettings: oldSettings.themeSettings.copyWith(),
      playerSettings: oldSettings.playerSettings.copyWith(),
      uiSettings: oldSettings.uiSettings?.copyWith() ?? defaultSettings.uiSettings,
    );

    log('Migrated settings: $newSettings', name: 'SettingsBox');
    await _saveSettings(newSettings);
  }

  /// Saves the settings to the Hive box.
  Future<void> _saveSettings(SettingsModel settings) async {
    _ensureInitialized();
    try {
      await _settingsBox!.put(_settingsKey, settings);
    } catch (e, stackTrace) {
      log('Error saving settings: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Ensures the box is initialized before performing operations.
  void _ensureInitialized() {
    if (_settingsBox == null) {
      throw StateError('SettingsBox not initialized. Call init() first.');
    }
  }

  /// Returns a listenable for the settings box to watch for changes.
  ValueListenable<Box<SettingsModel>> get settingsBoxListenable {
    _ensureInitialized();
    return _settingsBox!.listenable();
  }

  /// Updates the provider settings.
  Future<void> updateProviderSettings(ProviderSettingsModel providerSettings) async {
    await _updateSettings((current) => current.copyWith(providerSettings: providerSettings));
  }

  /// Updates the theme settings.
  Future<void> updateThemeSettings(ThemeSettingsModel themeSettings) async {
    await _updateSettings((current) => current.copyWith(themeSettings: themeSettings));
  }

  /// Updates the player settings.
  Future<void> updatePlayerSettings(PlayerSettingsModel playerSettings) async {
    await _updateSettings((current) => current.copyWith(playerSettings: playerSettings));
  }

  /// Updates the UI settings.
  Future<void> updateUISettings(UISettingsModel uiSettings) async {
    await _updateSettings((current) => current.copyWith(uiSettings: uiSettings));
  }

  /// Generic method to update settings with a transformation function.
  Future<void> _updateSettings(SettingsModel Function(SettingsModel) transform) async {
    _ensureInitialized();
    try {
      final currentSettings = getSettings() ?? _createDefaultSettings();
      final updatedSettings = transform(currentSettings);
      await _saveSettings(updatedSettings);
    } catch (e, stackTrace) {
      log('Error updating settings: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieves the current settings, or null if not found.
  SettingsModel? getSettings() {
    _ensureInitialized();
    return _settingsBox!.get(_settingsKey);
  }

  /// Retrieves the provider settings, returning a default if not found.
  ProviderSettingsModel getProviderSettings() {
    return getSettings()?.providerSettings ?? ProviderSettingsModel();
  }

  /// Retrieves the theme settings, returning a default if not found.
  ThemeSettingsModel getThemeSettings() {
    return getSettings()?.themeSettings ?? ThemeSettingsModel();
  }

  /// Retrieves the player settings, returning a default if not found.
  PlayerSettingsModel getPlayerSettings() {
    return getSettings()?.playerSettings ?? PlayerSettingsModel();
  }

  /// Retrieves the UI settings, returning a default if not found.
  UISettingsModel getUISettings() {
    return getSettings()?.uiSettings ?? UISettingsModel();
  }

  /// Creates default settings with all fields populated.
  SettingsModel _createDefaultSettings() {
    return SettingsModel(
      providerSettings: ProviderSettingsModel(),
      themeSettings: ThemeSettingsModel(),
      playerSettings: PlayerSettingsModel(),
      uiSettings: UISettingsModel(),
    );
  }

  /// Resets settings to defaults.
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = _createDefaultSettings();
      await _saveSettings(defaultSettings);
    } catch (e, stackTrace) {
      log('Error resetting settings to defaults: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Closes the Hive box (optional, for cleanup).
  Future<void> close() async {
    try {
      await _settingsBox?.close();
      _settingsBox = null;
    } catch (e, stackTrace) {
      log('Error closing SettingsBox: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}