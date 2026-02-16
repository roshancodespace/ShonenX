import 'package:flutter/foundation.dart';

@immutable
class CacheConfig {
  final Duration? duration;
  final bool forceRefresh;
  final String? customKey;

  const CacheConfig({
    this.duration,
    this.forceRefresh = false,
    this.customKey,
  });

  CacheConfig copyWith({
    Duration? duration,
    bool? forceRefresh,
    String? customKey,
  }) {
    return CacheConfig(
      duration: duration ?? this.duration,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      customKey: customKey ?? this.customKey,
    );
  }

  // Pre-defined configurations
  static const CacheConfig short = CacheConfig(duration: Duration(minutes: 5));
  static const CacheConfig medium = CacheConfig(duration: Duration(hours: 1));
  static const CacheConfig long = CacheConfig(duration: Duration(days: 1));
  static const CacheConfig veryLong = CacheConfig(duration: Duration(days: 7));
  static const CacheConfig month = CacheConfig(duration: Duration(days: 30));
  static const CacheConfig year = CacheConfig(duration: Duration(days: 365));
  static const CacheConfig infinite = CacheConfig(duration: Duration(days: 3650));
  
  // No cache configuration
  static const CacheConfig none = CacheConfig(duration: null);
}