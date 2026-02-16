import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';

class AnimeOnsenProvider extends AnimeProvider {
  // Token management variables
  String? _animeOnsenToken;
  int _tokenExpiration = 0;

  AnimeOnsenProvider()
    : super(
        baseUrl: "https://animeonsen.xyz",
        apiUrl: "https://api.animeonsen.xyz/v4",
        providerName: "animeonsen",
      );

  @override
  Map<String, String> get headers => {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
  };

  // --- Token Logic ---

  Future<void> _checkAndUpdateToken() async {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000;

    // Check if token is missing or expired (with 1 hour buffer)
    if (_animeOnsenToken == null || _tokenExpiration < (currentTime + 3600)) {
      // print("[PROVIDER] Generating new animeonsen token");
      final tokenData = await _getToken();

      _animeOnsenToken = tokenData['token'];
      _tokenExpiration = (tokenData['expiration'] as int) + currentTime.toInt();
    }
  }

  Future<Map<String, dynamic>> _getToken() async {
    final url = "https://auth.animeonsen.xyz/oauth/token";
    final body = {
      "client_id": "f296be26-28b5-4358-b5a1-6259575e23b7",
      "client_secret":
          "349038c4157d0480784753841217270c3c5b35f4281eaee029de21cb04084235",
      "grant_type": "client_credentials",
    };

    final res = await UniversalHttpClient.instance.post(
      Uri.parse(url),
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception("Exception: couldnt generate AO token");
    }

    final Map<String, dynamic> jsoned = jsonDecode(res.body);
    return {
      'expiration': jsoned['expires_in'],
      'token': jsoned['access_token'],
    };
  }

  // --- Interface Implementation ---

  @override
  Future<DetailPage> getDetails(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
    await _checkAndUpdateToken();

    final url = Uri.parse('$apiUrl/content/$animeId/episodes');
    final apiHeader = {"Authorization": "Bearer $_animeOnsenToken", ...headers};

    final res = await UniversalHttpClient.instance.get(url, headers: apiHeader, cacheConfig: CacheConfig.medium);

    if (res.statusCode != 200) {
      throw Exception("Failed to load episodes: ${res.statusCode}");
    }

    final Map<String, dynamic> jsoned = jsonDecode(res.body);
    List<EpisodeDataModel> episodes = [];

    int i = 1;
    for (final item in jsoned.keys) {
      final String? title = jsoned[item]["contentTitle_episode_en"];

      // Combine item ID and animeId to pass sufficient data to getSources later
      final String uniqueId = "$item+$animeId";
      final int epNum = int.tryParse(item) ?? i;

      episodes.add(
        EpisodeDataModel(
          id: uniqueId,
          number: epNum,
          title: (title?.isEmpty ?? true) ? "Episode $epNum" : title!,
          thumbnail: null,
          isFiller: false,
        ),
      );
      i++;
    }

    // Sort by episode number
    episodes.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    return BaseEpisodeModel(episodes: episodes, totalEpisodes: episodes.length);
  }

  @override
  Future<HomePage> getHome() {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getPage(String route, int page) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    await _checkAndUpdateToken();

    final query = keyword.replaceAll("-", "");
    final url = Uri.parse("$apiUrl/search/$query");

    final apiHeaders = {
      "Authorization": "Bearer $_animeOnsenToken",
      ...headers,
    };

    final res = await UniversalHttpClient.instance.get(
      url,
      headers: apiHeaders,
      cacheConfig: CacheConfig.medium
    );

    if (res.statusCode != 200) {
      return SearchPage(results: []);
    }

    final jsoned = jsonDecode(res.body);
    final List<BaseAnimeModel> searchResults = [];

    if (jsoned['result'] != null) {
      jsoned['result'].forEach((item) {
        final String id = item['content_id'];
        searchResults.add(
          BaseAnimeModel(
            id: id,
            anilistId: null,
            name: item['content_title_en'] ?? item['content_title'],
            jname: item['content_title_jp'],
            type: null,
            description: null,
            poster: "https://api.animeonsen.xyz/v4/image/210x300/$id",
            banner: null,
            genres: [],
            releaseDate: null,
            number: null,
          ),
        );
      });
    }

    return SearchPage(results: searchResults);
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    final parts = episodeId.split("+");
    if (parts.length < 2) {
      throw Exception("Invalid Episode ID format");
    }

    final episodeNumber = parts[0];
    final actualAnimeId = parts[1];

    final streamUrl =
        "https://cdn.animeonsen.xyz/video/mp4-dash/$actualAnimeId/$episodeNumber/manifest.mpd";
    final subtitleUrl =
        "https://api.animeonsen.xyz/v4/subtitles/$actualAnimeId/en-US/$episodeNumber";

    final source = Source(
      url: streamUrl,
      quality: "AnimeOnsen - Auto",
    );

    final track = Subtitle(url: subtitleUrl, lang: "English", isSub: true);

    return BaseSourcesModel(
      sources: [source],
      tracks: [track],
      intro: Intro(start: 0, end: 0),
      outro: Intro(start: 0, end: 0),
      headers: {'Referer': "https://animeonsen.xyz"},
    );
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    return BaseServerModel.defaultServer;
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }
}
