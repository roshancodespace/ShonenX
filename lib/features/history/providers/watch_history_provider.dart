import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/features/history/data/watch_history_repository.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  final isar = ref.watch(databaseProvider);
  return WatchHistoryRepository(isar);
}, name: 'watchHistoryRepositoryProvider');

final continueWatchingProvider =
    StreamProvider.autoDispose<List<WatchHistoryEntry>>((ref) {
      return ref.watch(watchHistoryRepositoryProvider).watchHistory();
    }, name: 'continueWatchingProvider');
