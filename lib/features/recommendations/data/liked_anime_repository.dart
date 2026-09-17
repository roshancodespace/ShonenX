import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/recommendations/domain/models/liked_anime.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class LikedAnimeRepository {
  static const String _storageKey = 'kurox_liked_anime_v1';
  final SharedPreferences _prefs;

  LikedAnimeRepository(this._prefs);

  Map<String, LikedAnime> loadAll() {
    final list = _prefs.getStringList(_storageKey);
    if (list == null || list.isEmpty) {
      return {};
    }

    final result = <String, LikedAnime>{};
    for (final jsonStr in list) {
      try {
        final item = LikedAnime.fromJson(jsonStr);
        if (item.id.isNotEmpty) {
          result[item.id] = item;
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> saveAll(Map<String, LikedAnime> items) async {
    final list = items.values.map((item) => item.toJson()).toList();
    await _prefs.setStringList(_storageKey, list);
  }

  bool isLiked(String id) {
    final all = loadAll();
    return all.containsKey(id);
  }

  Future<void> add(LikedAnime item) async {
    final all = loadAll();
    all[item.id] = item;
    await saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = loadAll();
    if (all.containsKey(id)) {
      all.remove(id);
      await saveAll(all);
    }
  }

  Future<bool> toggle(UnifiedMedia media) async {
    final all = loadAll();
    if (all.containsKey(media.id)) {
      all.remove(media.id);
      await saveAll(all);
      return false; // unliked
    } else {
      final newItem = LikedAnime.fromUnifiedMedia(media);
      all[media.id] = newItem;
      await saveAll(all);
      return true; // liked
    }
  }
}
