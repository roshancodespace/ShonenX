import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

extension AnimeSourceSettingsHelper on AnimeSource {
  T getSetting<T>(SharedPreferences storage, String key, T defaultValue) {
    final value = storage.get('source_setting_${sourceInfo.id}_$key');
    if (value is T) return value;
    return defaultValue;
  }
}
