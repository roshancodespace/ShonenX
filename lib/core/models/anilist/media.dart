import 'package:shonenx/core/models/anilist/fuzzy_date.dart';

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
      'relations': {'edges': relations.map((r) => r.toJson()).toList()},
      'recommendations': {
        'nodes': recommendations
            .map((m) => {'mediaRecommendation': m.toJson()})
            .toList(),
      },
      'characters': {'edges': characters.map((c) => c.toJson()).toList()},
      'staff': {'edges': staff.map((s) => s.toJson()).toList()},
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

  Map<String, dynamic> toJson() => {'large': large, 'medium': medium};
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

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'thumbnail': thumbnail, 'site': site};
  }
}

class Trailer {
  final String id;
  final String? site;
  final String? thumbnail;

  Trailer({required this.id, this.site, this.thumbnail});

  Map<String, dynamic> toJson() => {
    'id': id,
    'site': site,
    'thumbnail': thumbnail,
  };
}

class Studio {
  final String name;
  final bool isMain;

  Studio({required this.name, required this.isMain});

  Map<String, dynamic> toJson() => {'name': name, 'isMain': isMain};
}

class MediaRanking {
  final int? rank;
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

// ---------------- FuzzyDate extension for MAL ----------------

class MediaRelation {
  final String relationType;
  final Media media;

  MediaRelation({required this.relationType, required this.media});

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

  Character({required this.id, required this.name, this.image, this.role});

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

  const Staff({this.id, this.name, this.image, this.role});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'node': {'id': id, 'name': name?.toJson(), 'image': image?.toJson()},
    };
  }
}

class StaffName {
  final String? full;
  final String? native;

  const StaffName({this.full, this.native});

  Map<String, dynamic> toJson() {
    return {'full': full, 'native': native};
  }
}

class StaffImage {
  final String? large;
  final String? medium;

  const StaffImage({this.large, this.medium});

  Map<String, dynamic> toJson() {
    return {'large': large, 'medium': medium};
  }
}
