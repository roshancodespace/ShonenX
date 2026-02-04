import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/main.dart';

final playerSettingsProvider =
    NotifierProvider<PlayerSettingsNotifier, PlayerModel>(
      PlayerSettingsNotifier.new,
    );

class PlayerSettingsNotifier extends Notifier<PlayerModel> {
  static const _boxName = 'player_settings';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'player_settings_data';

  @override
  PlayerModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return PlayerModel.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<PlayerModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return PlayerModel();
  }

  void updateSettings(PlayerModel Function(PlayerModel) updater) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
