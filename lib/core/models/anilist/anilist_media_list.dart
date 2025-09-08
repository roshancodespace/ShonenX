class MediaListCollection {
  final List<MediaListGroup> lists;

  MediaListCollection({required this.lists});

  factory MediaListCollection.fromJson(Map<String, dynamic>? json) {
    final listData =
        json?['MediaListCollection']?['lists'] as List<dynamic>? ?? [];

    return MediaListCollection(
      lists: listData
          .map((list) => MediaListGroup.fromJson(list as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MediaListGroup {
  final String name;
  final List<MediaList> entries;

  MediaListGroup({required this.name, required this.entries});

  factory MediaListGroup.fromJson(Map<String, dynamic> json) {
    return MediaListGroup(
      name: json['name'] as String? ?? 'Unknown',
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((entry) => MediaList.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MediaList {
  final Media media;
  final String status;
  final int score;
  final int progress;

  MediaList({
    required this.media,
    required this.status,
    required this.score,
    required this.progress,
  });

  factory MediaList.fromJson(Map<String, dynamic> json) {
    return MediaList(
      media: Media.fromJson(json['media'] as Map<String, dynamic>? ?? {}),
      status: json['status'] as String? ?? 'UNKNOWN',
      score: json['score'] as int? ?? 0,
      progress: json['progress'] as int? ?? 0,
    );
  }
}

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
  final List<String>? genres;
  final double? averageScore;
  final double? popularity;
  final Trailer? trailer;
  final List<Studio>? studios;
  final List<StreamingEpisode>? streamingEpisodes;
  final bool? isAdult;
  final Date? startDate;
  final Date? endDate;
  final String? season;
  final int? seasonYear;
  final bool? isFavourite;
  final List<MediaRanking>? rankings;

  Media({
    this.id,
    this.title,
    this.coverImage,
    this.bannerImage,
    this.episodes,
    this.duration,
    this.format,
    this.status,
    this.description,
    this.genres,
    this.averageScore,
    this.popularity,
    this.trailer,
    this.studios,
    this.streamingEpisodes,
    this.isAdult,
    this.startDate,
    this.endDate,
    this.season,
    this.seasonYear,
    this.isFavourite,
    this.rankings,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int? ?? 0,
      title: Title.fromJson(json['title'] ?? {}),
      coverImage: CoverImage.fromJson(json['coverImage'] ?? {}),
      bannerImage: json['bannerImage'] ?? '',
      episodes: json['episodes'],
      duration: json['duration'],
      format: json['format'] ?? 'UNKNOWN',
      status: json['status'] ?? 'UNKNOWN',
      description: json['description'] ?? '',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          [],
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      trailer:
          json['trailer'] != null ? Trailer.fromJson(json['trailer']) : null,
      studios: (json['studios']?['nodes'] as List<dynamic>?)
          ?.map((s) => Studio.fromJson(s))
          .toList(),
      streamingEpisodes: (json['streamingEpisodes'] as List<dynamic>?)
          ?.map((s) => StreamingEpisode.fromJson(s))
          .toList(),
      isAdult: json['isAdult'] ?? false,
      startDate:
          json['startDate'] != null ? Date.fromJson(json['startDate']) : null,
      endDate: json['endDate'] != null ? Date.fromJson(json['endDate']) : null,
      season: json['season'],
      seasonYear: json['seasonYear'],
      isFavourite: json['isFavourite'] ?? false,
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .where((r) => r != null) // Ensure entries are not null
          .map((r) => MediaRanking.fromJson(r as Map<String, dynamic>))
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
      'studios': studios?.map((s) => s.toJson()).toList(),
      'streamingEpisodes': streamingEpisodes?.map((s) => s.toJson()).toList(),
      'isAdult': isAdult,
      'startDate': startDate?.toJson(),
      'endDate': endDate?.toJson(),
      'season': season,
      'seasonYear': seasonYear,
      'isFavourite': isFavourite,
      'rankings': rankings?.map((r) => r.toJson()).toList(),
    };
  }
}

class Title {
  final String? romaji;
  final String? english;
  final String? native;

  Title({
    required this.romaji,
    this.english,
    this.native,
  });

  factory Title.fromJson(Map<String, dynamic> json) {
    return Title(
      romaji: json['romaji'],
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

class StreamingEpisode {
  final String title;
  final String url;
  final String? thumbnail;
  final String? site;

  StreamingEpisode({
    required this.title,
    required this.url,
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

class Date {
  final int? year;
  final int? month;
  final int? day;

  Date({this.year, this.month, this.day});

  factory Date.fromJson(Map<String, dynamic> json) {
    return Date(
      year: json['year'],
      month: json['month'],
      day: json['day'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'day': day,
    };
  }
}

/// **Ranking information (e.g., #1 in Popularity, #5 in Top Anime)**
class MediaRanking {
  final int rank;
  final String type;
  final String context;
  final String? season; // Can be null
  final int? year; // Can be null
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
      season: json['season'] as String?, // Allow null
      year: json['year'] as int?, // Allow null
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
