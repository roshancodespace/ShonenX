enum SkipMode { off, manual, auto }

enum SkipType {
  opening,
  ending,
  mixedOpening,
  mixedEnding,
  recap;

  String get apiID {
    switch (this) {
      case SkipType.opening:
        return 'op';
      case SkipType.ending:
        return 'ed';
      case SkipType.mixedOpening:
        return 'mixed-op';
      case SkipType.mixedEnding:
        return 'mixed-ed';
      case SkipType.recap:
        return 'recap';
    }
  }
}

class AniSkipStamp {
  final SkipType type;
  final double startTime;
  final double endTime;

  const AniSkipStamp({
    required this.type,
    required this.startTime,
    required this.endTime,
  });
}

class AniSkipPrefs {
  final Map<SkipType, SkipMode> segments;

  const AniSkipPrefs({
    this.segments = const {
      SkipType.opening: SkipMode.auto,
      SkipType.ending: SkipMode.auto,
      SkipType.mixedOpening: SkipMode.auto,
      SkipType.mixedEnding: SkipMode.auto,
      SkipType.recap: SkipMode.auto,
    },
  });

  AniSkipPrefs copyWith({Map<SkipType, SkipMode>? segments}) {
    return AniSkipPrefs(segments: segments ?? this.segments);
  }

  SkipMode mode(SkipType segment) => segments[segment] ?? SkipMode.manual;

  AniSkipPrefs updateSegment(SkipType segment, SkipMode mode) {
    return copyWith(segments: {...segments, segment: mode});
  }

  factory AniSkipPrefs.fromMap(Map<String, dynamic> map) {
    final raw = map['segments'] as Map<String, dynamic>? ?? {};

    return AniSkipPrefs(
      segments: raw.map(
        (key, value) => MapEntry(
          SkipType.values.byName(key),
          SkipMode.values.byName(value),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'segments': segments.map((key, value) => MapEntry(key.name, value.name)),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory AniSkipPrefs.fromJson(Map<String, dynamic> json) {
    return AniSkipPrefs.fromMap(json);
  }

  List<SkipType> enabledTypes() {
    return segments.entries
        .where((entry) => entry.value != SkipMode.off)
        .map((entry) => entry.key)
        .toList();
  }
}
