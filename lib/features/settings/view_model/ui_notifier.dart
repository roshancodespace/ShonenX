import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';
import 'package:shonenx/main.dart';

final uiSettingsProvider = NotifierProvider<UiSettingsNotifier, UiSettings>(
  UiSettingsNotifier.new,
);

class UiSettingsNotifier extends Notifier<UiSettings> {
  static const _boxName = 'ui_settings';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'ui_settings_data';

  @override
  UiSettings build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return UiSettings.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<UiSettings>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return UiSettings();
  }

  void updateSettings(UiSettings Function(UiSettings) updater) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
