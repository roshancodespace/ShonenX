import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/exo_player_prefs.dart';

class ExoPlayerPrefsNotifier extends Notifier<ExoPlayerPrefs> {
  static const _key = 'exo_player_prefs';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  ExoPlayerPrefs build() {
    final json = _storage.getString(_key);
    if (json != null) {
      try {
        return ExoPlayerPrefs.fromJson(json);
      } catch (_) {}
    }
    return const ExoPlayerPrefs();
  }

  void updatePrefs(ExoPlayerPrefs newPrefs) {
    state = newPrefs;
    _saveDb();
  }

  void _saveDb() {
    _storage.setString(_key, state.toJson());
  }
}

final exoPlayerPrefsProvider = NotifierProvider<ExoPlayerPrefsNotifier, ExoPlayerPrefs>(
  ExoPlayerPrefsNotifier.new,
);
