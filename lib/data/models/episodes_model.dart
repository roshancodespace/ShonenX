class EpisodesData {
  final bool success;
  final EpisodeInfo? data;

  EpisodesData({
    required this.success,
    this.data,
  });

  factory EpisodesData.fromJson(Map<String, dynamic> json) {
    return EpisodesData(
      success: json['success'] as bool,
      data: json['data'] != null ? EpisodeInfo.fromJson(json['data']) : null,
    );
  }
}

class EpisodeInfo {
  final int totalEpisodes;
  final List<Episode> episodes;

  EpisodeInfo({
    required this.totalEpisodes,
    required this.episodes,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      totalEpisodes: json['totalEpisodes'] ?? 0,
      episodes: (json['episodes'] as List)
              .map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class Episode {
  final String title;
  final String episodeId;
  final int number;
  final bool isFiller;

  Episode({
    required this.title,
    required this.episodeId,
    required this.number,
    required this.isFiller,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'] ?? '',
      episodeId: json['episodeId'] ?? '',
      number: json['number'] ?? 0,
      isFiller: json['isFiller'] ?? false,
    );
  }
}

// Model for the Episode Servers response
class EpisodeServersModel {
  final String episodeId;
  final int episodeNo;
  final List<Server> sub;
  final List<Server> dub;
  final List<Server> raw;

  EpisodeServersModel({
    required this.episodeId,
    required this.episodeNo,
    required this.sub,
    required this.dub,
    required this.raw,
  });

  factory EpisodeServersModel.fromJson(Map<String, dynamic> json) {
    return EpisodeServersModel(
      episodeId: json['data']['episodeId'],
      episodeNo: json['data']['episodeNo'],
      sub:
          (json['data']['sub'] as List).map((e) => Server.fromJson(e)).toList(),
      dub:
          (json['data']['dub'] as List).map((e) => Server.fromJson(e)).toList(),
      raw:
          (json['data']['raw'] as List).map((e) => Server.fromJson(e)).toList(),
    );
  }
}

// Model for a server
class Server {
  final int serverId;
  final String serverName;

  Server({
    required this.serverId,
    required this.serverName,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      serverId: json['serverId'],
      serverName: json['serverName'],
    );
  }
}
