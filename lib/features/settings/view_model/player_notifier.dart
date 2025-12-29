import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/player_model.dart';

final playerSettingsProvider =
    NotifierProvider<PlayerSettingsNotifier, PlayerModel>(
  PlayerSettingsNotifier.new,
);

class PlayerSettingsNotifier extends Notifier<PlayerModel> {
  static const _boxName = 'player_settings';
  static const _key = 'settings';

  @override
  PlayerModel build() {
    final box = Hive.box<PlayerModel>(_boxName);
    return box.get(_key, defaultValue: PlayerModel()) ?? PlayerModel();
  }

  void updateSettings(PlayerModel Function(PlayerModel) updater) {
    state = updater(state);
    Hive.box<PlayerModel>(_boxName).put(_key, state);
  }
}
