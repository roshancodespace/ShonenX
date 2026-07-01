import 'package:isar_community/isar.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';

class WatchHistoryRepository {
  final Isar _isar;

  WatchHistoryRepository(this._isar);

  Future<void> saveProgress(WatchHistoryEntry entry) async {
    if (entry.positionInMilliseconds < 5000) return;

    await _isar.writeTxn(() async {
      await _isar.watchHistoryEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() async {
      await _isar.watchHistoryEntrys.delete(id);
    });
  }

  Future<void> deleteByAnimeId(String animeId) async {
    await _isar.writeTxn(() async {
      await _isar.watchHistoryEntrys
          .filter()
          .animeIdEqualTo(animeId)
          .deleteAll();
    });
  }

  Stream<List<WatchHistoryEntry>> watchHistory({int limit = 10}) {
    return _isar.watchHistoryEntrys
        .where()
        .sortByLastUpdatedDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<WatchHistoryEntry>> watchHistoryPerAnime({int limit = 10}) {
    return _isar.watchHistoryEntrys
        .where()
        .sortByLastUpdatedDesc()
        .distinctByAnimeId()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<WatchHistoryEntry>> watchHistoryForAnime(
    String animeId, {
    int limit = 50,
  }) {
    return _isar.watchHistoryEntrys
        .filter()
        .animeIdEqualTo(animeId)
        .sortByLastUpdatedDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }
}
