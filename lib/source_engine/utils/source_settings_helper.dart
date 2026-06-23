import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

extension MediaSourceSettingsHelper on MediaSource {
  T getSetting<T>(SharedPreferences storage, String key, T defaultValue) {
    final value = storage.get('source_setting_${sourceInfo.id}_$key');
    if (value is T) return value;

    // Handle List<String> which might come as List<Object?>
    if (defaultValue is List<String> && value is List) {
      return value.map((e) => e.toString()).toList() as T;
    }

    return defaultValue;
  }
}
