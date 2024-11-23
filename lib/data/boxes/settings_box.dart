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
    _box = Hive.box<SettingsModel>(boxName);
    _settingsModel = _box.get(0) ?? SettingsModel();
    await _box.put(0, _settingsModel!);
  }

  // Get the theme from SettingsBox
  String? getTheme() {
    debugPrint(_settingsModel?.theme);
    return _settingsModel?.theme ?? 'dark';
  }

  // Update theme in SettingsBox
  Future<void> updateTheme(String theme) async {
    _settingsModel!.theme = theme;
    await _box.put(0, _settingsModel!);
  }
}
