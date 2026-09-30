import 'dart:math' as math;

class DnsCacheEntry {
  final List<String> addresses;
  final DateTime expiresAt;

  DnsCacheEntry(this.addresses, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DohCache {
  static const int minTtlSeconds = 60;
  static const int maxTtlSeconds = 3600;
  static const int defaultTtlSeconds = 300;

  final Map<String, DnsCacheEntry> _cache = {};

  List<String>? get(String host) {
    final entry = _cache[host];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(host);
      return null;
    }
    return entry.addresses;
  }

  void put(String host, List<String> addresses, {int? ttlSeconds}) {
    if (addresses.isEmpty) return;
    final effectiveTtl = math.max(
      minTtlSeconds,
      math.min(maxTtlSeconds, ttlSeconds ?? defaultTtlSeconds),
    );
    _cache[host] = DnsCacheEntry(
      List.unmodifiable(addresses),
      DateTime.now().add(Duration(seconds: effectiveTtl)),
    );
  }

  void remove(String host) {
    _cache.remove(host);
  }

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;

  void pruneExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }
}
