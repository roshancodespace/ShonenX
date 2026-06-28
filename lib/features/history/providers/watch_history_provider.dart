import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/history/data/watch_history_repository.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  final isar = ref.watch(databaseProvider);
  return WatchHistoryRepository(isar);
}, name: 'watchHistoryRepositoryProvider');

final continueWatchingProvider = StreamProvider.autoDispose
    .family<List<WatchHistoryEntry>, int>((ref, limit) {
      return ref
          .watch(watchHistoryRepositoryProvider)
          .watchHistory(limit: limit);
    }, name: 'continueWatchingProvider');

final continueWatchingPerAnimeProvider = StreamProvider.autoDispose
    .family<List<WatchHistoryEntry>, int>((ref, limit) {
      return ref
          .watch(watchHistoryRepositoryProvider)
          .watchHistoryPerAnime(limit: limit);
    }, name: 'continueWatchingPerAnimeProvider');

final historyEpisodesProvider = StreamProvider.autoDispose
    .family<List<WatchHistoryEntry>, String>((ref, animeId) {
      return ref
          .watch(watchHistoryRepositoryProvider)
          .watchHistoryForAnime(animeId);
    }, name: 'historyEpisodesProvider');
