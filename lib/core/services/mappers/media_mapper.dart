import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';

class MediaMapper {
  static Media fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      idMal: json['idMal'],
      type: json['type'],
      format: json['format'],
      status: json['status'],
      source: json['source'],
      isAdult: json['isAdult'] ?? false,
      countryOfOrigin: json['countryOfOrigin'],
      title: json['title'] != null ? TitleMapper.fromJson(json['title']) : null,
      coverImage: json['coverImage'] != null
          ? CoverImageMapper.fromJson(json['coverImage'])
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
          ? NextAiringEpisodeMapper.fromJson(json['nextAiringEpisode'])
          : null,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => TagMapper.fromJson(e))
          .toList(),
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      meanScore: (json['meanScore'] as num?)?.toDouble(),
      popularity: json['popularity'],
      favourites: json['favourites'],
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .map((e) => MediaRankingMapper.fromJson(e))
          .toList(),
      studios: (json['studios']?['edges'] as List<dynamic>? ?? [])
          .map((e) => StudioMapper.fromJson(e['node']))
          .toList(),
      relations: (json['relations']?['edges'] as List<dynamic>? ?? [])
          .map((e) => MediaRelationMapper.fromJson(e))
          .toList(),
      recommendations:
          (json['recommendations']?['nodes'] as List<dynamic>? ?? [])
              .map((e) => MediaMapper.fromJson(e['mediaRecommendation']))
              .toList(),
      characters: (json['characters']?['edges'] as List<dynamic>? ?? [])
          .map((e) => CharacterMapper.fromJson(e))
          .toList(),
      staff: (json['staff']?['edges'] as List<dynamic>? ?? [])
          .map((e) => StaffMapper.fromJson(e))
          .toList(),
      trailer:
          json['trailer'] != null ? TrailerMapper.fromJson(json['trailer']) : null,
      siteUrl: json['siteUrl'],
      isFavourite: json['isFavourite'] ?? false,
    );
  }

  static Media fromMal(Map<String, dynamic> node) {
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

  static BaseAnimeModel toBaseAnimeModel(Media media) {
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

  static int? _extractTopRank(List<MediaRanking> rankings) {
    if (rankings.isEmpty) return null;

    final ranked = rankings.where((r) => r.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));

    return ranked.isNotEmpty ? ranked.first.rank : null;
  }
}

class TitleMapper {
  static Title fromJson(Map<String, dynamic> json) {
    return Title(
      romaji: json['romaji'] ?? 'Unknown',
      english: json['english'],
      native: json['native'],
    );
  }
}

class CoverImageMapper {
  static CoverImage fromJson(Map<String, dynamic> json) {
    return CoverImage(
      large: json['large'] ?? '',
      medium: json['medium'] ?? '',
    );
  }
}

class StreamingEpisodeMapper {
  static StreamingEpisode fromJson(Map<String, dynamic> json) {
    return StreamingEpisode(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      site: json['site'],
    );
  }
}

class TrailerMapper {
  static Trailer fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] ?? '',
      site: json['site'],
      thumbnail: json['thumbnail'],
    );
  }
}

class StudioMapper {
  static Studio fromJson(Map<String, dynamic> json) {
    return Studio(
      name: json['name'] ?? '',
      isMain: json['isMain'] ?? false,
    );
  }
}

class MediaRankingMapper {
  static MediaRanking fromJson(Map<String, dynamic> json) {
    return MediaRanking(
      rank: json['rank'] as int?,
      type: json['type'] as String,
      context: json['context'] as String,
      season: json['season'] as String?,
      year: json['year'] as int?,
      allTime: json['allTime'] as bool,
    );
  }
}

class MediaRelationMapper {
  static MediaRelation fromJson(Map<String, dynamic> json) {
    return MediaRelation(
      relationType: json['relationType'] ?? 'UNKNOWN',
      media: MediaMapper.fromJson(json['node'] ?? {}),
    );
  }
}

class CharacterMapper {
  static Character fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return Character(
      id: node['id'] ?? 0,
      name: node['name']?['full'] ?? 'Unknown',
      image: node['image']?['large'],
      role: json['role'],
    );
  }
}

class NextAiringEpisodeMapper {
  static NextAiringEpisode fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
      id: json['id'],
      airingAt: json['airingAt'],
      timeUntilAiring: json['timeUntilAiring'],
      episode: json['episode'],
    );
  }
}

class TagMapper {
  static Tag fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rank: json['rank'],
      isAdult: json['isAdult'] ?? false,
    );
  }
}

class StaffMapper {
  static Staff fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    return Staff(
      id: node['id'],
      name: node['name'] != null ? StaffNameMapper.fromJson(node['name']) : null,
      image: node['image'] != null ? StaffImageMapper.fromJson(node['image']) : null,
      role: json['role'],
    );
  }
}

class StaffNameMapper {
  static StaffName fromJson(Map<String, dynamic> json) {
    return StaffName(
      full: json['full'],
      native: json['native'],
    );
  }
}

class StaffImageMapper {
  static StaffImage fromJson(Map<String, dynamic> json) {
    return StaffImage(
      large: json['large'],
      medium: json['medium'],
    );
  }
}
