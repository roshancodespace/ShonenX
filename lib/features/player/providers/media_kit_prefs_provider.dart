import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';

class MediaKitPrefsNotifier extends Notifier<MediaKitPrefs> {
  static const _key = 'media_kit_prefs';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  MediaKitPrefs build() {
    final json = _storage.getString(_key);
    if (json != null) {
      return MediaKitPrefs.fromJson(json);
    }
    String defaultHwdec = 'auto-copy';
    try {
      if (Platform.isAndroid || Platform.isIOS) defaultHwdec = 'auto-safe';
    } catch (_) {}
    return MediaKitPrefs(hwdec: defaultHwdec);
  }

  void updatePrefs(MediaKitPrefs newPrefs) {
    state = newPrefs;
    _saveDb();
  }

  void _saveDb() {
    _storage.setString(_key, state.toJson());
  }
}

final mediaKitPrefsProvider = NotifierProvider<MediaKitPrefsNotifier, MediaKitPrefs>(
  MediaKitPrefsNotifier.new,
);