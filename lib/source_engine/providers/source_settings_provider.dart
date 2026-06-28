import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

final sourceSettingsProvider =
    NotifierProvider.family<
      SourceSettingsNotifier,
      Map<String, dynamic>,
      String
    >(SourceSettingsNotifier.new, name: 'sourceSettingsProvider');

class SourceSettingsNotifier extends Notifier<Map<String, dynamic>> {
  late final SharedPreferences _storage = ref.read(sharedPreferencesProvider);

  SourceSettingsNotifier(this.sourceId);

  final String sourceId;

  @override
  Map<String, dynamic> build() {
    return _loadSettings();
  }

  Map<String, dynamic> _loadSettings() {
    final keys = _storage.getKeys();
    final prefix = 'source_setting_${sourceId}_';
    final map = <String, dynamic>{};

    for (final key in keys) {
      if (key.startsWith(prefix)) {
        final settingId = key.replaceFirst(prefix, '');
        map[settingId] = _storage.get(key);
      }
    }
    return map;
  }

  void updateSetting(String settingId, dynamic value) {
    final key = 'source_setting_${sourceId}_$settingId';

    if (value is String) {
      _storage.setString(key, value);
    } else if (value is bool) {
      _storage.setBool(key, value);
    } else if (value is int) {
      _storage.setInt(key, value);
    } else if (value is double) {
      _storage.setDouble(key, value);
    } else if (value is List<String>) {
      _storage.setStringList(key, value);
    }

    state = {...state, settingId: value};
  }

  dynamic getSetting(String settingId, {dynamic defaultValue}) {
    return state[settingId] ?? defaultValue;
  }
}
