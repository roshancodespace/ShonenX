import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';

void main() {
  group('BackupManifest and Deserialization Resilience Tests', () {
    test('1. UTF-8 BOM at start of JSON', () {
      const jsonWithBom =
          '\uFEFF{"appVersion":"2.0.0","categories":["library"],"data":{"library":[]}}';
      expect(() => BackupManifest.fromJson(jsonWithBom), returnsNormally);
    });

    test('2. Missing categories in JSON (legacy or corrupted)', () {
      const jsonWithoutCategories =
          '{"appVersion":"2.0.0","data":{"library":[],"history":[]}}';
      final manifest = BackupManifest.fromJson(jsonWithoutCategories);
      expect(manifest.categories.isNotEmpty, isTrue);
      expect(manifest.categories.contains(BackupCategory.library), isTrue);
      expect(manifest.categories.contains(BackupCategory.history), isTrue);
    });

    test('3. Data placed at root level instead of under "data" key', () {
      const jsonRootData =
          '{"appVersion":"2.0.0","library":[{"providerId":"1","title":"Test","cover":"img"}],"categories":["library"]}';
      final manifest = BackupManifest.fromJson(jsonRootData);
      expect(manifest.data.containsKey('library'), isTrue);
      expect(manifest.countFor(BackupCategory.library), equals(1));
    });

    test('4. Double-encoded JSON data string', () {
      const jsonDoubleEncoded =
          '{"appVersion":"2.0.0","categories":["library"],"data":"{\\"library\\":[{\\"providerId\\":\\"1\\",\\"title\\":\\"Test\\",\\"cover\\":\\"img\\"}]}"}';
      final manifest = BackupManifest.fromJson(jsonDoubleEncoded);
      expect(manifest.data.containsKey('library'), isTrue);
    });

    test('5. Legacy v1 Hive format with watchlist and settings', () {
      const legacyHive =
          '{"version":1,"timestamp":"2026-01-01T00:00:00","data":{"watchlist":{"1":{"animeId":"1","title":"Naruto","cover":"c"}}}}';
      final manifest = BackupManifest.fromJson(legacyHive);
      expect(manifest.categories.contains(BackupCategory.library), isTrue);
      expect(manifest.countFor(BackupCategory.library), equals(1));
    });

    test('6. Legacy AnymeX format with animeLibrary and mangaLibrary', () {
      const anymexJson =
          '{"date":"01 01 2026 12:00 PM","animeLibrary":[{"mediaId":"10","title":{"english":"Bleach"},"coverImage":"img"}],"settings":[]}';
      final manifest = BackupManifest.fromJson(anymexJson);
      expect(manifest.categories.contains(BackupCategory.library), isTrue);
      expect(manifest.countFor(BackupCategory.library), equals(1));
    });

    test(
      '7. CountFor legacy watchHistory and readHistory in history category',
      () {
        const legacyHistory =
            '{"appVersion":"2.0.0","categories":["watchHistory","readHistory"],"data":{"watchHistory":[{"animeId":"1"}],"readHistory":[{"mangaId":"2"}]}}';
        final manifest = BackupManifest.fromJson(legacyHistory);
        expect(manifest.countFor(BackupCategory.history), equals(2));
      },
    );

    test(
      '8. LibraryEntry.fromBackupMap with int id, null cover, string episodes',
      () {
        final map = {
          'providerId': 12345, // int instead of String!
          'title': 'One Piece',
          'cover': null, // null cover!
          'episodes': '1000', // string instead of int!
          'score': '8.5', // string instead of double!
        };
        final entry = LibraryEntry.fromBackupMap(map);
        expect(entry.providerId, equals('12345'));
        expect(entry.cover, equals(''));
        expect(entry.episodes, equals(1000));
        expect(entry.score, equals(8.5));
      },
    );

    test('9. HistoryEntry.fromBackupMap with old field names and nulls', () {
      final map = {
        'animeId': 999, // old field and int!
        'episodeNumber': '12', // old field and string!
        'animeTitle': 'Death Note', // old field!
        'positionInMilliseconds': '150000', // old field in ms as string!
        'durationInMilliseconds': 300000, // old field in ms!
      };
      final entry = HistoryEntry.fromBackupMap(map);
      expect(entry.mediaId, equals('999'));
      expect(entry.mediaTitle, equals('Death Note'));
      expect(entry.itemNumber, equals(12.0));
      expect(entry.progress, equals(150)); // converted to seconds!
      expect(entry.total, equals(300)); // converted to seconds!
    });

    test('10. Trailing comma recovery in JSON', () {
      const brokenJson =
          '{"appVersion":"2.0.0", "categories":["library",], "data":{"library":[],},}';
      final manifest = BackupManifest.fromJson(brokenJson);
      expect(manifest.categories.contains(BackupCategory.library), isTrue);
    });
  });
}
