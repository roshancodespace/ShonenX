import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class CacheConfig {
  final int maxCacheSize;
  final bool enableCaching;
  final bool bypassCache;

  const CacheConfig({
    this.maxCacheSize = 1024 * 1024 * 1024,
    this.enableCaching = true,
    this.bypassCache = false,
  });

  CacheConfig copyWith({
    int? maxCacheSize,
    bool? enableCaching,
    bool? bypassCache,
  }) {
    return CacheConfig(
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      enableCaching: enableCaching ?? this.enableCaching,
      bypassCache: bypassCache ?? this.bypassCache,
    );
  }

  factory CacheConfig.fromMap(Map<String, dynamic> map) {
    return CacheConfig(
      maxCacheSize: map['maxCacheSize'] as int? ?? 1024 * 1024 * 1024,
      enableCaching: map['enableCaching'] as bool? ?? true,
      bypassCache: map['bypassCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxCacheSize': maxCacheSize,
      'enableCaching': enableCaching,
      'bypassCache': bypassCache,
    };
  }

  factory CacheConfig.fromJson(Map<String, dynamic> json) =>
      CacheConfig.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

class CacheConfigNotifier extends Notifier<CacheConfig> {
  static const _key = 'cache_config';
  Timer? _debounce;

  @override
  CacheConfig build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        return CacheConfig.fromJson(jsonDecode(json));
      } catch (_) {}
    }
    return const CacheConfig();
  }

  void setMaxCacheSize(int maxCacheSize) {
    state = state.copyWith(maxCacheSize: maxCacheSize);
    _saveDb();
  }

  void setEnableCaching(bool enableCaching) {
    state = state.copyWith(enableCaching: enableCaching);
    _saveDb();
  }

  void setBypassCache(bool bypassCache) {
    state = state.copyWith(bypassCache: bypassCache);
    _saveDb();
  }

  void _saveDb() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final prefs = ref.read(sharedPreferencesProvider);
      final newValue = jsonEncode(state.toJson());

      if (prefs.getString(_key) != newValue) {
        prefs.setString(_key, newValue);
      }
    });
  }
}

final cacheConfigProvider = NotifierProvider<CacheConfigNotifier, CacheConfig>(
  CacheConfigNotifier.new,
);
