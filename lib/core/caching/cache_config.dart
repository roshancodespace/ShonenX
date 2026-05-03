import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/storage_provider.dart';

class CacheConfig {
  final int? maxCacheSize;

  const CacheConfig({this.maxCacheSize = 1024 * 1024 * 1024});

  CacheConfig copyWith({int? maxCacheSize}) {
    return CacheConfig(maxCacheSize: maxCacheSize ?? this.maxCacheSize);
  }

  factory CacheConfig.fromMap(Map<String, dynamic> map) {
    return CacheConfig(maxCacheSize: map['maxCacheSize'] as int?);
  }

  Map<String, dynamic> toMap() {
    return {'maxCacheSize': maxCacheSize};
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
      return CacheConfig.fromJson(jsonDecode(json));
    }
    return const CacheConfig();
  }

  void setMaxCacheSize(int maxCacheSize) {
    state = CacheConfig(maxCacheSize: maxCacheSize);
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
