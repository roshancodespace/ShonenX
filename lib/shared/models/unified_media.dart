// ignore_for_file: constant_identifier_names

enum MediaType {
  ANIME,
  MANGA,
  NOVEL;

  String get displayName {
    switch (this) {
      case MediaType.ANIME:
        return 'Anime';
      case MediaType.MANGA:
        return 'Manga';
      case MediaType.NOVEL:
        return 'Novel';
    }
  }

  String get id => name.toLowerCase();
}

enum TitlePreference {
  english('English'),
  romaji('Romaji'),
  native('Native');

  final String displayName;
  const TitlePreference(this.displayName);
}

class MediaExternalLink {
  final String id;
  final String url;
  final String site;
  final String? icon;

  const MediaExternalLink({
    required this.id,
    required this.url,
    required this.site,
    this.icon,
  });
}

class MediaCharacter {
  final String id;
  final String name;
  final String? nativeName;
  final String? role;
  final String? image;
  final String? description;
  final String? voiceActorName;
  final String? voiceActorImage;

  const MediaCharacter({
    required this.id,
    required this.name,
    this.nativeName,
    this.role,
    this.image,
    this.description,
    this.voiceActorName,
    this.voiceActorImage,
  });
}

class UnifiedMedia {
  final String id;
  final MediaType type;
  final String? sourceId;
  final String? sourceName;
  final String? providerId;
  final String? idMal;
  final MediaTitle title;
  final String? format;
  final String? cover;
  final double? score;
  final String? banner;
  final String? description;
  final List<MediaTag>? tags;
  final List<String>? genres;
  final bool? isAdult;
  final String? status;
  final int? episodes;
  final int? chapters;
  final int? volumes;
  final int? duration;
  final String? source;
  final int? popularity;
  final int? favourites;
  final List<String>? studios;
  final List<String>? synonyms;
  final List<MediaExternalLink>? externalLinks;
  final List<MediaCharacter>? characters;
  final String? season;
  final DateTime? airingAt;
  final int? nextEpisode;
  final String? relationType;
  final List<UnifiedMedia>? relations;
  final List<UnifiedMedia>? recommendations;

  UnifiedMedia({
    required this.id,
    required this.type,
    this.sourceId,
    this.sourceName,
    this.title = const MediaTitle(),
    this.providerId,
    this.idMal,
    this.format,
    this.cover,
    this.score,
    this.banner,
    this.description,
    this.tags = const [],
    this.genres = const [],
    this.isAdult,
    this.status,
    this.episodes,
    this.chapters,
    this.volumes,
    this.duration,
    this.source,
    this.popularity,
    this.favourites,
    this.studios = const [],
    this.synonyms = const [],
    this.externalLinks = const [],
    this.characters = const [],
    this.season,
    this.airingAt,
    this.nextEpisode,
    this.relationType,
    this.relations = const [],
    this.recommendations = const [],
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UnifiedMedia && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MediaTitle {
  final String? romaji;
  final String? english;
  final String? native;

  const MediaTitle({this.romaji, this.english, this.native});

  String get availableTitle {
    switch (preference) {
      case TitlePreference.english:
        return english ?? romaji ?? native ?? 'Unknown';
      case TitlePreference.romaji:
        return romaji ?? english ?? native ?? 'Unknown';
      case TitlePreference.native:
        return native ?? romaji ?? english ?? 'Unknown';
    }
  }

  static TitlePreference preference = TitlePreference.english;
}

class MediaTag {
  final String id;
  final String name;
  final String category;

  MediaTag({required this.id, required this.name, required this.category});
}

extension UnifiedMediaX on UnifiedMedia {
  UnifiedMedia merge(UnifiedMedia? other) {
    if (other == null) return this;

    return UnifiedMedia(
      id: other.id.isNotEmpty ? other.id : id,
      type: other.type,

      sourceId: other.sourceId ?? sourceId,
      sourceName: other.sourceName ?? sourceName,
      providerId: other.providerId ?? providerId,
      idMal: other.idMal ?? idMal,
      format: other.format ?? format,

      title: title.merge(other.title),

      cover: other.cover ?? cover,
      banner: other.banner ?? banner,
      description: other.description ?? description,

      tags: (other.tags != null && other.tags!.isNotEmpty) ? other.tags : tags,

      genres: (other.genres != null && other.genres!.isNotEmpty)
          ? other.genres
          : genres,

      isAdult: other.isAdult ?? isAdult,
      status: other.status ?? status,
      episodes: other.episodes ?? episodes,
      chapters: other.chapters ?? chapters,
      volumes: other.volumes ?? volumes,
      duration: other.duration ?? duration,
      source: other.source ?? source,
      popularity: other.popularity ?? popularity,
      favourites: other.favourites ?? favourites,
      studios: (other.studios != null && other.studios!.isNotEmpty)
          ? other.studios
          : studios,
      synonyms: (other.synonyms != null && other.synonyms!.isNotEmpty)
          ? other.synonyms
          : synonyms,
      externalLinks:
          (other.externalLinks != null && other.externalLinks!.isNotEmpty)
          ? other.externalLinks
          : externalLinks,
      characters: (other.characters != null && other.characters!.isNotEmpty)
          ? other.characters
          : characters,
      season: other.season ?? season,
      airingAt: other.airingAt ?? airingAt,
      nextEpisode: other.nextEpisode ?? nextEpisode,
      relationType: other.relationType ?? relationType,

      relations: (other.relations != null && other.relations!.isNotEmpty)
          ? other.relations
          : relations,

      recommendations:
          (other.recommendations != null && other.recommendations!.isNotEmpty)
          ? other.recommendations
          : recommendations,
    );
  }
}

extension MediaTitleX on MediaTitle {
  MediaTitle merge(MediaTitle? other) {
    if (other == null) return this;

    return MediaTitle(
      romaji: other.romaji ?? romaji,
      english: other.english ?? english,
      native: other.native ?? native,
    );
  }
}
