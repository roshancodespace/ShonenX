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

  Future<void> deleteByAnimeIds(List<String> animeIds) async {
    if (animeIds.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final animeId in animeIds) {
        await _isar.watchHistoryEntrys
            .filter()
            .animeIdEqualTo(animeId)
            .deleteAll();
      }
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
    String? animeIdMal,
    int? limit,
  }) {
    var query = _isar.watchHistoryEntrys.filter().group((q) {
      var inner = q.animeIdEqualTo(animeId);
      if (animeIdMal != null && animeIdMal.isNotEmpty) {
        inner = inner.or().animeIdMalEqualTo(animeIdMal);
      }
      return inner;
    }).sortByEpisodeNumberAsc();

    if (limit != null && limit > 0) {
      return query.limit(limit).watch(fireImmediately: true);
    }
    return query.watch(fireImmediately: true);
  }
}
