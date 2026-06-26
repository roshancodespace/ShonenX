class TrackerProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final String? profileUrl;
  final int? animeCount;
  final int? episodesWatched;
  final int? minutesWatched;
  final double? meanScore;
  final int? mangaCount;
  final int? chaptersRead;
  final Map<String, int>? statusCounts;
  final DateTime? lastSyncedAt;
  final List<String>? favorites;

  const TrackerProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.profileUrl,
    this.animeCount,
    this.episodesWatched,
    this.minutesWatched,
    this.meanScore,
    this.mangaCount,
    this.chaptersRead,
    this.statusCounts,
    this.lastSyncedAt,
    this.favorites,
  });

  TrackerProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? profileUrl,
    int? animeCount,
    int? episodesWatched,
    int? minutesWatched,
    double? meanScore,
    int? mangaCount,
    int? chaptersRead,
    Map<String, int>? statusCounts,
    DateTime? lastSyncedAt,
    List<String>? favorites,
  }) {
    return TrackerProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      profileUrl: profileUrl ?? this.profileUrl,
      animeCount: animeCount ?? this.animeCount,
      episodesWatched: episodesWatched ?? this.episodesWatched,
      minutesWatched: minutesWatched ?? this.minutesWatched,
      meanScore: meanScore ?? this.meanScore,
      mangaCount: mangaCount ?? this.mangaCount,
      chaptersRead: chaptersRead ?? this.chaptersRead,
      statusCounts: statusCounts ?? this.statusCounts,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      favorites: favorites ?? this.favorites,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'bio': bio,
      'profileUrl': profileUrl,
      'animeCount': animeCount,
      'episodesWatched': episodesWatched,
      'minutesWatched': minutesWatched,
      'meanScore': meanScore,
      'mangaCount': mangaCount,
      'chaptersRead': chaptersRead,
      'statusCounts': statusCounts,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'favorites': favorites,
    };
  }

  factory TrackerProfile.fromMap(Map<String, dynamic> map) {
    return TrackerProfile(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? 'Unknown',
      avatarUrl: map['avatarUrl']?.toString(),
      bannerUrl: map['bannerUrl']?.toString(),
      bio: map['bio']?.toString(),
      profileUrl: map['profileUrl']?.toString(),
      animeCount: (map['animeCount'] as num?)?.toInt(),
      episodesWatched: (map['episodesWatched'] as num?)?.toInt(),
      minutesWatched: (map['minutesWatched'] as num?)?.toInt(),
      meanScore: (map['meanScore'] as num?)?.toDouble(),
      mangaCount: (map['mangaCount'] as num?)?.toInt(),
      chaptersRead: (map['chaptersRead'] as num?)?.toInt(),
      statusCounts: map['statusCounts'] != null
          ? Map<String, int>.from(map['statusCounts'] as Map)
          : null,
      lastSyncedAt: DateTime.tryParse(map['lastSyncedAt']?.toString() ?? ''),
      favorites: (map['favorites'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
