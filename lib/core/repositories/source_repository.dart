import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';

class SourceRepository {
  static const _boxName = 'themedata'; // Legacy Hive box name

  // Prefs Keys
  static const _keyAnimeId = 'active_anime_source_id';
  static const _keyMangaId = 'active_manga_source_id';
  static const _keyNovelId = 'active_novel_source_id';
  static const _keyAnimeRepo = 'active_anime_repo';
  static const _keyMangaRepo = 'active_manga_repo';
  static const _keyNovelRepo = 'active_novel_repo';

  // Hive Keys (Legacy)
  static const _hiveAnimeId = 'activeSourceId';
  static const _hiveMangaId = 'activeMangaSourceId';
  static const _hiveNovelId = 'activeNovelSourceId';
  static const _hiveAnimeRepo = 'activeAnimeRepo';
  static const _hiveMangaRepo = 'activeMangaRepo';
  static const _hiveNovelRepo = 'activeNovelRepo';

  SourceRepository();

  // Helper for Int migration
  int? _getInt(String prefKey, String hiveKey) {
    if (sharedPrefs.containsKey(prefKey)) {
      return sharedPrefs.getInt(prefKey);
    }
    // Migration
    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box(_boxName);
        final val = box.get(hiveKey);
        if (val is int) {
          sharedPrefs.setInt(prefKey, val);
          return val;
        }
      } catch (_) {}
    }
    return null;
  }

  // Helper for String migration
  String _getString(String prefKey, String hiveKey, String def) {
    if (sharedPrefs.containsKey(prefKey)) {
      return sharedPrefs.getString(prefKey) ?? def;
    }
    // Migration
    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box(_boxName);
        final val = box.get(hiveKey);
        if (val is String) {
          sharedPrefs.setString(prefKey, val);
          return val;
        }
      } catch (_) {}
    }
    return def;
  }

  // --- Active Source IDs ---
  int? getActiveAnimeSourceId() => _getInt(_keyAnimeId, _hiveAnimeId);
  void saveActiveAnimeSourceId(int id) => sharedPrefs.setInt(_keyAnimeId, id);

  int? getActiveMangaSourceId() => _getInt(_keyMangaId, _hiveMangaId);
  void saveActiveMangaSourceId(int id) => sharedPrefs.setInt(_keyMangaId, id);

  int? getActiveNovelSourceId() => _getInt(_keyNovelId, _hiveNovelId);
  void saveActiveNovelSourceId(int id) => sharedPrefs.setInt(_keyNovelId, id);

  // --- Active Repo URLs ---
  String getActiveAnimeRepo() => _getString(_keyAnimeRepo, _hiveAnimeRepo, '');
  void saveActiveAnimeRepo(String repo) {
    sharedPrefs.setString(_keyAnimeRepo, repo);
    AppLogger.d("Saved Anime Repo: $repo");
  }

  String getActiveMangaRepo() => _getString(_keyMangaRepo, _hiveMangaRepo, '');
  void saveActiveMangaRepo(String repo) {
    sharedPrefs.setString(_keyMangaRepo, repo);
    AppLogger.d("Saved Manga Repo: $repo");
  }

  String getActiveNovelRepo() => _getString(_keyNovelRepo, _hiveNovelRepo, '');
  void saveActiveNovelRepo(String repo) {
    sharedPrefs.setString(_keyNovelRepo, repo);
    AppLogger.d("Saved Novel Repo: $repo");
  }
}
