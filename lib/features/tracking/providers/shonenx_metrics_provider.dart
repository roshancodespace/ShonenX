import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/shared/models/unified_media.dart';

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
      final entries = await isar.historyEntrys.where().findAll();
      final watchEntries = entries
          .where((e) => e.mediaType == MediaType.ANIME)
          .toList();
      final readCount = entries
          .where((e) => e.mediaType != MediaType.ANIME)
          .length;

      final totalMillis = watchEntries.fold<double>(
        0.0,
        (prev, e) => prev + e.progress,
      );
      final uniqueSeries = watchEntries.map((e) => e.mediaId).toSet().length;

      return ShonenxLocalMetrics(
        streamedSessions: watchEntries.length,
        hoursWatched: totalMillis / 3600000.0,
        uniqueSeriesTracked: uniqueSeries,
        chaptersRead: readCount,
      );
    }, name: 'shonenxLocalMetricsProvider');
