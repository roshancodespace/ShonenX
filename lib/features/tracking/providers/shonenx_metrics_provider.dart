import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';

class ShonenxLocalMetrics {
  final int streamedSessions;
  final double hoursWatched;
  final int uniqueSeriesTracked;
  final int chaptersRead;

  const ShonenxLocalMetrics({
    required this.streamedSessions,
    required this.hoursWatched,
    required this.uniqueSeriesTracked,
    required this.chaptersRead,
  });
}

final shonenxLocalMetricsProvider =
    FutureProvider.autoDispose<ShonenxLocalMetrics>((ref) async {
      final isar = ref.watch(databaseProvider);
      final watchEntries = await isar.watchHistoryEntrys.where().findAll();
      final readCount = await isar.readHistoryEntrys.count();

      final totalMillis = watchEntries.fold<int>(
        0,
        (prev, e) => prev + e.positionInMilliseconds,
      );
      final uniqueSeries = watchEntries.map((e) => e.animeId).toSet().length;

      return ShonenxLocalMetrics(
        streamedSessions: watchEntries.length,
        hoursWatched: totalMillis / 3600000.0,
        uniqueSeriesTracked: uniqueSeries,
        chaptersRead: readCount,
      );
    }, name: 'shonenxLocalMetricsProvider');
