enum SkipMode { off, manual, auto }

enum SkipType { intro, recap, outro, opening, ending }

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
      SkipType.intro: SkipMode.auto,
      SkipType.recap: SkipMode.auto,
      SkipType.outro: SkipMode.auto,
      SkipType.opening: SkipMode.auto,
      SkipType.ending: SkipMode.auto,
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
}
