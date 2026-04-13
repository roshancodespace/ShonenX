import 'package:shonenx/core/models/universal/universal_media.dart';

class UniversalMediaMapper {
  static UniversalMedia fromAnilist(Map<String, dynamic> node) {
    return UniversalMedia(
      id: node['id'].toString(),
      idMal: node['idMal']?.toString(),
      title: UniversalTitleMapper.fromAnilist(Map<String, dynamic>.from(node['title'] ?? {})),
      coverImage: UniversalCoverImageMapper.fromAnilist(Map<String, dynamic>.from(node['coverImage'] ?? {})),
      bannerImage: node['bannerImage'],
      format: node['format'],
      status: node['status'],
      description: node['description'],
      episodes: node['episodes'],
      duration: node['duration'],
      averageScore: (node['averageScore'] as num?)?.toDouble(),
      popularity: node['popularity'],
      isAdult: node['isAdult'] ?? false,
      season: node['season'],
      seasonYear: node['seasonYear'],
      startDate: node['startDate'] != null
          ? UniversalFuzzyDateMapper.fromJson(
              Map<String, dynamic>.from(node['startDate']),
            )
          : null,
      endDate: node['endDate'] != null
          ? UniversalFuzzyDateMapper.fromJson(
              Map<String, dynamic>.from(node['endDate']),
            )
          : null,
      genres:
          (node['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      synonyms:
          (node['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      source: node['source'],
      tags:
          (node['tags'] as List?)
              ?.map((e) => e['name']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      nextAiringEpisode: node['nextAiringEpisode'] != null
          ? UniversalNextAiringEpisodeMapper.fromJson(
              Map<String, dynamic>.from(node['nextAiringEpisode']),
            )
          : null,
      rankings:
          (node['rankings'] as List?)
              ?.map(
                (e) => UniversalMediaRankingMapper.fromAnilist(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      characters:
          (node['characters']?['edges'] as List?)
              ?.map(
                (e) => UniversalCharacterMapper.fromAnilist(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      staff:
          (node['staff']?['edges'] as List?)
              ?.map(
                (e) => UniversalStaffMapper.fromAnilist(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      relations:
          (node['relations']?['edges'] as List?)
              ?.map(
                (e) => UniversalMediaRelationMapper.fromAnilist(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      recommendations:
          (node['recommendations']?['nodes'] as List?)
              ?.map((e) {
                final recNode = e['mediaRecommendation'];
                return recNode != null
                    ? UniversalMediaMapper.fromAnilist(
                        Map<String, dynamic>.from(recNode),
                      )
                    : null;
              })
              .whereType<UniversalMedia>()
              .toList() ??
          [],
      studios:
          (node['studios']?['nodes'] as List?)
              ?.map(
                (e) =>
                    UniversalStudioMapper.fromAnilist(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      trailer: node['trailer'] != null
          ? UniversalTrailerMapper.fromAnilist(
              Map<String, dynamic>.from(node['trailer']),
            )
          : null,
      siteUrl: node['siteUrl'],
    );
  }

  static UniversalMedia fromMal(Map<String, dynamic> node) {
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
          ? UniversalFuzzyDateMapper.fromMal(node['start_date'])
          : null,
      endDate: node['end_date'] != null
          ? UniversalFuzzyDateMapper.fromMal(node['end_date'])
          : null,
      genres:
          (node['genres'] as List?)?.map((e) => e['name'] as String).toList() ??
          [],
      source: node['source'],
    );
  }

  static UniversalMedia fromJson(Map<String, dynamic> json) {
    return UniversalMedia(
      id: json['id'],
      idMal: json['idMal'],
      title: UniversalTitleMapper.fromJson(
        Map<String, dynamic>.from(json['title'] ?? {}),
      ),
      coverImage: UniversalCoverImageMapper.fromJson(
        Map<String, dynamic>.from(json['coverImage'] ?? {}),
      ),
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
          ? UniversalFuzzyDateMapper.fromJson(
              Map<String, dynamic>.from(json['startDate']),
            )
          : null,
      endDate: json['endDate'] != null
          ? UniversalFuzzyDateMapper.fromJson(
              Map<String, dynamic>.from(json['endDate']),
            )
          : null,
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      synonyms:
          (json['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      source: json['source'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? UniversalNextAiringEpisodeMapper.fromJson(
              Map<String, dynamic>.from(json['nextAiringEpisode']),
            )
          : null,
      rankings:
          (json['rankings'] as List?)
              ?.map(
                (e) => UniversalMediaRankingMapper.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      characters:
          (json['characters'] as List?)
              ?.map(
                (e) =>
                    UniversalCharacterMapper.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      staff:
          (json['staff'] as List?)
              ?.map(
                (e) => UniversalStaffMapper.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      relations:
          (json['relations'] as List?)
              ?.map(
                (e) => UniversalMediaRelationMapper.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      recommendations:
          (json['recommendations'] as List?)
              ?.map(
                (e) => UniversalMediaMapper.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      studios:
          (json['studios'] as List?)
              ?.map(
                (e) => UniversalStudioMapper.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      trailer: json['trailer'] != null
          ? UniversalTrailerMapper.fromJson(
              Map<String, dynamic>.from(json['trailer']),
            )
          : null,
      siteUrl: json['siteUrl'],
    );
  }
}

class UniversalTitleMapper {
  static UniversalTitle fromAnilist(Map<String, dynamic> json) {
    return UniversalTitle(
      romaji: json['romaji'],
      english: json['english'],
      native: json['native'],
    );
  }

  static UniversalTitle fromJson(Map<String, dynamic> json) {
    return UniversalTitle(
      romaji: json['romaji'],
      english: json['english'],
      native: json['native'],
    );
  }
}

class UniversalCoverImageMapper {
  static UniversalCoverImage fromAnilist(Map<String, dynamic> json) {
    return UniversalCoverImage(
      large: json['large'],
      medium: json['medium'],
    );
  }

  static UniversalCoverImage fromJson(Map<String, dynamic> json) {
    return UniversalCoverImage(large: json['large'], medium: json['medium']);
  }
}

class UniversalNextAiringEpisodeMapper {
  static UniversalNextAiringEpisode fromJson(Map<String, dynamic> json) {
    return UniversalNextAiringEpisode(
      episode: json['episode'],
      airingAt: json['airingAt'],
      timeUntilAiring: json['timeUntilAiring'],
    );
  }
}

class UniversalMediaRankingMapper {
  static UniversalMediaRanking fromAnilist(Map<String, dynamic> rank) {
    return UniversalMediaRanking(
      rank: rank['rank'],
      type: rank['type'] ?? '',
      context: rank['context'] ?? '',
      season: rank['season'],
      year: rank['year'],
      allTime: rank['allTime'] ?? false,
    );
  }

  static UniversalMediaRanking fromJson(Map<String, dynamic> json) {
    return UniversalMediaRanking(
      rank: json['rank'],
      type: json['type'] ?? '',
      context: json['context'] ?? '',
      season: json['season'],
      year: json['year'],
      allTime: json['allTime'] ?? false,
    );
  }
}

class UniversalCharacterMapper {
  static UniversalCharacter fromAnilist(Map<String, dynamic> edge) {
    final charNode = edge['node'] ?? {};
    return UniversalCharacter(
      id: charNode['id'] ?? 0,
      name: charNode['name']?['full'] ?? 'Unknown',
      image: charNode['image']?['large'],
      role: edge['role'],
    );
  }

  static UniversalCharacter fromJson(Map<String, dynamic> json) {
    return UniversalCharacter(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: json['image'],
      role: json['role'],
    );
  }
}

class UniversalStaffMapper {
  static UniversalStaff fromAnilist(Map<String, dynamic> edge) {
    final staffNode = edge['node'] ?? {};
    return UniversalStaff(
      id: staffNode['id'],
      name: staffNode['name'] != null
          ? UniversalStaffNameMapper.fromAnilist(staffNode['name'])
          : null,
      image: staffNode['image'] != null
          ? UniversalStaffImageMapper.fromAnilist(staffNode['image'])
          : null,
      role: edge['role'],
    );
  }

  static UniversalStaff fromJson(Map<String, dynamic> json) {
    return UniversalStaff(
      id: json['id'],
      name: json['name'] != null
          ? UniversalStaffNameMapper.fromJson(Map<String, dynamic>.from(json['name']))
          : null,
      image: json['image'] != null
          ? UniversalStaffImageMapper.fromJson(
              Map<String, dynamic>.from(json['image']),
            )
          : null,
      role: json['role'],
    );
  }
}

class UniversalStaffNameMapper {
  static UniversalStaffName fromAnilist(Map<String, dynamic> name) {
    return UniversalStaffName(full: name['full'], native: name['native']);
  }

  static UniversalStaffName fromJson(Map<String, dynamic> json) {
    return UniversalStaffName(full: json['full'], native: json['native']);
  }
}

class UniversalStaffImageMapper {
  static UniversalStaffImage fromAnilist(Map<String, dynamic> image) {
    return UniversalStaffImage(large: image['large'], medium: image['medium']);
  }

  static UniversalStaffImage fromJson(Map<String, dynamic> json) {
    return UniversalStaffImage(large: json['large'], medium: json['medium']);
  }
}

class UniversalMediaRelationMapper {
  static UniversalMediaRelation fromAnilist(Map<String, dynamic> edge) {
    final relNode = edge['node'] ?? {};
    return UniversalMediaRelation(
      relationType: edge['relationType'] ?? 'UNKNOWN',
      media: UniversalMediaMapper.fromAnilist(relNode),
    );
  }

  static UniversalMediaRelation fromJson(Map<String, dynamic> json) {
    return UniversalMediaRelation(
      relationType: json['relationType'] ?? 'UNKNOWN',
      media: UniversalMediaMapper.fromJson(
        Map<String, dynamic>.from(json['media'] ?? {}),
      ),
    );
  }
}

class UniversalStudioMapper {
  static UniversalStudio fromAnilist(Map<String, dynamic> studioEdge) {
    return UniversalStudio(
      name: studioEdge['name'] ?? '',
      isMain: studioEdge['isMain'] ?? false,
    );
  }

  static UniversalStudio fromJson(Map<String, dynamic> json) {
    return UniversalStudio(
      name: json['name'] ?? '',
      isMain: json['isMain'] ?? false,
    );
  }
}

class UniversalTrailerMapper {
  static UniversalTrailer fromAnilist(Map<String, dynamic> trailer) {
    return UniversalTrailer(
      id: trailer['id'] ?? '',
      site: trailer['site'],
      thumbnail: trailer['thumbnail'],
    );
  }

  static UniversalTrailer fromJson(Map<String, dynamic> json) {
    return UniversalTrailer(
      id: json['id'] ?? '',
      site: json['site'],
      thumbnail: json['thumbnail'],
    );
  }
}

class UniversalFuzzyDateMapper {
  static UniversalFuzzyDate fromAnilist(Map<String, dynamic> date) {
    return UniversalFuzzyDate(
      year: date['year'],
      month: date['month'],
      day: date['day'],
    );
  }

  static UniversalFuzzyDate fromMal(String dateStr) {
    final parts = dateStr.split('-');
    return UniversalFuzzyDate(
      year: parts.isNotEmpty ? int.tryParse(parts[0]) : null,
      month: parts.length > 1 ? int.tryParse(parts[1]) : null,
      day: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
  }

  static UniversalFuzzyDate fromJson(Map<String, dynamic> json) {
    return UniversalFuzzyDate(
      year: json['year'],
      month: json['month'],
      day: json['day'],
    );
  }
}
