abstract class BaseEpisode {
  String? get id;

  String? get title;

  String? get url;

  String? get thumbnail;

  bool? get isFiller;

  int? get number;
}

class BaseEpisodeModel {
  final int? totalEpisodes;
  final List<EpisodeDataModel>? episodes;

  BaseEpisodeModel({this.totalEpisodes, this.episodes});
}

class EpisodeDataModel implements BaseEpisode {
  @override
  final String? id;
  @override
  final String? title;
  @override
  final String? url;
  @override
  final String? thumbnail;
  @override
  final bool? isFiller;
  @override
  final int? number;

  EpisodeDataModel({
    this.id,
    this.title,
    this.url,
    this.thumbnail,
    this.isFiller,
    this.number,
  });
}
