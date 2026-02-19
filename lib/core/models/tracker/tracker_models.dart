enum TrackerType { anilist, mal }

extension TrackerTypeName on TrackerType {
  String get displayName {
    switch (this) {
      case TrackerType.anilist:
        return 'AniList';
      case TrackerType.mal:
        return 'MyAnimeList';
    }
  }

  String get shortName {
    switch (this) {
      case TrackerType.anilist:
        return 'AL';
      case TrackerType.mal:
        return 'MAL';
    }
  }
}

class TrackerStatus {
  static const String watching = 'CURRENT';
  static const String completed = 'COMPLETED';
  static const String planned = 'PLANNING';
  static const String dropped = 'DROPPED';
  static const String onHold = 'PAUSED';
  static const String repeating = 'REPEATING';

  static const List<String> all = [
    watching,
    completed,
    planned,
    dropped,
    onHold,
    repeating,
  ];

  static String displayName(String status) {
    switch (status) {
      case watching:
        return 'Watching';
      case completed:
        return 'Completed';
      case planned:
        return 'Plan to Watch';
      case dropped:
        return 'Dropped';
      case onHold:
        return 'On Hold';
      case repeating:
        return 'Rewatching';
      default:
        return status;
    }
  }
}

class TrackerSearchResult {
  final int remoteId;
  final String title;
  final String? imageUrl;
  final String? format;
  final int? episodes;
  final String? status;
  final double? score;
  final int? year;

  const TrackerSearchResult({
    required this.remoteId,
    required this.title,
    this.imageUrl,
    this.format,
    this.episodes,
    this.status,
    this.score,
    this.year,
  });
}

class TrackerEntry {
  final TrackerType tracker;
  final int remoteId;
  final String status;
  final int progress;
  final double score;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? title;
  final String? imageUrl;
  final int? totalEpisodes;

  const TrackerEntry({
    required this.tracker,
    required this.remoteId,
    required this.status,
    this.progress = 0,
    this.score = 0,
    this.startDate,
    this.endDate,
    this.title,
    this.imageUrl,
    this.totalEpisodes,
  });

  TrackerEntry copyWith({
    String? status,
    int? progress,
    double? score,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TrackerEntry(
      tracker: tracker,
      remoteId: remoteId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      score: score ?? this.score,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      title: title,
      imageUrl: imageUrl,
      totalEpisodes: totalEpisodes,
    );
  }
}
