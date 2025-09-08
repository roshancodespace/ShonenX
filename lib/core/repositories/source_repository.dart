import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class SourceRepository {
  final Box _box;

  SourceRepository() : _box = Hive.box('themedata');

  // --- Active Source IDs ---
  int? getActiveAnimeSourceId() => _box.get('activeSourceId');
  void saveActiveAnimeSourceId(int id) => _box.put('activeSourceId', id);

  int? getActiveMangaSourceId() => _box.get('activeMangaSourceId');
  void saveActiveMangaSourceId(int id) => _box.put('activeMangaSourceId', id);

  int? getActiveNovelSourceId() => _box.get('activeNovelSourceId');
  void saveActiveNovelSourceId(int id) => _box.put('activeNovelSourceId', id);

  // --- Active Repo URLs ---
  String getActiveAnimeRepo() => _box.get("activeAnimeRepo", defaultValue: '');
  void saveActiveAnimeRepo(String repo) {
    _box.put("activeAnimeRepo", repo);
    AppLogger.d("Saved Anime Repo: $repo");
  }

  String getActiveMangaRepo() => _box.get("activeMangaRepo", defaultValue: '');
  void saveActiveMangaRepo(String repo) {
    _box.put("activeMangaRepo", repo);
    AppLogger.d("Saved Manga Repo: $repo");
  }

  String getActiveNovelRepo() => _box.get("activeNovelRepo", defaultValue: '');
  void saveActiveNovelRepo(String repo) {
    _box.put("activeNovelRepo", repo);
    AppLogger.d("Saved Novel Repo: $repo");
  }
}

