import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/caching/cache_config.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class CacheManager {
  late final Isar _isar;
  late final CacheConfig _cacheConfig;

  late final ScopedLogger _log = AppLogger.scope(CacheManager);

  CacheManager({required Isar isar, required CacheConfig cacheConfig}) {
    _isar = isar;
    _cacheConfig = cacheConfig;
    clearExpired();
  }

  Future<CacheEntry?> get(String key) async {
    final log = _log.child('get');

    try {
      final entry = await _isar.cacheEntrys.getByKey(key);

      if (entry == null) {
        log.v('MISS: $key');
        return null;
      }

      if (entry.expiry.isBefore(DateTime.now())) {
        log.i('EXPIRED: $key → deleting');
        await delete(key);
        return null;
      }

      log.s('HIT: $key');
      return entry;
    } catch (e, st) {
      log.e('READ FAILED: $key', e, st);
      return null;
    }
  }

  Future<void> put(String key, CacheEntry entry, Duration cacheDuration) async {
    final log = _log.child('put');

    try {
      entry.expiry = DateTime.now().add(cacheDuration);

      await _isar.writeTxn(() async {
        await _isar.cacheEntrys.put(entry);
      });

      log.s('STORED: $key (ttl: ${cacheDuration.inMinutes}m)');
    } catch (e, st) {
      log.e('WRITE FAILED: $key', e, st);
    }
  }

  Future<void> delete(String key) async {
    final log = _log.child('delete');

    try {
      await _isar.writeTxn(() async {
        await _isar.cacheEntrys.deleteByKey(key);
      });

      log.s('DELETED: $key');
    } catch (e, st) {
      log.e('DELETE FAILED: $key', e, st);
    }
  }

  Future<void> clearExpired() async {
    final log = _log.child('clearExpired');

    try {
      log.w('Cleanup started');

      final now = DateTime.now();

      await _isar.writeTxn(() async {
        final count = await _isar.cacheEntrys
            .filter()
            .expiryLessThan(now)
            .deleteAll();

        log.s('Cleanup done → removed $count');
      });
    } catch (e, st) {
      log.e('CLEANUP FAILED', e, st);
    }
  }

  Future<int> getCacheSize() async {
    final log = _log.child('getCacheSize');

    try {
      return await _isar.cacheEntrys.getSize();
    } catch (e, st) {
      log.e('SIZE FAILED', e, st);
      return 0;
    }
  }

  Future<void> clearCache() async {
    final log = _log.child('clearCache');

    try {
      log.w('Clearing cache');

      await _isar.writeTxn(() async {
        await _isar.cacheEntrys.clear();
      });

      log.s('Cache cleared');
    } catch (e, st) {
      log.e('CLEAR FAILED', e, st);
    }
  }
}

// ---------------- Provider ----------------

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final isar = ref.watch(databaseProvider);
  final cacheConfig = ref.watch(cacheConfigProvider);

  return CacheManager(isar: isar, cacheConfig: cacheConfig);
});
