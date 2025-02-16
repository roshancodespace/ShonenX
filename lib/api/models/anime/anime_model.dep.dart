// Depecrated don't use
abstract class BaseAnime {
  int? get rank;

  String? get id;

  String? get name;

  String? get jname;

  String? get description;

  String? get poster;

  String? get url;

  String? get type;

  String? get banner;

  Episodes? get episodes;

  int? get number;

  String? get duration;

  String? get releaseDate;

  List<String>? get genres;

  int? get anilistId;
}

abstract class Episodes {
  int? get sub;

  int? get dub;

  int? get total;
}

class EpisodesModel implements Episodes {
  @override
  final int? sub;
  @override
  final int? dub;
  @override
  final int? total;

  const EpisodesModel({this.sub, this.dub, this.total});
}

class BaseAnimeModel implements BaseAnime {
  @override
  final int? rank;
  @override
  final String? id;
  @override
  final String? name;
  @override
  final String? jname;
  @override
  final String? description;
  @override
  final String? poster;
  @override
  final String? banner;
  @override
  final String? url;
  @override
  final String? type;
  @override
  final Episodes? episodes;
  @override
  final int? number;
  @override
  final String? duration;
  @override
  final String? releaseDate;
  @override
  final List<String>? genres;
  @override
  final int? anilistId;

  const BaseAnimeModel({
    this.rank,
    this.id,
    this.name,
    this.jname,
    this.description,
    this.poster,
    this.banner,
    this.url,
    this.duration,
    this.type,
    this.episodes,
    this.number,
    this.releaseDate,
    this.genres,
    this.anilistId,
  });
}
