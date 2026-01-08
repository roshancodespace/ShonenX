import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';

class Media {
  final dynamic id;
  final int? idMal;
  final String? type;
  final String? format;
  final String? status;
  final String? source;
  final bool isAdult;
  final String? countryOfOrigin;

  final Title? title;
  final CoverImage? coverImage;
  final String? bannerImage;
  final String? description;
  final List<String> synonyms;

  final int? episodes;
  final int? duration;

  final String? season;
  final int? seasonYear;
  final FuzzyDate? startDate;
  final FuzzyDate? endDate;
  final NextAiringEpisode? nextAiringEpisode;

  final List<String> genres;
  final List<Tag> tags;

  final double? averageScore;
  final double? meanScore;
  final int? popularity;
  final int? favourites;

  final List<MediaRanking> rankings;
  final List<Studio> studios;

  final List<MediaRelation> relations;
  final List<Media> recommendations;
  final List<Character> characters;
  final List<Staff> staff;

  final Trailer? trailer;
  final String? siteUrl;

  final bool isFavourite;

  const Media({
    this.id,
    this.idMal,
    this.type,
    this.format,
    this.status,
    this.source,
    this.isAdult = false,
    this.countryOfOrigin,
    this.title,
    this.coverImage,
    this.bannerImage,
    this.description,
    this.synonyms = const [],
    this.episodes,
    this.duration,
    this.season,
    this.seasonYear,
    this.startDate,
    this.endDate,
    this.nextAiringEpisode,
    this.genres = const [],
    this.tags = const [],
    this.averageScore,
    this.meanScore,
    this.popularity,
    this.favourites,
    this.rankings = const [],
    this.studios = const [],
    this.relations = const [],
    this.recommendations = const [],
    this.characters = const [],
    this.staff = const [],
    this.trailer,
    this.siteUrl,
    this.isFavourite = false,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      idMal: json['idMal'],
      type: json['type'],
      format: json['format'],
      status: json['status'],
      source: json['source'],
      isAdult: json['isAdult'] ?? false,
      countryOfOrigin: json['countryOfOrigin'],
      title: json['title'] != null ? Title.fromJson(json['title']) : null,
      coverImage: json['coverImage'] != null
          ? CoverImage.fromJson(json['coverImage'])
          : null,
      bannerImage: json['bannerImage'],
      description: json['description'],
      synonyms: (json['synonyms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      episodes: json['episodes'],
      duration: json['duration'],
      season: json['season'],
      seasonYear: json['seasonYear'],
      startDate: json['startDate'] != null
          ? FuzzyDate.fromJson(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? FuzzyDate.fromJson(json['endDate']) : null,
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => Tag.fromJson(e))
          .toList(),
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      meanScore: (json['meanScore'] as num?)?.toDouble(),
      popularity: json['popularity'],
      favourites: json['favourites'],
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .map((e) => MediaRanking.fromJson(e))
          .toList(),
      studios: (json['studios']?['edges'] as List<dynamic>? ?? [])
          .map((e) => Studio.fromJson(e['node']))
          .toList(),
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
      staff: (json['staff']?['edges'] as List<dynamic>? ?? [])
          .map((e) => Staff.fromJson(e))
          .toList(),
      trailer:
          json['trailer'] != null ? Trailer.fromJson(json['trailer']) : null,
      siteUrl: json['siteUrl'],
      isFavourite: json['isFavourite'] ?? false,
    );
  }

  factory Media.fromMal(Map<String, dynamic> node) {
    return Media(
      id: node['id'],
      idMal: node['id'],
      type: 'ANIME',
      format: node['media_type'],
      status: node['status'],
      source: node['source'],
      isAdult: node['nsfw'] ?? false,
      title: Title(
        romaji: node['title'],
        english: node['title'],
        native: node['title_japanese'],
      ),
      coverImage: CoverImage(
        large: node['main_picture']?['large'],
        medium: node['main_picture']?['medium'],
      ),
      bannerImage: node['background'],
      description: node['synopsis'],
      episodes: node['num_episodes'],
      duration: node['duration'],
      genres: (node['genres'] as List<dynamic>? ?? [])
          .map((e) => e['name'] as String)
          .toList(),
      averageScore: (node['mean'] as num?)?.toDouble(),
      meanScore: (node['mean'] as num?)?.toDouble(),
      popularity: node['popularity'],
      favourites: node['favorites'],
      startDate: node['start_date'] != null
          ? FuzzyDate.fromIso(node['start_date'])
          : null,
      endDate:
          node['end_date'] != null ? FuzzyDate.fromIso(node['end_date']) : null,
    );
  }

  BaseAnimeModel toBaseAnimeModel(Media media) {
    return BaseAnimeModel(
      id: media.id?.toString(),
      anilistId: media.id is int ? media.id as int : null,
      name: media.title?.english ?? media.title?.romaji ?? media.title?.native,
      jname: media.title?.native,
      poster: media.coverImage?.large ?? media.coverImage?.medium,
      banner: media.bannerImage,
      type: media.format,
      description: media.description,
      genres: media.genres.isNotEmpty ? media.genres : null,
      url: media.siteUrl,
      rank: _extractTopRank(media.rankings),
      episodes: EpisodesModel(
        sub: media.episodes,
        dub: media.episodes,
        total: media.episodes,
      ),
      duration: media.duration != null ? '${media.duration} min' : null,
      releaseDate: media.startDate?.toDateTime?.toIso8601String(),
    );
  }

  int? _extractTopRank(List<MediaRanking> rankings) {
    if (rankings.isEmpty) return null;

    final ranked = rankings.where((r) => r.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));

    return ranked.isNotEmpty ? ranked.first.rank : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idMal': idMal,
      'type': type,
      'format': format,
      'status': status,
      'source': source,
      'isAdult': isAdult,
      'countryOfOrigin': countryOfOrigin,
      'title': title?.toJson(),
      'coverImage': coverImage?.toJson(),
      'bannerImage': bannerImage,
      'description': description,
      'synonyms': synonyms,
      'episodes': episodes,
      'duration': duration,
      'season': season,
      'seasonYear': seasonYear,
      'startDate': startDate?.toJson(),
      'endDate': endDate?.toJson(),
      'nextAiringEpisode': nextAiringEpisode?.toJson(),
      'genres': genres,
      'tags': tags.map((t) => t.toJson()).toList(),
      'averageScore': averageScore,
      'meanScore': meanScore,
      'popularity': popularity,
      'favourites': favourites,
      'rankings': rankings.map((r) => r.toJson()).toList(),
      'studios': {
        'edges': studios.map((s) => {'node': s.toJson()}).toList(),
      },
      'relations': {
        'edges': relations.map((r) => r.toJson()).toList(),
      },
      'recommendations': {
        'nodes': recommendations
            .map((m) => {'mediaRecommendation': m.toJson()})
            .toList(),
      },
      'characters': {
        'edges': characters.map((c) => c.toJson()).toList(),
      },
      'staff': {
        'edges': staff.map((s) => s.toJson()).toList(),
      },
      'trailer': trailer?.toJson(),
      'siteUrl': siteUrl,
      'isFavourite': isFavourite,
    };
  }

  Media copyWith({
    dynamic id,
    int? idMal,
    String? type,
    String? format,
    String? status,
    String? source,
    bool? isAdult,
    String? countryOfOrigin,
    Title? title,
    CoverImage? coverImage,
    String? bannerImage,
    String? description,
    List<String>? synonyms,
    int? episodes,
    int? duration,
    String? season,
    int? seasonYear,
    FuzzyDate? startDate,
    FuzzyDate? endDate,
    NextAiringEpisode? nextAiringEpisode,
    List<String>? genres,
    List<Tag>? tags,
    double? averageScore,
    double? meanScore,
    int? popularity,
    int? favourites,
    List<MediaRanking>? rankings,
    List<Studio>? studios,
    List<MediaRelation>? relations,
    List<Media>? recommendations,
    List<Character>? characters,
    List<Staff>? staff,
    Trailer? trailer,
    String? siteUrl,
    bool? isFavourite,
  }) {
    return Media(
      id: id ?? this.id,
      idMal: idMal ?? this.idMal,
      type: type ?? this.type,
      format: format ?? this.format,
      status: status ?? this.status,
      source: source ?? this.source,
      isAdult: isAdult ?? this.isAdult,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      bannerImage: bannerImage ?? this.bannerImage,
      description: description ?? this.description,
      synonyms: synonyms ?? this.synonyms,
      episodes: episodes ?? this.episodes,
      duration: duration ?? this.duration,
      season: season ?? this.season,
      seasonYear: seasonYear ?? this.seasonYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextAiringEpisode: nextAiringEpisode ?? this.nextAiringEpisode,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      averageScore: averageScore ?? this.averageScore,
      meanScore: meanScore ?? this.meanScore,
      popularity: popularity ?? this.popularity,
      favourites: favourites ?? this.favourites,
      rankings: rankings ?? this.rankings,
      studios: studios ?? this.studios,
      relations: relations ?? this.relations,
      recommendations: recommendations ?? this.recommendations,
      characters: characters ?? this.characters,
      staff: staff ?? this.staff,
      trailer: trailer ?? this.trailer,
      siteUrl: siteUrl ?? this.siteUrl,
      isFavourite: isFavourite ?? this.isFavourite,
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
  final int? rank;
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
      rank: json['rank'] as int?,
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

class NextAiringEpisode {
  final int? id;
  final int? airingAt;
  final int? timeUntilAiring;
  final int? episode;

  const NextAiringEpisode({
    this.id,
    this.airingAt,
    this.timeUntilAiring,
    this.episode,
  });

  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
      id: json['id'],
      airingAt: json['airingAt'],
      timeUntilAiring: json['timeUntilAiring'],
      episode: json['episode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airingAt': airingAt,
      'timeUntilAiring': timeUntilAiring,
      'episode': episode,
    };
  }
}

class Tag {
  final int? id;
  final String? name;
  final String? description;
  final int? rank;
  final bool isAdult;

  const Tag({
    this.id,
    this.name,
    this.description,
    this.rank,
    this.isAdult = false,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rank: json['rank'],
      isAdult: json['isAdult'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rank': rank,
      'isAdult': isAdult,
    };
  }
}

class Staff {
  final int? id;
  final StaffName? name;
  final StaffImage? image;
  final String? role;

  const Staff({
    this.id,
    this.name,
    this.image,
    this.role,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    return Staff(
      id: node['id'],
      name: node['name'] != null ? StaffName.fromJson(node['name']) : null,
      image: node['image'] != null ? StaffImage.fromJson(node['image']) : null,
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'node': {
        'id': id,
        'name': name?.toJson(),
        'image': image?.toJson(),
      },
    };
  }
}

class StaffName {
  final String? full;
  final String? native;

  const StaffName({
    this.full,
    this.native,
  });

  factory StaffName.fromJson(Map<String, dynamic> json) {
    return StaffName(
      full: json['full'],
      native: json['native'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full': full,
      'native': native,
    };
  }
}

class StaffImage {
  final String? large;
  final String? medium;

  const StaffImage({
    this.large,
    this.medium,
  });

  factory StaffImage.fromJson(Map<String, dynamic> json) {
    return StaffImage(
      large: json['large'],
      medium: json['medium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'medium': medium,
    };
  }
}
