import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Keys
const _settingsBox = 'settings';
const _automaticUpdatesKey = 'useAutomaticUpdates';

/// Notifier
class AutomaticUpdatesNotifier extends StateNotifier<bool> {
  AutomaticUpdatesNotifier() : super(_loadInitial());

  static bool _loadInitial() {
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

/// Provider
final automaticUpdatesProvider =
    StateNotifierProvider<AutomaticUpdatesNotifier, bool>(
  (ref) => AutomaticUpdatesNotifier(),
);
