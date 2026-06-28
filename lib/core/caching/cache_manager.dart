import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/caching/cache_config.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class CacheManager {
  final Isar _isar;
  final CacheConfig cacheConfig;

  late final ScopedLogger _log = AppLogger.scope(CacheManager);

  CacheManager({required Isar isar, required this.cacheConfig}) : _isar = isar {
    _initCleanup();
  }

  Future<void> _initCleanup() async {
    await clearExpired();
    await _enforceMaxCacheSize();
  }

  Future<void> _enforceMaxCacheSize() async {
    final log = _log.child('enforceMaxCacheSize');
    try {
      final maxSize = cacheConfig.maxCacheSize;
      final currentSize = await getCacheSize();
      if (currentSize <= maxSize) {
        return;
      }

      // OPTIMIZATION: Query all cache entries sorted by earliest expiry first, and prune entries until the Isar DB size drops below maxCacheSize. Runs on startup for performance.
      final entries = await _isar.cacheEntrys.where().sortByExpiry().findAll();
      final keysToDelete = <String>[];
      int bytesCleared = 0;

      for (final entry in entries) {
        keysToDelete.add(entry.key);
        bytesCleared += entry.bodyBytes.length;
        if (currentSize - bytesCleared <= maxSize) {
          break;
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _isar.writeTxn(() async {
          for (final key in keysToDelete) {
            await _isar.cacheEntrys.deleteByKey(key);
          }
        });
        log.s(
          'Pruned ${keysToDelete.length} entries, cleared approx $bytesCleared bytes',
        );
      }
    } catch (e, st) {
      log.e('PRUNING FAILED', e, st);
    }
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

  Future<List<CacheEntry>> getAllEntries() async {
    final log = _log.child('getAllEntries');
    try {
      return await _isar.cacheEntrys.where().findAll();
    } catch (e, st) {
      log.e('GET ALL ENTRIES FAILED', e, st);
      return [];
    }
  }

  Future<void> deleteEntriesByCategory(String category) async {
    final log = _log.child('deleteEntriesByCategory');
    try {
      final entries = await getAllEntries();
      final keysToDelete = entries
          .where((e) => getCategoryName(e.key) == category)
          .map((e) => e.key)
          .toList();

      if (keysToDelete.isNotEmpty) {
        await _isar.writeTxn(() async {
          for (final key in keysToDelete) {
            await _isar.cacheEntrys.deleteByKey(key);
          }
        });
        log.s('Deleted ${keysToDelete.length} entries for category: $category');
      }
    } catch (e, st) {
      log.e('DELETE BY CATEGORY FAILED: $category', e, st);
    }
  }

  String getCategoryName(String key) {
    if (key.contains('/api/anime/search')) return 'Search Queries';
    if (key.contains('/api/anime/eps/')) return 'Episode Metadata';
    if (key.contains('/api/anime/servers/')) return 'Server Lists';
    if (key.contains('/api/anime/oppai/')) return 'Stream Sources';
    return 'General / Others';
  }
}

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final isar = ref.watch(databaseProvider);
  final cacheConfig = ref.watch(cacheConfigProvider);

  return CacheManager(isar: isar, cacheConfig: cacheConfig);
});
