import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/history/data/read_history_repository.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';

final readHistoryRepositoryProvider = Provider<ReadHistoryRepository>((ref) {
  final isar = ref.watch(databaseProvider);
  return ReadHistoryRepository(isar);
}, name: 'readHistoryRepositoryProvider');

final continueReadingProvider = StreamProvider.autoDispose
    .family<List<ReadHistoryEntry>, int>((ref, limit) {
      return ref
          .watch(readHistoryRepositoryProvider)
          .readHistory(limit: limit);
    }, name: 'continueReadingProvider');

final continueReadingPerMangaProvider = StreamProvider.autoDispose
    .family<List<ReadHistoryEntry>, int>((ref, limit) {
      return ref
          .watch(readHistoryRepositoryProvider)
          .readHistoryPerManga(limit: limit);
    }, name: 'continueReadingPerMangaProvider');

final historyChaptersProvider = StreamProvider.autoDispose
    .family<List<ReadHistoryEntry>, String>((ref, mangaId) {
      return ref
          .watch(readHistoryRepositoryProvider)
          .readHistoryForManga(mangaId);
    }, name: 'historyChaptersProvider');
