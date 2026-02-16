import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:shonenx/main.dart';

part 'update_provider.g.dart';

/// Keys
const _settingsBox = 'settings';
const _hiveKey = 'useAutomaticUpdates';
const _prefsKey = 'use_automatic_updates';

@riverpod
class AutomaticUpdates extends _$AutomaticUpdates {
  @override
  bool build() {
    if (sharedPrefs.containsKey(_prefsKey)) {
      return sharedPrefs.getBool(_prefsKey) ?? true;
    }

    if (Hive.isBoxOpen(_settingsBox)) {
      try {
        final box = Hive.box(_settingsBox);
        final val = box.get(_hiveKey);
        if (val is bool) {
          sharedPrefs.setBool(_prefsKey, val);
          return val;
        }
      } catch (_) {}
    }

    return true;
  }

  void toggle() {
    state = !state;
    sharedPrefs.setBool(_prefsKey, state);
  }

  void set(bool value) {
    state = value;
    sharedPrefs.setBool(_prefsKey, value);
  }
}
