import 'dart:convert';

class ExoPlayerPrefs {
  final bool useCache;
  final int bufferCapacityMs;
  final bool hwAcceleration;

  const ExoPlayerPrefs({
    this.useCache = true,
    this.bufferCapacityMs = 15000,
    this.hwAcceleration = true,
  });

  ExoPlayerPrefs copyWith({
    bool? useCache,
    int? bufferCapacityMs,
    bool? hwAcceleration,
  }) {
    return ExoPlayerPrefs(
      useCache: useCache ?? this.useCache,
      bufferCapacityMs: bufferCapacityMs ?? this.bufferCapacityMs,
      hwAcceleration: hwAcceleration ?? this.hwAcceleration,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExoPlayerPrefs &&
            other.useCache == useCache &&
            other.bufferCapacityMs == bufferCapacityMs &&
            other.hwAcceleration == hwAcceleration);
  }

  @override
  int get hashCode => Object.hash(useCache, bufferCapacityMs, hwAcceleration);

  factory ExoPlayerPrefs.fromMap(Map<String, dynamic> map) {
    return ExoPlayerPrefs(
      useCache: map['useCache'] ?? true,
      bufferCapacityMs: map['bufferCapacityMs'] ?? 15000,
      hwAcceleration: map['hwAcceleration'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useCache': useCache,
      'bufferCapacityMs': bufferCapacityMs,
      'hwAcceleration': hwAcceleration,
    };
  }

  factory ExoPlayerPrefs.fromJson(String source) =>
      ExoPlayerPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
