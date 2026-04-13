class UniversalMedia {
  final String id;
  final String? idMal;
  final UniversalTitle title;
  final UniversalCoverImage coverImage;
  final String? bannerImage;
  final String? format;
  final String? status;
  final String? description;
  final int? episodes;
  final int? duration;
  final double? averageScore;
  final int? popularity;
  final bool isAdult;
  final String? season;
  final int? seasonYear;
  final UniversalFuzzyDate? startDate;
  final UniversalFuzzyDate? endDate;
  final List<String> genres;
  final List<String> synonyms;
  final String? source;
  final List<String> tags;
  final UniversalNextAiringEpisode? nextAiringEpisode;
  final List<UniversalMediaRanking> rankings;
  final List<UniversalCharacter> characters;
  final List<UniversalStaff> staff;
  final List<UniversalMediaRelation> relations;
  final List<UniversalMedia> recommendations;
  final List<UniversalStudio> studios;
  final UniversalTrailer? trailer;
  final String? siteUrl;

  const UniversalMedia({
    required this.id,
    this.idMal,
    required this.title,
    required this.coverImage,
    this.bannerImage,
    this.format,
    this.status,
    this.description,
    this.episodes,
    this.duration,
    this.averageScore,
    this.popularity,
    this.isAdult = false,
    this.season,
    this.seasonYear,
    this.startDate,
    this.endDate,
    this.genres = const [],
    this.synonyms = const [],
    this.source,
    this.tags = const [],
    this.nextAiringEpisode,
    this.rankings = const [],
    this.characters = const [],
    this.staff = const [],
    this.relations = const [],
    this.recommendations = const [],
    this.studios = const [],
    this.trailer,
    this.siteUrl,
  });



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idMal': idMal,
      'title': title.toJson(),
      'coverImage': coverImage.toJson(),
      'bannerImage': bannerImage,
      'format': format,
      'status': status,
      'description': description,
      'episodes': episodes,
      'duration': duration,
      'averageScore': averageScore,
      'popularity': popularity,
      'isAdult': isAdult,
      'season': season,
      'seasonYear': seasonYear,
      'startDate': startDate?.toJson(),
      'endDate': endDate?.toJson(),
      'genres': genres,
      'synonyms': synonyms,
      'source': source,
      'tags': tags,
      'nextAiringEpisode': nextAiringEpisode?.toJson(),
      'rankings': rankings.map((e) => e.toJson()).toList(),
      'characters': characters.map((e) => e.toJson()).toList(),
      'staff': staff.map((e) => e.toJson()).toList(),
      'relations': relations.map((e) => e.toJson()).toList(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'studios': studios.map((e) => e.toJson()).toList(),
      'trailer': trailer?.toJson(),
      'siteUrl': siteUrl,
    };
  }

  UniversalMedia copyWith({
    String? id,
    String? idMal,
    UniversalTitle? title,
    UniversalCoverImage? coverImage,
    String? bannerImage,
    String? format,
    String? status,
    String? description,
    int? episodes,
    int? duration,
    double? averageScore,
    int? popularity,
    bool? isAdult,
    String? season,
    int? seasonYear,
    UniversalFuzzyDate? startDate,
    UniversalFuzzyDate? endDate,
    List<String>? genres,
    List<String>? synonyms,
    String? source,
    List<String>? tags,
    UniversalNextAiringEpisode? nextAiringEpisode,
    List<UniversalMediaRanking>? rankings,
    List<UniversalCharacter>? characters,
    List<UniversalStaff>? staff,
    List<UniversalMediaRelation>? relations,
    List<UniversalMedia>? recommendations,
    List<UniversalStudio>? studios,
    UniversalTrailer? trailer,
    String? siteUrl,
  }) {
    return UniversalMedia(
      id: id ?? this.id,
      idMal: idMal ?? this.idMal,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      bannerImage: bannerImage ?? this.bannerImage,
      format: format ?? this.format,
      status: status ?? this.status,
      description: description ?? this.description,
      episodes: episodes ?? this.episodes,
      duration: duration ?? this.duration,
      averageScore: averageScore ?? this.averageScore,
      popularity: popularity ?? this.popularity,
      isAdult: isAdult ?? this.isAdult,
      season: season ?? this.season,
      seasonYear: seasonYear ?? this.seasonYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      genres: genres ?? this.genres,
      synonyms: synonyms ?? this.synonyms,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      nextAiringEpisode: nextAiringEpisode ?? this.nextAiringEpisode,
      rankings: rankings ?? this.rankings,
      characters: characters ?? this.characters,
      staff: staff ?? this.staff,
      relations: relations ?? this.relations,
      recommendations: recommendations ?? this.recommendations,
      studios: studios ?? this.studios,
      trailer: trailer ?? this.trailer,
      siteUrl: siteUrl ?? this.siteUrl,
    );
  }
}

class UniversalTitle {
  final String? romaji;
  final String? english;
  final String? native;

  const UniversalTitle({this.romaji, this.english, this.native});

  String get userPreferred => english ?? romaji ?? native ?? 'Unknown';



  Map<String, dynamic> toJson() => {
    'romaji': romaji,
    'english': english,
    'native': native,
  };

  String get available => english ?? romaji ?? native ?? 'Unknown';
}

class UniversalCoverImage {
  final String? large;
  final String? medium;

  const UniversalCoverImage({this.large, this.medium});



  Map<String, dynamic> toJson() => {'large': large, 'medium': medium};
}

class UniversalNextAiringEpisode {
  final int? episode;
  final int? airingAt;
  final int? timeUntilAiring;

  const UniversalNextAiringEpisode({
    this.episode,
    this.airingAt,
    this.timeUntilAiring,
  });



  Map<String, dynamic> toJson() => {
    'episode': episode,
    'airingAt': airingAt,
    'timeUntilAiring': timeUntilAiring,
  };
}

class UniversalMediaRanking {
  final int? rank;
  final String type;
  final String context;
  final String? season;
  final int? year;
  final bool allTime;

  const UniversalMediaRanking({
    required this.rank,
    required this.type,
    required this.context,
    this.season,
    this.year,
    required this.allTime,
  });



  Map<String, dynamic> toJson() => {
    'rank': rank,
    'type': type,
    'context': context,
    'season': season,
    'year': year,
    'allTime': allTime,
  };
}

class UniversalCharacter {
  final int id;
  final String name;
  final String? image;
  final String? role;

  const UniversalCharacter({
    required this.id,
    required this.name,
    this.image,
    this.role,
  });



  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'role': role,
  };
}

class UniversalStaff {
  final int? id;
  final UniversalStaffName? name;
  final UniversalStaffImage? image;
  final String? role;

  const UniversalStaff({this.id, this.name, this.image, this.role});



  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name?.toJson(),
    'image': image?.toJson(),
    'role': role,
  };
}

class UniversalStaffName {
  final String? full;
  final String? native;

  const UniversalStaffName({this.full, this.native});



  Map<String, dynamic> toJson() => {'full': full, 'native': native};
}

class UniversalStaffImage {
  final String? large;
  final String? medium;

  const UniversalStaffImage({this.large, this.medium});



  Map<String, dynamic> toJson() => {'large': large, 'medium': medium};
}

class UniversalMediaRelation {
  final String relationType;
  final UniversalMedia media;

  const UniversalMediaRelation({
    required this.relationType,
    required this.media,
  });



  Map<String, dynamic> toJson() => {
    'relationType': relationType,
    'media': media.toJson(),
  };
}

class UniversalStudio {
  final String name;
  final bool isMain;

  const UniversalStudio({required this.name, required this.isMain});



  Map<String, dynamic> toJson() => {'name': name, 'isMain': isMain};
}

class UniversalTrailer {
  final String id;
  final String? site;
  final String? thumbnail;

  const UniversalTrailer({required this.id, this.site, this.thumbnail});



  Map<String, dynamic> toJson() => {
    'id': id,
    'site': site,
    'thumbnail': thumbnail,
  };
}

class UniversalFuzzyDate {
  final int? year;
  final int? month;
  final int? day;

  const UniversalFuzzyDate({this.year, this.month, this.day});



  Map<String, dynamic> toJson() => {'year': year, 'month': month, 'day': day};
}
