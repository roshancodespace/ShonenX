import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/models/settings/theme_model.dart';
import 'package:shonenx/main.dart';

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeModel>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<ThemeModel> {
  static const _boxName = 'theme_settings';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'theme_settings_data';

  @override
  ThemeModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return ThemeModel.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<ThemeModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return ThemeModel();
  }

  void updateSettings(ThemeModel Function(ThemeModel) updater) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
