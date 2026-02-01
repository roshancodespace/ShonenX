import 'package:html/parser.dart';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';

class AnizoneProvider implements AnimeProvider {
  @override
  String get baseUrl => "https://anizone.to";

  @override
  String get apiUrl => "https://anizone.to";

  @override
  Map<String, String> get headers => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'Referer': baseUrl,
  };

  @override
  String get providerName => "anizone";

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final url = "$baseUrl/anime?search=$keyword&page=$page";
    final res = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to search");
    }

    final doc = parse(res.body);
    final grid = doc.querySelector("div.grid.grid-cols-1.gap-4");

    if (grid == null) {
      return SearchPage(results: []);
    }

    final List<BaseAnimeModel> searchRes = [];

    for (final child in grid.children) {
      final a = child.querySelector("a");
      final imgTag = child.querySelector("img");

      if (a == null) continue;

      final title = a.attributes['title'] ?? "Unknown";
      final href = a.attributes['href'];
      final img = imgTag?.attributes['src'];

      if (href != null) {
        searchRes.add(BaseAnimeModel(id: href, name: title, poster: img ?? ""));
      }
    }

    return SearchPage(results: searchRes);
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
    final url = animeId.startsWith("http") ? animeId : "$baseUrl$animeId";

    final res = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load episodes page");
    }

    final doc = parse(res.body);
    final list = doc.querySelector("ul.grid.grid-cols-1")?.children;

    if (list == null) {
      return BaseEpisodeModel(episodes: [], totalEpisodes: 0);
    }

    final List<EpisodeDataModel> episodes = [];
    int i = 1;

    for (final item in list) {
      final aTag = item.querySelector("a");
      final imgTag = item.querySelector("img");
      final h3 = item.querySelector("h3");

      final epLink = aTag?.attributes['href'];
      final epImg = imgTag?.attributes['src'];
      final title = h3?.text.trim().split(':').last.trim();

      if (epLink != null) {
        episodes.add(
          EpisodeDataModel(
            id: epLink,
            number: i,
            title: title ?? "Episode $i",
            thumbnail: epImg,
            isFiller: false,
          ),
        );
        i++;
      }
    }

    episodes.sort((a, b) => a.number?.compareTo(b.number as num) ?? 0);

    return BaseEpisodeModel(episodes: episodes, totalEpisodes: episodes.length);
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    final url = episodeId.startsWith("http") ? episodeId : "$baseUrl$episodeId";

    final res = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
      cacheConfig: CacheConfig.infinite,
    );

    if (res.statusCode != 200) {
      return BaseSourcesModel();
    }

    final doc = parse(res.body);
    final mediaPlayer = doc.querySelector("media-player");

    if (mediaPlayer == null) {
      throw Exception("Media player not found");
    }

    final src = mediaPlayer.attributes['src'];

    if (src == null) return BaseSourcesModel();

    // Extract Subtitles
    final tracks = mediaPlayer.querySelectorAll("track");
    final List<Subtitle> subtitles = [];

    for (final track in tracks) {
      final lang = track.attributes['srclang'] ?? "en";
      final trackSrc = track.attributes['src'];
      final kind = track.attributes['kind'];

      if (trackSrc != null && kind == "subtitles") {
        subtitles.add(Subtitle(url: trackSrc, lang: lang, isSub: true));
      }
    }

    final serverLabel =
        doc
            .querySelector(".flex.gap-2.relative.items-center.bg-teal-600")
            ?.text
            .trim() ??
        "Default";

    return BaseSourcesModel(
      headers: headers,
      sources: [Source(url: src, quality: "$serverLabel - Multi")],
      tracks: subtitles,
    );
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    return BaseServerModel.defaultServer;
  }

  // Stubs
  @override
  Future<DetailPage> getDetails(String animeId) => throw UnimplementedError();
  @override
  Future<HomePage> getHome() => throw UnimplementedError();
  @override
  Future<SearchPage> getPage(String route, int page) =>
      throw UnimplementedError();
  @override
  Future<WatchPage> getWatch(String animeId) => throw UnimplementedError();
}
