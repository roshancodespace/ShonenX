import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class MediaKitPrefsNotifier extends Notifier<MediaKitPrefs> {
  static const _key = 'media_kit_prefs';

  Timer? _debounceTimer;

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  MediaKitPrefs build() {
    ref.onDispose(_flush);

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
    if (state == newPrefs) return;
    state = newPrefs;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _saveDb);
  }

  void _saveDb() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _storage.setString(_key, state.toJson());
  }

  void _flush() {
    if (_debounceTimer?.isActive ?? false) {
      _saveDb();
    }
  }
}

final mediaKitPrefsProvider =
    NotifierProvider<MediaKitPrefsNotifier, MediaKitPrefs>(
      MediaKitPrefsNotifier.new,
    );
