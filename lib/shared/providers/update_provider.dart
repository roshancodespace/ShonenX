import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'update_provider.g.dart';

/// Keys
const _settingsBox = 'settings';
const _automaticUpdatesKey = 'useAutomaticUpdates';

@riverpod
class AutomaticUpdates extends _$AutomaticUpdates {
  @override
  bool build() {
    final box = Hive.box(_settingsBox);
    return box.get(_automaticUpdatesKey, defaultValue: true);
  }

  void toggle() {
    state = !state;
    Hive.box(_settingsBox).put(_automaticUpdatesKey, state);
  }

  void set(bool value) {
    state = value;
    Hive.box(_settingsBox).put(_automaticUpdatesKey, value);
  }
}
