import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/history/data/history_repository.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final isar = ref.watch(databaseProvider);
  return HistoryRepository(isar);
}, name: 'historyRepositoryProvider');

final historyProvider = StreamProvider.autoDispose
    .family<List<HistoryEntry>, ({String mediaType, int limit})>((ref, args) {
      return ref
          .watch(historyRepositoryProvider)
          .history(args.mediaType, limit: args.limit);
    }, name: 'historyProvider');

final historyPerMediaProvider = StreamProvider.autoDispose
    .family<List<HistoryEntry>, ({String mediaType, int limit})>((ref, args) {
      return ref
          .watch(historyRepositoryProvider)
          .historyPerMedia(args.mediaType, limit: args.limit);
    }, name: 'historyPerMediaProvider');

final historyForMediaProvider = StreamProvider.autoDispose
    .family<List<HistoryEntry>, String>((ref, mediaId) {
      return ref.watch(historyRepositoryProvider).historyForMedia(mediaId);
    }, name: 'historyForMediaProvider');
