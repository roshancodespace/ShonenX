import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';

class CacheStorageService {
  static const String _boxName = 'http_cache_v1';
  
  CacheStorageService._();
  static final CacheStorageService instance = CacheStorageService._();

  Box? _box;

  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox(_boxName);
  }

  Future<void> _ensureOpen() async {
    if (_box == null || !_box!.isOpen) await init();
  }

  Future<Map<dynamic, dynamic>?> get(String key) async {
    await _ensureOpen();
    return _box!.get(key) as Map<dynamic, dynamic>?;
  }

  Future<void> put({
    required String key,
    required http.Response response,
    required Duration duration,
  }) async {
    await _ensureOpen();
    await _box!.put(key, {
      'body': response.body,
      'statusCode': response.statusCode,
      'headers': response.headers,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
    });
  }

  Future<void> delete(String key) async {
    await _ensureOpen();
    await _box!.delete(key);
  }

  Future<void> clearAll() async {
    await _ensureOpen();
    await _box!.clear();
  }

  Future<void> clearExpired() async {
    await _ensureOpen();
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];

    for (final entry in _box!.toMap().entries) {
      final data = entry.value as Map<dynamic, dynamic>?;
      
      if (data == null || data['ts'] == null || data['duration'] == null) {
        keysToDelete.add(entry.key);
        continue;
      }

      if ((now - (data['ts'] as int)) > (data['duration'] as int)) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _box!.deleteAll(keysToDelete);
      AppLogger.d('[CACHE CLEANUP] Removed ${keysToDelete.length} expired entries');
    }
  }

  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
    }
  }
}