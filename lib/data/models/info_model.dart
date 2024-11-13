class AnimeInfo {
  final bool success;
  final AnimeData? data;

  AnimeInfo({
    required this.success,
    this.data,
  });

  factory AnimeInfo.fromJson(Map<String, dynamic> json) {
    return AnimeInfo(
      success: json['success'] as bool,
      data: json['data'] != null ? AnimeData.fromJson(json['data']) : null,
    );
  }
}

class AnimeData {
  final Anime? anime;
  // final List<AnimeBasic>? seasons;
  // final List<AnimeBasic>? mostPopularAnimes;
  // final List<AnimeBasic>? relatedAnimes;
  // final List<AnimeBasic>? recommendedAnimes;

  AnimeData({
    this.anime,
    // this.seasons,
    // this.mostPopularAnimes,
    // this.relatedAnimes,
    // this.recommendedAnimes,
  });

  factory AnimeData.fromJson(Map<String, dynamic> json) {
    return AnimeData(
      anime: json['anime'] != null ? Anime.fromJson(json['anime']) : null,
      // // seasons: (json['seasons'] as List?)?.map((e) => AnimeBasic.fromJson(e)).toList(),
      // // mostPopularAnimes: (json['mostPopularAnimes'] as List?)?.map((e) => AnimeBasic.fromJson(e)).toList(),
      // // relatedAnimes: (json['relatedAnimes'] as List?)?.map((e) => AnimeBasic.fromJson(e)).toList(),
      // // recommendedAnimes: (json['recommendedAnimes'] as List?)?.map((e) => AnimeBasic.fromJson(e)).toList(),
    );
  }
}

class Anime {
  final AnimeInfoDetails? info;
  final AnimeMoreInfo? moreInfo;

  Anime({
    this.info,
    this.moreInfo,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      info: json['info'] != null ? AnimeInfoDetails.fromJson(json['info']) : null,
      moreInfo: json['moreInfo'] != null ? AnimeMoreInfo.fromJson(json['moreInfo']) : null,
    );
  }
}

class AnimeInfoDetails {
  final String id;
  final int anilistId;
  final int malId;
  final String name;
  final String poster;
  final String description;
  final AnimeStats? stats;
  final List<PromoVideo>? promotionalVideos;
  final List<CharacterVoiceActor>? charactersVoiceActors;

  AnimeInfoDetails({
    required this.id,
    required this.anilistId,
    required this.malId,
    required this.name,
    required this.poster,
    required this.description,
    this.stats,
    this.promotionalVideos,
    this.charactersVoiceActors,
  });

  factory AnimeInfoDetails.fromJson(Map<String, dynamic> json) {
    return AnimeInfoDetails(
      id: json['id'],
      anilistId: json['anilistId'],
      malId: json['malId'],
      name: json['name'],
      poster: json['poster'],
      description: json['description'],
      stats: json['stats'] != null ? AnimeStats.fromJson(json['stats']) : null,
      promotionalVideos: (json['promotionalVideos'] as List?)?.map((e) => PromoVideo.fromJson(e)).toList() ?? [],
      charactersVoiceActors: (json['charactersVoiceActors'] as List?)?.map((e) => CharacterVoiceActor.fromJson(e)).toList() ?? [],
    );
  }
}

class AnimeStats {
  final String? rating;
  final String? quality;
  final int? episodesSub;
  final int? episodesDub;
  final String? type;
  final String? duration;

  AnimeStats({
    required this.rating,
    required this.quality,
    required this.episodesSub,
    required this.episodesDub,
    required this.type,
    required this.duration,
  });

  factory AnimeStats.fromJson(Map<String, dynamic> json) {
    return AnimeStats(
      rating: json['rating'],
      quality: json['quality'],
      episodesSub: json['episodes']['sub'],
      episodesDub: json['episodes']['dub'],
      type: json['type'],
      duration: json['duration'],
    );
  }
}

class PromoVideo {
  final String title;
  final String source;
  final String thumbnail;

  PromoVideo({
    required this.title,
    required this.source,
    required this.thumbnail,
  });

  factory PromoVideo.fromJson(Map<String, dynamic> json) {
    return PromoVideo(
      title: json['title'],
      source: json['source'],
      thumbnail: json['thumbnail'],
    );
  }
}

class CharacterVoiceActor {
  final Character character;
  final VoiceActor voiceActor;

  CharacterVoiceActor({
    required this.character,
    required this.voiceActor,
  });

  factory CharacterVoiceActor.fromJson(Map<String, dynamic> json) {
    return CharacterVoiceActor(
      character: Character.fromJson(json['character']),
      voiceActor: VoiceActor.fromJson(json['voiceActor']),
    );
  }
}

class Character {
  final String id;
  final String poster;
  final String name;
  final String cast;

  Character({
    required this.id,
    required this.poster,
    required this.name,
    required this.cast,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      poster: json['poster'],
      name: json['name'],
      cast: json['cast'],
    );
  }
}

class VoiceActor {
  final String id;
  final String poster;
  final String name;
  final String cast;

  VoiceActor({
    required this.id,
    required this.poster,
    required this.name,
    required this.cast,
  });

  factory VoiceActor.fromJson(Map<String, dynamic> json) {
    return VoiceActor(
      id: json['id'],
      poster: json['poster'],
      name: json['name'],
      cast: json['cast'],
    );
  }
}

class AnimeMoreInfo {
  final String? japanese;
  final String? synonyms;
  final String? aired;
  final String? premiered;
  final String? duration;
  final String? status;
  final String? malscore;
  final List<String>? genres;
  final String studios;
  final List<String> producers;

  AnimeMoreInfo({
    required this.japanese,
    required this.synonyms,
    required this.aired,
    required this.premiered,
    required this.duration,
    required this.status,
    required this.malscore,
    required this.genres,
    required this.studios,
    required this.producers,
  });

  factory AnimeMoreInfo.fromJson(Map<String, dynamic> json) {
    return AnimeMoreInfo(
      japanese: json['japanese'] ,
      synonyms: json['synonyms'] ,
      aired: json['aired'] ,
      premiered: json['premiered'] ,
      duration: json['duration'] ,
      status: json['status'] ,
      malscore: json['malscore'] ,
      genres: List<String>.from(json['genres']),
      studios: json['studios'],
      producers: List<String>.from(json['producers']),
    );
  }
}

class AnimeBasic {
  final String id;
  final String name;
  final String jname;
  final String poster;
  final AnimeStats episodes;
  final String type;

  AnimeBasic({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
    required this.type,
  });

  factory AnimeBasic.fromJson(Map<String, dynamic> json) {
    return AnimeBasic(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeStats.fromJson(json['episodes']),
      type: json['type'],
    );
  }
}
