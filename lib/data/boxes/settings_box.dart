import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';

class SettingsBox {
  static const String boxName = 'settings';
  late Box<SettingsModel> _box;
  SettingsModel? _settingsModel;

  // Get listenable for the box
  ValueListenable<Box<SettingsModel>> listenable() => _box.listenable();

  Future<void> init() async {
    try {
      _box = Hive.box<SettingsModel>(boxName);
      _settingsModel = _box.get(0) ??
          SettingsModel(
            theme: ThemeModel(),
          );
      await _box.put(0, _settingsModel!);
    } catch (e) {
      // Handle initialization error (e.g., log the error)
    }
  }

  // Get the settings model
  SettingsModel? getSettingsModel() => _settingsModel;

  // Get the theme model
  ThemeModel? getTheme() => _settingsModel?.theme;

  // Update Theme
  Future<void> updateTheme(ThemeModel theme) async {
    _settingsModel?.theme = theme;
    await _box.put(0, _settingsModel!);
  }
}
