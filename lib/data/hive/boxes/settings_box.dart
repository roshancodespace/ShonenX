import 'package:hive/hive.dart';
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
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox?.put(0, settings); // Use null safety
  }

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

  SettingsModel? getSettings() {
    return _settingsBox?.get(0);
  }
}
