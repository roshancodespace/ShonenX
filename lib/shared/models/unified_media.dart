// ignore_for_file: constant_identifier_names

enum MediaType {
  ANIME,
  MANGA,
  NOVEL,
  TV,
  MOVIE;

  String get displayName {
    switch (this) {
      case MediaType.ANIME:
        return 'Anime';
      case MediaType.MANGA:
        return 'Manga';
      case MediaType.NOVEL:
        return 'Novel';
      case MediaType.TV:
        return 'TV Series';
      case MediaType.MOVIE:
        return 'Movie';
    }
  }

  String get id => name.toLowerCase();

  static MediaType fromId(String id) => MediaType.values.firstWhere(
    (t) => t.id == id,
    orElse: () => throw ArgumentError('Invalid MediaType id: $id'),
  );
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

class MediaExternalIds {
  final String? anilist;
  final String? mal;
  final String? simkl;
  final String? tmdb;
  final String? kitsu;
  final Map<String, String> extra;

  const MediaExternalIds({
    this.anilist,
    this.mal,
    this.simkl,
    this.tmdb,
    this.kitsu,
    this.extra = const {},
  });

  String? get(String key) {
    switch (key.toLowerCase()) {
      case 'anilist':
        return anilist;
      case 'mal':
      case 'myanimelist':
        return mal;
      case 'simkl':
        return simkl;
      case 'tmdb':
        return tmdb;
      case 'kitsu':
        return kitsu;
      default:
        return extra[key];
    }
  }

  MediaExternalIds copyWith({
    String? anilist,
    String? mal,
    String? simkl,
    String? tmdb,
    String? kitsu,
    Map<String, String>? extra,
  }) {
    return MediaExternalIds(
      anilist: anilist ?? this.anilist,
      mal: mal ?? this.mal,
      simkl: simkl ?? this.simkl,
      tmdb: tmdb ?? this.tmdb,
      kitsu: kitsu ?? this.kitsu,
      extra: extra ?? this.extra,
    );
  }

  MediaExternalIds merge(MediaExternalIds? other) {
    if (other == null) return this;
    return MediaExternalIds(
      anilist: other.anilist ?? anilist,
      mal: other.mal ?? mal,
      simkl: other.simkl ?? simkl,
      tmdb: other.tmdb ?? tmdb,
      kitsu: other.kitsu ?? kitsu,
      extra: {...extra, ...other.extra},
    );
  }

  Map<String, dynamic> toMap() => {
    if (anilist != null && anilist!.isNotEmpty) 'anilist': anilist,
    if (mal != null && mal!.isNotEmpty) 'mal': mal,
    if (simkl != null && simkl!.isNotEmpty) 'simkl': simkl,
    if (tmdb != null && tmdb!.isNotEmpty) 'tmdb': tmdb,
    if (kitsu != null && kitsu!.isNotEmpty) 'kitsu': kitsu,
    ...extra,
  };

  factory MediaExternalIds.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const MediaExternalIds();
    final extra = <String, String>{};
    String? anilist, mal, simkl, tmdb, kitsu;
    for (final entry in map.entries) {
      final val = entry.value?.toString();
      if (val == null || val.isEmpty) continue;
      switch (entry.key.toLowerCase()) {
        case 'anilist':
          anilist = val;
          break;
        case 'mal':
        case 'myanimelist':
          mal = val;
          break;
        case 'simkl':
          simkl = val;
          break;
        case 'tmdb':
          tmdb = val;
          break;
        case 'kitsu':
          kitsu = val;
          break;
        default:
          extra[entry.key] = val;
      }
    }
    return MediaExternalIds(
      anilist: anilist,
      mal: mal,
      simkl: simkl,
      tmdb: tmdb,
      kitsu: kitsu,
      extra: extra,
    );
  }

  bool get isEmpty =>
      anilist == null &&
      mal == null &&
      simkl == null &&
      tmdb == null &&
      kitsu == null &&
      extra.isEmpty;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaExternalIds) return false;
    if (anilist != other.anilist ||
        mal != other.mal ||
        simkl != other.simkl ||
        tmdb != other.tmdb ||
        kitsu != other.kitsu ||
        extra.length != other.extra.length) {
      return false;
    }
    for (final key in extra.keys) {
      if (extra[key] != other.extra[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    anilist,
    mal,
    simkl,
    tmdb,
    kitsu,
    Object.hashAll(extra.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

class UnifiedMedia {
  final String id;
  final MediaType type;
  final String? sourceId;
  final String? sourceName;
  final String? providerId;
  final MediaExternalIds externalIds;
  final String? _idMal;
  String? get idMal => externalIds.mal ?? _idMal;

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
    String? idMal,
    MediaExternalIds? externalIds,
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
  }) : _idMal = idMal,
       externalIds = (externalIds ?? const MediaExternalIds()).merge(
         idMal != null ? MediaExternalIds(mal: idMal) : null,
       );

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
    String? getValid(String? val) =>
        (val != null && val.trim().isNotEmpty) ? val.trim() : null;

    final e = getValid(english);
    final r = getValid(romaji);
    final n = getValid(native);

    switch (preference) {
      case TitlePreference.english:
        return e ?? r ?? n ?? 'Unknown';
      case TitlePreference.romaji:
        return r ?? e ?? n ?? 'Unknown';
      case TitlePreference.native:
        return n ?? r ?? e ?? 'Unknown';
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
      externalIds: externalIds.merge(other.externalIds),
      idMal: other.idMal ?? idMal,
      format: other.format ?? format,

      title: title.merge(other.title),

      cover: other.cover ?? cover,
      score: other.score ?? score,
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
