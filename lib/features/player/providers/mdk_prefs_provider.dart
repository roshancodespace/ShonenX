import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/mdk_prefs.dart';

class MdkPrefsNotifier extends Notifier<MdkPrefs> {
  static const _key = 'mdk_prefs';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  MdkPrefs build() {
    final json = _storage.getString(_key);
    if (json != null) {
      try {
        return MdkPrefs.fromJson(json);
      } catch (_) {}
    }
    return const MdkPrefs();
  }

  void updatePrefs(MdkPrefs newPrefs) {
    state = newPrefs;
    _saveDb();
  }

  void _saveDb() {
    _storage.setString(_key, state.toJson());
  }
}

final mdkPrefsProvider = NotifierProvider<MdkPrefsNotifier, MdkPrefs>(
  MdkPrefsNotifier.new,
);
