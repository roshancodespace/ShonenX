import 'dart:io';

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

  static const int _oneMb = 1024 * 1024; // 1 MB threshold for gzip compression

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
      int usedSize = await getCacheSize();

      if (usedSize <= maxSize) return;

      int deletedEntries = 0;
      int bytesCleared = 0;

      while (usedSize > maxSize) {
        final entries = await _isar.cacheEntrys
            .where()
            .sortByExpiry()
            .limit(100)
            .findAll();

        if (entries.isEmpty) break;

        final keysToDelete = <String>[];
        int batchBytes = 0;

        for (final entry in entries) {
          keysToDelete.add(entry.key);
          batchBytes += entry.bodyBytes.length;

          if (usedSize - batchBytes <= maxSize) break;
        }

        await _isar.writeTxn(() async {
          for (final key in keysToDelete) {
            await _isar.cacheEntrys.deleteByKey(key);
          }
        });

        deletedEntries += keysToDelete.length;
        bytesCleared += batchBytes;
        usedSize -= batchBytes;
      }

      if (deletedEntries > 0) {
        log.s(
          'Pruned $deletedEntries entries, cleared approx $bytesCleared bytes',
        );
      }
    } catch (e, st) {
      log.e('PRUNING FAILED', e, st);
    }
  }

  Future<CacheEntry?> get(String key, {bool suppressLogs = false}) async {
    final log = _log.child('get');

    try {
      final entry = await _isar.cacheEntrys.getByKey(key);

      if (entry == null) {
        if (!suppressLogs) log.v('MISS: $key');
        return null;
      }

      if (entry.expiry.isBefore(DateTime.now())) {
        if (!suppressLogs) log.i('EXPIRED: $key → deleting');
        await delete(key, suppressLogs: suppressLogs);
        return null;
      }

      entry.bodyBytes = _decompressIfNeeded(entry.bodyBytes);

      if (!suppressLogs) log.s('HIT: $key');
      return entry;
    } catch (e, st) {
      if (!suppressLogs) log.e('READ FAILED: $key', e, st);
      return null;
    }
  }

  Future<void> put(
    CacheEntry entry,
    Duration cacheDuration, {
    bool suppressLogs = false,
  }) async {
    final log = _log.child('put');

    try {
      entry.expiry = DateTime.now().add(cacheDuration);

      if (entry.bodyBytes.length > _oneMb) {
        if (!suppressLogs)
          log.v(
            'Compressing bodyBytes (${entry.bodyBytes.length} bytes) with gzip: ${entry.key}',
          );
        entry.bodyBytes = gzip.encode(entry.bodyBytes);
      }

      await _isar.writeTxn(() async {
        await _isar.cacheEntrys.put(entry);
      });

      if (!suppressLogs)
        log.s('STORED: ${entry.key} (ttl: ${cacheDuration.inMinutes}m)');
    } catch (e, st) {
      if (!suppressLogs) log.e('WRITE FAILED: ${entry.key}', e, st);
    }
  }

  bool _isGzip(List<int> bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0x1F &&
        bytes[1] == 0x8B &&
        bytes[2] == 0x08;
  }

  List<int> _decompressIfNeeded(List<int> bytes) {
    if (_isGzip(bytes)) {
      try {
        return gzip.decode(bytes);
      } catch (e, st) {
        _log.child('decompress').w('Failed to decompress gzip bytes', e, st);
        return bytes;
      }
    }
    return bytes;
  }

  Future<void> delete(String key, {bool suppressLogs = false}) async {
    final log = _log.child('delete');

    try {
      await _isar.writeTxn(() async {
        await _isar.cacheEntrys.deleteByKey(key);
      });

      if (!suppressLogs) log.s('DELETED: $key');
    } catch (e, st) {
      if (!suppressLogs) log.e('DELETE FAILED: $key', e, st);
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
    if (key.contains('search')) return 'Search Queries';
    if (key.contains('episode')) return 'Episode Metadata';
    if (key.contains('server')) return 'Server Lists';
    if (key.contains('source')) return 'Stream Sources';
    return 'General / Others';
  }
}

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final isar = ref.watch(databaseProvider);
  final cacheConfig = ref.watch(cacheConfigProvider);

  return CacheManager(isar: isar, cacheConfig: cacheConfig);
});
