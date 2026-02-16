import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';

class CacheStorageService {
  static const String _boxName = 'http_cache_v1';
  
  CacheStorageService._();
  static final CacheStorageService instance = CacheStorageService._();

  Box? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  Future<Map<dynamic, dynamic>?> get(String key) async {
    await _initIfNeeded();
    return _box!.get(key);
  }

  Future<void> put({
    required String key,
    required http.Response response,
    required Duration duration,
  }) async {
    await _initIfNeeded();
    
    final entry = {
      'body': response.body,
      'statusCode': response.statusCode,
      'headers': response.headers,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
    };
    
    await _box!.put(key, entry);
  }

  Future<void> delete(String key) async {
    await _initIfNeeded();
    await _box!.delete(key);
  }

  Future<void> clearAll() async {
    await _initIfNeeded();
    await _box!.clear();
  }

  /// Removes all entries where the duration has passed
  Future<void> clearExpired() async {
    await _initIfNeeded();
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];

    for (final key in _box!.keys) {
      final cachedData = _box!.get(key);
      if (cachedData == null) continue;

      final int? timestamp = cachedData['ts'];
      final int? durationMs = cachedData['duration'];

      if (timestamp == null || durationMs == null) {
        keysToDelete.add(key);
        continue;
      }

      if ((now - timestamp) > durationMs) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _box!.deleteAll(keysToDelete);
      AppLogger.w('[CACHE CLEANUP] Removed ${keysToDelete.length} expired entries');
    }
  }

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }

  Future<void> _initIfNeeded() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
}