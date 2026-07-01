import 'package:isar_community/isar.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';

class ReadHistoryRepository {
  final Isar _isar;

  ReadHistoryRepository(this._isar);

  Future<void> saveProgress(ReadHistoryEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.readHistoryEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() async {
      await _isar.readHistoryEntrys.delete(id);
    });
  }

  Future<void> deleteByMangaId(String mangaId) async {
    await _isar.writeTxn(() async {
      await _isar.readHistoryEntrys
          .filter()
          .mangaIdEqualTo(mangaId)
          .deleteAll();
    });
  }

  Stream<List<ReadHistoryEntry>> readHistory({int limit = 10}) {
    return _isar.readHistoryEntrys
        .where()
        .sortByLastUpdatedDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<ReadHistoryEntry>> readHistoryPerManga({int limit = 10}) {
    return _isar.readHistoryEntrys
        .where()
        .sortByLastUpdatedDesc()
        .distinctByMangaId()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<ReadHistoryEntry>> readHistoryForManga(
    String mangaId, {
    int limit = 50,
  }) {
    return _isar.readHistoryEntrys
        .filter()
        .mangaIdEqualTo(mangaId)
        .sortByLastUpdatedDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }
}
