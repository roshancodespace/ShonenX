import 'package:shonenx/core/models/anilist/fuzzy_date.dart';

class Media {
  final int? id;
  final Title? title;
  final CoverImage? coverImage;
  final String? bannerImage;
  final int? episodes;
  final int? duration;
  final String? format;
  final String? status;
  final String? description;
  final List<String> genres;
  final double? averageScore;
  final double? popularity;
  final Trailer? trailer;
  final List<Studio> studios;
  final List<StreamingEpisode> streamingEpisodes;
  final bool isAdult;
  final FuzzyDate? startDate;
  final FuzzyDate? endDate;
  final String? season;
  final int? seasonYear;
  final bool isFavourite;
  final List<MediaRanking> rankings;

  const Media({
    this.id,
    this.title,
    this.coverImage,
    this.bannerImage,
    this.episodes,
    this.duration,
    this.format,
    this.status,
    this.description,
    this.genres = const [],
    this.averageScore,
    this.popularity,
    this.trailer,
    this.studios = const [],
    this.streamingEpisodes = const [],
    this.isAdult = false,
    this.startDate,
    this.endDate,
    this.season,
    this.seasonYear,
    this.isFavourite = false,
    this.rankings = const [],
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int? ?? 0,
      title: Title.fromJson(json['title'] ?? {}),
      coverImage: CoverImage.fromJson(json['coverImage'] ?? {}),
      bannerImage: json['bannerImage'] as String? ?? '',
      episodes: json['episodes'] as int?,
      duration: json['duration'] as int?,
      format: json['format'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      description: json['description'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      trailer:
          json['trailer'] != null ? Trailer.fromJson(json['trailer']) : null,
      studios: (json['studios']?['nodes'] as List<dynamic>? ?? [])
          .map((s) => Studio.fromJson(s))
          .toList(),
      streamingEpisodes: (json['streamingEpisodes'] as List<dynamic>? ?? [])
          .map((s) => StreamingEpisode.fromJson(s))
          .toList(),
      isAdult: json['isAdult'] as bool? ?? false,
      startDate: json['startDate'] != null
          ? FuzzyDate.fromJson(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? FuzzyDate.fromJson(json['endDate']) : null,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      isFavourite: json['isFavourite'] as bool? ?? false,
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .map((r) => MediaRanking.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title?.toJson(),
      'coverImage': coverImage?.toJson(),
      'bannerImage': bannerImage,
      'episodes': episodes,
      'duration': duration,
      'format': format,
      'status': status,
      'description': description,
      'genres': genres,
      'averageScore': averageScore,
      'popularity': popularity,
      'trailer': trailer?.toJson(),
      'studios': {'nodes': studios.map((s) => s.toJson()).toList()},
      'streamingEpisodes': streamingEpisodes.map((s) => s.toJson()).toList(),
      'isAdult': isAdult,
      'startDate': startDate?.toJson(),
      'endDate': endDate?.toJson(),
      'season': season,
      'seasonYear': seasonYear,
      'isFavourite': isFavourite,
      'rankings': rankings.map((r) => r.toJson()).toList(),
    };
  }
}

class Title {
  final String? romaji;
  final String? english;
  final String? native;

  Title({
    this.romaji,
    this.english,
    this.native,
  });

  factory Title.fromJson(Map<String, dynamic> json) {
    return Title(
      romaji: json['romaji'] ?? 'Unknown',
      english: json['english'],
      native: json['native'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'romaji': romaji,
      'english': english,
      'native': native,
    };
  }
}

class CoverImage {
  final String large;
  final String medium;

  CoverImage({
    required this.large,
    required this.medium,
  });

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      large: json['large'] ?? '',
      medium: json['medium'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'medium': medium,
    };
  }
}

class StreamingEpisode {
  final String title;
  final String url;
  final String? thumbnail;
  final String? site;
  final String? id;

  StreamingEpisode({
    required this.title,
    required this.url,
    this.id,
    this.thumbnail,
    this.site,
  });

  factory StreamingEpisode.fromJson(Map<String, dynamic> json) {
    return StreamingEpisode(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      site: json['site'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'thumbnail': thumbnail,
      'site': site,
    };
  }
}

class Trailer {
  final String id;
  final String? site;
  final String? thumbnail;

  Trailer({
    required this.id,
    this.site,
    this.thumbnail,
  });

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] ?? '',
      site: json['site'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site': site,
      'thumbnail': thumbnail,
    };
  }
}

class Studio {
  final String name;
  final bool isMain;

  Studio({
    required this.name,
    required this.isMain,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      name: json['name'] ?? '',
      isMain: json['isMain'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isMain': isMain,
    };
  }
}

class MediaRanking {
  final int rank;
  final String type;
  final String context;
  final String? season;
  final int? year;
  final bool allTime;

  MediaRanking({
    required this.rank,
    required this.type,
    required this.context,
    this.season,
    this.year,
    required this.allTime,
  });

  factory MediaRanking.fromJson(Map<String, dynamic> json) {
    return MediaRanking(
      rank: json['rank'] as int,
      type: json['type'] as String,
      context: json['context'] as String,
      season: json['season'] as String?,
      year: json['year'] as int?,
      allTime: json['allTime'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'type': type,
      'context': context,
      'season': season,
      'year': year,
      'allTime': allTime,
    };
  }
}
