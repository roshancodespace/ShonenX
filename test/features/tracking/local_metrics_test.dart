import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/tracking/providers/shonenx_metrics_provider.dart';

HistoryEntry historyEntryWithType(String mediaType) =>
    HistoryEntry()..mediaType = mediaType;

void main() {
  group('isWatchHistoryEntry', () {
    test('the stored lowercase anime id classifies as a watch entry', () {
      expect(isWatchHistoryEntry(historyEntryWithType('anime')), isTrue);
    });

    test('manga, novel, tv, movie and empty types classify as read entries', () {
      for (final type in const <String>['manga', 'novel', 'tv', 'movie', '']) {
        expect(
          isWatchHistoryEntry(historyEntryWithType(type)),
          isFalse,
          reason: 'stored type "$type" is not a watch entry',
        );
      }
    });

    test('an uppercase ANIME string is not treated as a watch entry', () {
      expect(isWatchHistoryEntry(historyEntryWithType('ANIME')), isFalse);
    });
  });
}
