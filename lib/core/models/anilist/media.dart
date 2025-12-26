import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';

class Media {
  final dynamic id;
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
  final List<MediaRelation> relations;
  final List<Media> recommendations;
  final List<Character> characters;

  // MAL specific fields
  final String? source;
  final int? rank;
  final int? favorites;
  final double? meanScore;

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
    this.relations = const [],
    this.recommendations = const [],
    this.characters = const [],
    this.source,
    this.rank,
    this.favorites,
    this.meanScore,
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
      source: json['source'] as String?,
      rank: json['rank'] as int?,
      favorites: json['favorites'] as int?,
      meanScore: (json['meanScore'] as num?)?.toDouble(),
      relations: (json['relations']?['edges'] as List<dynamic>? ?? [])
          .map((e) => MediaRelation.fromJson(e))
          .toList(),
      recommendations:
          (json['recommendations']?['nodes'] as List<dynamic>? ?? [])
              .map((e) => Media.fromJson(e['mediaRecommendation']))
              .toList(),
      characters: (json['characters']?['edges'] as List<dynamic>? ?? [])
          .map((e) => Character.fromJson(e))
          .toList(),
    );
  }

  factory Media.fromMal(Map<String, dynamic> node) {
    return Media(
      id: node['id'],
      title: Title(
        romaji: node['title'],
        english: node['title'],
        native: node['title_japanese'],
      ),
      coverImage: CoverImage(
        large: node['main_picture']?['large'] ?? '',
        medium: node['main_picture']?['medium'] ?? '',
      ),
      bannerImage: node['background'] ?? '',
      episodes: node['num_episodes'],
      duration: node['duration'],
      format: node['media_type'],
      status: node['status'],
      description: node['synopsis'],
      genres: (node['genres'] as List<dynamic>? ?? [])
          .map((e) => e['name'] as String)
          .toList(),
      averageScore: (node['mean'] as num?)?.toDouble(),
      popularity: (node['popularity'] as num?)?.toDouble(),
      source: node['source'],
      rank: node['rank'],
      favorites: node['favorites'],
      startDate: node['start_date'] != null
          ? FuzzyDate.fromJson({
              'year': int.tryParse(node['start_date'].substring(0, 4)),
              'month': node['start_date'].length > 5
                  ? int.tryParse(node['start_date'].substring(5, 7))
                  : null,
              'day': node['start_date'].length > 8
                  ? int.tryParse(node['start_date'].substring(8, 10))
                  : null,
            })
          : null,
      endDate: node['end_date'] != null
          ? FuzzyDate.fromJson({
              'year': int.tryParse(node['end_date'].substring(0, 4)),
              'month': node['end_date'].length > 5
                  ? int.tryParse(node['end_date'].substring(5, 7))
                  : null,
              'day': node['end_date'].length > 8
                  ? int.tryParse(node['end_date'].substring(8, 10))
                  : null,
            })
          : null,
      isAdult: node['nsfw'] ?? false,
      studios: [],
      streamingEpisodes: [],
      trailer: null,
      season: null,
      seasonYear: null,
      isFavourite: false,
      rankings: [],
      relations: [],
      recommendations: [],
      characters: [],
      meanScore: (node['mean'] as num?)?.toDouble(),
    );
  }

  BaseAnimeModel toBaseAnimeModel(Media media) {
    return BaseAnimeModel(
      id: media.id.toString(),
      name: media.title?.english ?? media.title?.romaji ?? media.title?.native,
      poster: media.coverImage?.large ?? media.coverImage?.medium,
      banner: media.bannerImage,
      type: media.format,
      description: media.description,
      genres: media.genres,
      rank: media.rank,
      duration: media.duration.toString(),
      episodes: EpisodesModel(
        sub: media.episodes,
        dub: media.episodes,
        total: media.episodes,
      ),
      releaseDate: media.startDate?.toDateTime?.toIso8601String(),
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
      'source': source,
      'rank': rank,
      'favorites': favorites,
      'meanScore': meanScore,
      'relations': {
        'edges': relations.map((r) => r.toJson()).toList(),
      },
      'recommendations': {
        'nodes': recommendations
            .map((r) => {'mediaRecommendation': r.toJson()})
            .toList(),
      },
      'characters': {
        'edges': characters.map((c) => c.toJson()).toList(),
      },
    };
  }

  copyWith({
    dynamic id,
    Title? title,
    CoverImage? coverImage,
    String? bannerImage,
    int? episodes,
    int? duration,
    String? format,
    String? status,
    String? description,
    List<String>? genres,
    double? averageScore,
    double? popularity,
    Trailer? trailer,
    List<Studio>? studios,
    List<StreamingEpisode>? streamingEpisodes,
    bool? isAdult,
    FuzzyDate? startDate,
    FuzzyDate? endDate,
    String? season,
    int? seasonYear,
    bool? isFavourite,
    List<MediaRanking>? rankings,
    List<MediaRelation>? relations,
    List<Media>? recommendations,
    List<Character>? characters,
    String? source,
    int? rank,
    int? favorites,
    double? meanScore,
  }) {
    return Media(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      bannerImage: bannerImage ?? this.bannerImage,
      episodes: episodes ?? this.episodes,
      duration: duration ?? this.duration,
      format: format ?? this.format,
      status: status ?? this.status,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      averageScore: averageScore ?? this.averageScore,
      popularity: popularity ?? this.popularity,
      trailer: trailer ?? this.trailer,
      studios: studios ?? this.studios,
      streamingEpisodes: streamingEpisodes ?? this.streamingEpisodes,
      isAdult: isAdult ?? this.isAdult,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      season: season ?? this.season,
      seasonYear: seasonYear ?? this.seasonYear,
      isFavourite: isFavourite ?? this.isFavourite,
      rankings: rankings ?? this.rankings,
      relations: relations ?? this.relations,
      recommendations: recommendations ?? this.recommendations,
      characters: characters ?? this.characters,
      source: source ?? this.source,
      rank: rank ?? this.rank,
      favorites: favorites ?? this.favorites,
      meanScore: meanScore ?? this.meanScore,
    );
  }
}

// ---------------- Supporting Classes ----------------

class Title {
  final String? romaji;
  final String? english;
  final String? native;

  Title({this.romaji, this.english, this.native});

  factory Title.fromJson(Map<String, dynamic> json) {
    return Title(
      romaji: json['romaji'] ?? 'Unknown',
      english: json['english'],
      native: json['native'],
    );
  }

  Map<String, dynamic> toJson() => {
        'romaji': romaji,
        'english': english,
        'native': native,
      };
}

class CoverImage {
  final String large;
  final String medium;

  CoverImage({required this.large, required this.medium});

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      large: json['large'] ?? '',
      medium: json['medium'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'large': large, 'medium': medium};
}

class StreamingEpisode {
  final String title;
  final String url;
  final String? thumbnail;
  final String? site;
  final String? id;

  StreamingEpisode(
      {required this.title,
      required this.url,
      this.id,
      this.thumbnail,
      this.site});

  factory StreamingEpisode.fromJson(Map<String, dynamic> json) {
    return StreamingEpisode(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      site: json['site'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'thumbnail': thumbnail, 'site': site};
  }
}

class Trailer {
  final String id;
  final String? site;
  final String? thumbnail;

  Trailer({required this.id, this.site, this.thumbnail});

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] ?? '',
      site: json['site'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'site': site, 'thumbnail': thumbnail};
}

class Studio {
  final String name;
  final bool isMain;

  Studio({required this.name, required this.isMain});

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      name: json['name'] ?? '',
      isMain: json['isMain'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'isMain': isMain};
}

class MediaRanking {
  final int rank;
  final String type;
  final String context;
  final String? season;
  final int? year;
  final bool allTime;

  MediaRanking(
      {required this.rank,
      required this.type,
      required this.context,
      this.season,
      this.year,
      required this.allTime});

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
      'allTime': allTime
    };
  }
}

// ---------------- FuzzyDate extension for MAL ----------------
extension FuzzyDateMal on FuzzyDate {
  static FuzzyDate fromMal(String dateStr) {
    final parts = dateStr.split('-');
    return FuzzyDate(
      year: parts.isNotEmpty ? int.tryParse(parts[0]) : null,
      month: parts.length > 1 ? int.tryParse(parts[1]) : null,
      day: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
  }
}

class MediaRelation {
  final String relationType;
  final Media media;

  MediaRelation({required this.relationType, required this.media});

  factory MediaRelation.fromJson(Map<String, dynamic> json) {
    return MediaRelation(
      relationType: json['relationType'] ?? 'UNKNOWN',
      media: Media.fromJson(json['node'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'relationType': relationType,
        'node': media.toJson(),
      };
}

class Character {
  final int id;
  final String name;
  final String? image;
  final String? role;

  Character({
    required this.id,
    required this.name,
    this.image,
    this.role,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return Character(
      id: node['id'] ?? 0,
      name: node['name']?['full'] ?? 'Unknown',
      image: node['image']?['large'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'node': {
          'id': id,
          'name': {'full': name},
          'image': {'large': image},
        },
      };
}
