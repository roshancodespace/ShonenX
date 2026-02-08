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
  String? _getString(String prefKey, String hiveKey) {
    if (sharedPrefs.containsKey(prefKey)) {
      return sharedPrefs.getString(prefKey);
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
    return null;
  }

  // --- Active Source IDs ---
  String? getActiveAnimeSourceId() => _getString(_keyAnimeId, _hiveAnimeId);
  void saveActiveAnimeSourceId(dynamic id) => sharedPrefs.setString(_keyAnimeId, id);

  String? getActiveMangaSourceId() => _getString(_keyMangaId, _hiveMangaId);
  void saveActiveMangaSourceId(dynamic id) => sharedPrefs.setString(_keyMangaId, id);

  String? getActiveNovelSourceId() => _getString(_keyNovelId, _hiveNovelId);
  void saveActiveNovelSourceId(dynamic id) => sharedPrefs.setString(_keyNovelId, id);

  // --- Active Repo URLs ---
  String getActiveAnimeRepo() => _getString(_keyAnimeRepo, _hiveAnimeRepo) ?? '';
  void saveActiveAnimeRepo(String repo) {
    sharedPrefs.setString(_keyAnimeRepo, repo);
    AppLogger.d("Saved Anime Repo: $repo");
  }

  String getActiveMangaRepo() => _getString(_keyMangaRepo, _hiveMangaRepo) ?? '';
  void saveActiveMangaRepo(String repo) {
    sharedPrefs.setString(_keyMangaRepo, repo);
    AppLogger.d("Saved Manga Repo: $repo");
  }

  String getActiveNovelRepo() => _getString(_keyNovelRepo, _hiveNovelRepo) ?? '';
  void saveActiveNovelRepo(String repo) {
    sharedPrefs.setString(_keyNovelRepo, repo);
    AppLogger.d("Saved Novel Repo: $repo");
  }
}
