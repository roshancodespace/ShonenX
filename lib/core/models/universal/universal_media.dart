import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';

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

  /// Factory to convert from AniList [Media]
  factory UniversalMedia.fromAnilist(Media media) {
    return UniversalMedia(
      id: media.id.toString(),
      idMal: media.idMal?.toString(),
      title: UniversalTitle(
        romaji: media.title?.romaji,
        english: media.title?.english,
        native: media.title?.native,
      ),
      coverImage: UniversalCoverImage(
        large: media.coverImage?.large,
        medium: media.coverImage?.medium,
      ),
      bannerImage: media.bannerImage,
      format: media.format,
      status: media.status,
      description: media.description,
      episodes: media.episodes,
      duration: media.duration,
      averageScore: media.averageScore,
      popularity: media.popularity,
      isAdult: media.isAdult,
      season: media.season,
      seasonYear: media.seasonYear,
      startDate: media.startDate != null
          ? UniversalFuzzyDate.fromAnilist(media.startDate!)
          : null,
      endDate: media.endDate != null
          ? UniversalFuzzyDate.fromAnilist(media.endDate!)
          : null,
      genres: media.genres,
      synonyms: media.synonyms,
      source: media.source,
      tags: media.tags
          .map((e) => e.name ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      nextAiringEpisode: media.nextAiringEpisode != null
          ? UniversalNextAiringEpisode(
              episode: media.nextAiringEpisode!.episode,
              airingAt: media.nextAiringEpisode!.airingAt,
              timeUntilAiring: media.nextAiringEpisode!.timeUntilAiring,
            )
          : null,
      rankings: media.rankings.map(UniversalMediaRanking.fromAnilist).toList(),
      characters: media.characters.map(UniversalCharacter.fromAnilist).toList(),
      staff: media.staff.map(UniversalStaff.fromAnilist).toList(),
      relations:
          media.relations.map(UniversalMediaRelation.fromAnilist).toList(),
      recommendations:
          media.recommendations.map(UniversalMedia.fromAnilist).toList(),
      studios: media.studios.map(UniversalStudio.fromAnilist).toList(),
      trailer: media.trailer != null
          ? UniversalTrailer.fromAnilist(media.trailer!)
          : null,
      siteUrl: media.siteUrl,
    );
  }

  factory UniversalMedia.fromMal(Map<String, dynamic> node) {
    return UniversalMedia(
      id: node['id'].toString(),
      idMal: node['id'].toString(),
      title: UniversalTitle(
        romaji: node['title'],
        english: node['title'],
        native: node['title_japanese'],
      ),
      coverImage: UniversalCoverImage(
        large: node['main_picture']?['large'],
        medium: node['main_picture']?['medium'],
      ),
      bannerImage: node['background'],
      format: node['media_type'],
      status: node['status'],
      description: node['synopsis'],
      episodes: node['num_episodes'],
      duration: node['duration'],
      averageScore: (node['mean'] as num?)?.toDouble(),
      popularity: node['popularity'],
      isAdult: node['nsfw'] == 'white' ? false : true,
      startDate: node['start_date'] != null
          ? UniversalFuzzyDate.fromMal(node['start_date'])
          : null,
      endDate: node['end_date'] != null
          ? UniversalFuzzyDate.fromMal(node['end_date'])
          : null,
      genres:
          (node['genres'] as List?)?.map((e) => e['name'] as String).toList() ??
              [],
      source: node['source'],
    );
  }

  factory UniversalMedia.fromJson(Map<String, dynamic> json) {
    return UniversalMedia(
      id: json['id'],
      idMal: json['idMal'],
      title: UniversalTitle.fromJson(
          Map<String, dynamic>.from(json['title'] ?? {})),
      coverImage: UniversalCoverImage.fromJson(
          Map<String, dynamic>.from(json['coverImage'] ?? {})),
      bannerImage: json['bannerImage'],
      format: json['format'],
      status: json['status'],
      description: json['description'],
      episodes: json['episodes'],
      duration: json['duration'],
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      popularity: json['popularity'],
      isAdult: json['isAdult'] ?? false,
      season: json['season'],
      seasonYear: json['seasonYear'],
      startDate: json['startDate'] != null
          ? UniversalFuzzyDate.fromJson(
              Map<String, dynamic>.from(json['startDate']))
          : null,
      endDate: json['endDate'] != null
          ? UniversalFuzzyDate.fromJson(
              Map<String, dynamic>.from(json['endDate']))
          : null,
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      synonyms:
          (json['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      source: json['source'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? UniversalNextAiringEpisode.fromJson(
              Map<String, dynamic>.from(json['nextAiringEpisode']))
          : null,
      rankings: (json['rankings'] as List?)
              ?.map((e) =>
                  UniversalMediaRanking.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      characters: (json['characters'] as List?)
              ?.map((e) =>
                  UniversalCharacter.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      staff: (json['staff'] as List?)
              ?.map(
                  (e) => UniversalStaff.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      relations: (json['relations'] as List?)
              ?.map((e) =>
                  UniversalMediaRelation.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List?)
              ?.map(
                  (e) => UniversalMedia.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      studios: (json['studios'] as List?)
              ?.map(
                  (e) => UniversalStudio.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      trailer: json['trailer'] != null
          ? UniversalTrailer.fromJson(
              Map<String, dynamic>.from(json['trailer']))
          : null,
      siteUrl: json['siteUrl'],
    );
  }

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

  factory UniversalTitle.fromJson(Map<String, dynamic> json) {
    return UniversalTitle(
      romaji: json['romaji'],
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

class UniversalCoverImage {
  final String? large;
  final String? medium;

  const UniversalCoverImage({this.large, this.medium});

  factory UniversalCoverImage.fromJson(Map<String, dynamic> json) {
    return UniversalCoverImage(
      large: json['large'],
      medium: json['medium'],
    );
  }

  Map<String, dynamic> toJson() => {
        'large': large,
        'medium': medium,
      };
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

  factory UniversalNextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return UniversalNextAiringEpisode(
      episode: json['episode'],
      airingAt: json['airingAt'],
      timeUntilAiring: json['timeUntilAiring'],
    );
  }

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

  factory UniversalMediaRanking.fromAnilist(MediaRanking rank) {
    return UniversalMediaRanking(
      rank: rank.rank,
      type: rank.type,
      context: rank.context,
      season: rank.season,
      year: rank.year,
      allTime: rank.allTime,
    );
  }

  factory UniversalMediaRanking.fromJson(Map<String, dynamic> json) {
    return UniversalMediaRanking(
      rank: json['rank'],
      type: json['type'] ?? '',
      context: json['context'] ?? '',
      season: json['season'],
      year: json['year'],
      allTime: json['allTime'] ?? false,
    );
  }

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

  factory UniversalCharacter.fromAnilist(Character char) {
    return UniversalCharacter(
      id: char.id,
      name: char.name,
      image: char.image,
      role: char.role,
    );
  }

  factory UniversalCharacter.fromJson(Map<String, dynamic> json) {
    return UniversalCharacter(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: json['image'],
      role: json['role'],
    );
  }

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

  const UniversalStaff({
    this.id,
    this.name,
    this.image,
    this.role,
  });

  factory UniversalStaff.fromAnilist(Staff staff) {
    return UniversalStaff(
      id: staff.id,
      name: staff.name != null
          ? UniversalStaffName.fromAnilist(staff.name!)
          : null,
      image: staff.image != null
          ? UniversalStaffImage.fromAnilist(staff.image!)
          : null,
      role: staff.role,
    );
  }

  factory UniversalStaff.fromJson(Map<String, dynamic> json) {
    return UniversalStaff(
      id: json['id'],
      name: json['name'] != null
          ? UniversalStaffName.fromJson(Map<String, dynamic>.from(json['name']))
          : null,
      image: json['image'] != null
          ? UniversalStaffImage.fromJson(
              Map<String, dynamic>.from(json['image']))
          : null,
      role: json['role'],
    );
  }

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

  factory UniversalStaffName.fromAnilist(StaffName name) {
    return UniversalStaffName(full: name.full, native: name.native);
  }

  factory UniversalStaffName.fromJson(Map<String, dynamic> json) {
    return UniversalStaffName(
      full: json['full'],
      native: json['native'],
    );
  }

  Map<String, dynamic> toJson() => {
        'full': full,
        'native': native,
      };
}

class UniversalStaffImage {
  final String? large;
  final String? medium;

  const UniversalStaffImage({this.large, this.medium});

  factory UniversalStaffImage.fromAnilist(StaffImage image) {
    return UniversalStaffImage(large: image.large, medium: image.medium);
  }

  factory UniversalStaffImage.fromJson(Map<String, dynamic> json) {
    return UniversalStaffImage(
      large: json['large'],
      medium: json['medium'],
    );
  }

  Map<String, dynamic> toJson() => {
        'large': large,
        'medium': medium,
      };
}

class UniversalMediaRelation {
  final String relationType;
  final UniversalMedia media;

  const UniversalMediaRelation(
      {required this.relationType, required this.media});

  factory UniversalMediaRelation.fromAnilist(MediaRelation rel) {
    return UniversalMediaRelation(
      relationType: rel.relationType,
      media: UniversalMedia.fromAnilist(rel.media),
    );
  }

  factory UniversalMediaRelation.fromJson(Map<String, dynamic> json) {
    return UniversalMediaRelation(
      relationType: json['relationType'] ?? 'UNKNOWN',
      media: UniversalMedia.fromJson(
          Map<String, dynamic>.from(json['media'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
        'relationType': relationType,
        'media': media.toJson(),
      };
}

class UniversalStudio {
  final String name;
  final bool isMain;

  const UniversalStudio({required this.name, required this.isMain});

  factory UniversalStudio.fromAnilist(Studio studio) {
    return UniversalStudio(name: studio.name, isMain: studio.isMain);
  }

  factory UniversalStudio.fromJson(Map<String, dynamic> json) {
    return UniversalStudio(
      name: json['name'] ?? '',
      isMain: json['isMain'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'isMain': isMain,
      };
}

class UniversalTrailer {
  final String id;
  final String? site;
  final String? thumbnail;

  const UniversalTrailer({required this.id, this.site, this.thumbnail});

  factory UniversalTrailer.fromAnilist(Trailer trailer) {
    return UniversalTrailer(
      id: trailer.id,
      site: trailer.site,
      thumbnail: trailer.thumbnail,
    );
  }

  factory UniversalTrailer.fromJson(Map<String, dynamic> json) {
    return UniversalTrailer(
      id: json['id'] ?? '',
      site: json['site'],
      thumbnail: json['thumbnail'],
    );
  }

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

  factory UniversalFuzzyDate.fromAnilist(FuzzyDate date) {
    return UniversalFuzzyDate(
      year: date.year,
      month: date.month,
      day: date.day,
    );
  }

  factory UniversalFuzzyDate.fromMal(String dateStr) {
    final parts = dateStr.split('-');
    return UniversalFuzzyDate(
      year: parts.isNotEmpty ? int.tryParse(parts[0]) : null,
      month: parts.length > 1 ? int.tryParse(parts[1]) : null,
      day: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
  }

  factory UniversalFuzzyDate.fromJson(Map<String, dynamic> json) {
    return UniversalFuzzyDate(
      year: json['year'],
      month: json['month'],
      day: json['day'],
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };
}
