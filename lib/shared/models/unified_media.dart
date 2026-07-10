// ignore_for_file: constant_identifier_names

enum MediaType {
  ANIME,
  MANGA;

  String get displayName {
    switch (this) {
      case MediaType.ANIME:
        return 'Anime';
      case MediaType.MANGA:
        return 'Manga';
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
