import 'dart:convert';
import 'package:shonenx/shared/models/unified_media.dart';

class LikedAnime {
  final String id;
  final String title;
  final String? cover;
  final String? banner;
  final List<String> genres;
  final List<String> tags;
  final String? format;
  final double? score;
  final String? season;
  final MediaType type;
  final DateTime likedAt;
  final String? providerId;
  final String? sourceId;
  final List<String> directRecommendationIds;

  const LikedAnime({
    required this.id,
    required this.title,
    this.cover,
    this.banner,
    this.genres = const [],
    this.tags = const [],
    this.format,
    this.score,
    this.season,
    this.type = MediaType.ANIME,
    required this.likedAt,
    this.providerId,
    this.sourceId,
    this.directRecommendationIds = const [],
  });

  factory LikedAnime.fromUnifiedMedia(UnifiedMedia media) {
    final directRecIds = <String>[];
    if (media.recommendations != null) {
      for (final rec in media.recommendations!) {
        if (rec.id.isNotEmpty) {
          directRecIds.add(rec.id);
        }
      }
    }

    return LikedAnime(
      id: media.id,
      title: media.title.availableTitle,
      cover: media.cover,
      banner: media.banner,
      genres: List<String>.from(media.genres ?? const []),
      tags: List<String>.from(media.tags ?? const []),
      format: media.format,
      score: media.score,
      season: media.season,
      type: media.type,
      likedAt: DateTime.now(),
      providerId: media.providerId,
      sourceId: media.sourceId,
      directRecommendationIds: directRecIds,
    );
  }

  UnifiedMedia toUnifiedMedia() {
    return UnifiedMedia(
      id: id,
      title: MediaTitle(english: title, userPreferred: title),
      cover: cover,
      banner: banner,
      genres: genres,
      tags: tags,
      format: format,
      score: score,
      season: season,
      type: type,
      providerId: providerId,
      sourceId: sourceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'banner': banner,
      'genres': genres,
      'tags': tags,
      'format': format,
      'score': score,
      'season': season,
      'type': type.name,
      'likedAt': likedAt.millisecondsSinceEpoch,
      'providerId': providerId,
      'sourceId': sourceId,
      'directRecommendationIds': directRecommendationIds,
    };
  }

  factory LikedAnime.fromMap(Map<String, dynamic> map) {
    return LikedAnime(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      cover: map['cover']?.toString(),
      banner: map['banner']?.toString(),
      genres: List<String>.from(map['genres'] ?? const []),
      tags: List<String>.from(map['tags'] ?? const []),
      format: map['format']?.toString(),
      score: (map['score'] as num?)?.toDouble(),
      season: map['season']?.toString(),
      type: MediaType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MediaType.ANIME,
      ),
      likedAt: map['likedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['likedAt'] as int)
          : DateTime.now(),
      providerId: map['providerId']?.toString(),
      sourceId: map['sourceId']?.toString(),
      directRecommendationIds: List<String>.from(
        map['directRecommendationIds'] ?? const [],
      ),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory LikedAnime.fromJson(String source) =>
      LikedAnime.fromMap(jsonDecode(source));
}
