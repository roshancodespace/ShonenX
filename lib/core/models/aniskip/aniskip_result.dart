class AniSkipInterval {
  final double startTime;
  final double endTime;

  const AniSkipInterval({
    required this.startTime,
    required this.endTime,
  });

  factory AniSkipInterval.fromJson(Map<String, dynamic> json) {
    return AniSkipInterval(
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }
}

enum SkipType {
  op,
  ed,
  mixed,
  recap,
  unknown,
}

class AniSkipResultItem {
  final AniSkipInterval? interval;
  final SkipType skipType;
  final String action;
  final double episodeLength;
  final String? skipId;

  const AniSkipResultItem({
    this.interval,
    required this.skipType,
    required this.action,
    required this.episodeLength,
    this.skipId,
  });

  factory AniSkipResultItem.fromJson(Map<String, dynamic> json) {
    SkipType type;
    switch (json['skipType']) {
      case 'op':
        type = SkipType.op;
        break;
      case 'ed':
        type = SkipType.ed;
        break;
      case 'mixed-op':
      case 'mixed-ed':
        type = SkipType.mixed;
        break;
      case 'recap':
        type = SkipType.recap;
        break;
      default:
        type = SkipType.unknown;
    }

    return AniSkipResultItem(
      interval: json['interval'] != null
          ? AniSkipInterval.fromJson(json['interval'])
          : null,
      skipType: type,
      action: json['action'] ?? 'skip',
      episodeLength: (json['episodeLength'] as num? ?? 0).toDouble(),
      skipId: json['skipId'],
    );
  }
}

class AniSkipResponse {
  final bool found;
  final List<AniSkipResultItem> results;

  const AniSkipResponse({
    required this.found,
    required this.results,
  });

  factory AniSkipResponse.fromJson(Map<String, dynamic> json) {
    return AniSkipResponse(
      found: json['found'] ?? false,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => AniSkipResultItem.fromJson(e))
          .toList(),
    );
  }
}
