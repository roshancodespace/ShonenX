import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/video_player_prefs.dart';

class VideoPlayerPrefsNotifier extends Notifier<VideoPlayerPrefs> {
  static const _key = 'video_player_prefs';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  VideoPlayerPrefs build() {
    final json = _storage.getString(_key);
    if (json != null) {
      try {
        return VideoPlayerPrefs.fromJson(json);
      } catch (_) {}
    }
    return const VideoPlayerPrefs();
  }

  void updatePrefs(VideoPlayerPrefs newPrefs) {
    state = newPrefs;
    _saveDb();
  }

  void _saveDb() {
    _storage.setString(_key, state.toJson());
  }
}

final videoPlayerPrefsProvider =
    NotifierProvider<VideoPlayerPrefsNotifier, VideoPlayerPrefs>(
  VideoPlayerPrefsNotifier.new,
);
