import 'dart:convert';
import 'dart:math';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:html/parser.dart' as html;
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';

class AnimePaheProvider extends AnimeProvider {
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36';

  final Map<String, String> _sourceHeaders = {
    'Cookie': '__ddg1=;__ddg2_=',
    'Referer': 'https://animepahe.si/',
    'User-Agent': _userAgent,
  };

  AnimePaheProvider()
    : super(
        baseUrl: "https://animepahe.si",
        apiUrl: "https://animepahe.si/api",
        providerName: "animepahe",
      );

  @override
  Map<String, String> get headers => _sourceHeaders;

  @override
  Future<DetailPage> getDetails(String animeId) {
    throw UnimplementedError();
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
    final query = keyword.replaceAll("-", " ");
    final url = Uri.parse("$apiUrl?m=search&q=$query");

    final res = await UniversalHttpClient.instance.get(url, headers: headers);
    final Map<String, dynamic> decoded = json.decode(res.body);

    final List<dynamic>? results = decoded['data'];
    final List<BaseAnimeModel> searchResults = [];

    if (results != null) {
      for (final result in results) {
        searchResults.add(
          BaseAnimeModel(
            id: result['session'],
            anilistId: null,
            name: result['title'],
            jname: null,
            type: result['type'],
            description: null,
            poster: result['poster'],
            banner: null,
            genres: [],
            releaseDate: result['year']?.toString(),
            number: result['episodes'],
          ),
        );
      }
    }

    return SearchPage(results: searchResults);
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
    List<dynamic> list = [];
    final String url = "$apiUrl?m=release&id=$animeId&sort=episode_asc";

    final res = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
    );
    var bodyDecoded = json.decode(res.body);

    if (bodyDecoded['data'] != null) {
      list.add(bodyDecoded['data']);
    }

    final int totalPages = bodyDecoded['last_page'] ?? 1;

    for (int i = 1; i < totalPages; i++) {
      final nextRes = await UniversalHttpClient.instance.get(
        Uri.parse("$url&page=${i + 1}"),
        headers: headers,
        cacheConfig:
            (i == (totalPages - 1) || (i == 0 && i == (totalPages - 1)))
            ? CacheConfig.short
            : CacheConfig.year,
      );
      final nextBody = json.decode(nextRes.body);
      if (nextBody['data'] != null) {
        list.add(nextBody['data']);
      }
    }

    final flatList = list.expand((item) => item as List<dynamic>).toList();
    List<EpisodeDataModel> episodes = [];

    for (int i = 0; i < flatList.length; i++) {
      final item = flatList[i];
      final String episodeSession = item['session'];
      final String combinedId = "$animeId+$episodeSession";

      final num? epNumFromApi = item['episode'];
      final int calculatedEpNum = (epNumFromApi != null)
          ? epNumFromApi.toInt()
          : (i + 1);

      // Robust title checking
      String? title = item['title'];
      if (title != null && title.trim().isEmpty) {
        title = null;
      }

      final String? thumbnail = item['snapshot'];
      final bool isFiller = (item['filler'] ?? 0) != 0;

      episodes.add(
        EpisodeDataModel(
          id: combinedId,
          number: calculatedEpNum,
          title: title ?? 'Episode $calculatedEpNum',
          thumbnail: thumbnail,
          isFiller: isFiller,
        ),
      );
    }
    episodes.sort((a, b) => a.number!.compareTo(b.number!));
    return BaseEpisodeModel(episodes: episodes, totalEpisodes: episodes.length);
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    final parts = episodeId.split("+");
    if (parts.length < 2) throw Exception("Invalid ID format");
    final String animeSession = parts[0];
    final String epSession = parts[1];

    final episodeUrl = "https://animepahe.si/play/$animeSession/$epSession";
    final bool isRequestingDub = category?.toLowerCase() == 'dub';

    final data = await UniversalHttpClient.instance.get(
      Uri.parse(episodeUrl),
      headers: headers,
      cacheConfig: CacheConfig.veryLong,
    );
    final document = html.parse(data.body);

    final downloadQualities = document.querySelectorAll('div#pickDownload > a');

    List<Source> sources = [];
    List<Future<void>> extractTasks = [];

    for (final e in downloadQualities) {
      final link = e.attributes['href'] ?? '';
      final text = e.text;

      String quality = "Unknown";
      String size = "?? MB";

      if (text.contains('·')) {
        final split = text.split('·');
        if (split.length >= 2) {
          quality = split[1].trim().replaceAll(RegExp(r'\(\d+MB\)'), "");
        }
      }
      final sizeMatch = RegExp(r'(\d+MB)').firstMatch(text);
      if (sizeMatch != null) {
        size = sizeMatch.group(1)!;
      }

      // Determining audio type from the link attributes or text
      final bool isStreamDub =
          e.attributes['data-audio'] == 'eng' ||
          text.toLowerCase().contains('eng');

      // Filter based on what the user requested (Sub or Dub)
      if (isStreamDub != isRequestingDub) continue;

      extractTasks.add(() async {
        try {
          final mp4Url = await _extractDownloadLink(link);
          sources.add(
            Source(
              url: mp4Url,
              quality: "$quality [$size]",
              type: "mp4",
              isM3U8: false,
              isDub: isStreamDub,
              headers: {
                'Referer': 'https://kwik.cx/',
                'User-Agent': _userAgent,
              },
            ),
          );
        } catch (e) {
          // ignore error
        }
      }());
    }

    await Future.wait(extractTasks);

    return BaseSourcesModel(
      sources: sources,
      tracks: [],
      intro: Intro(start: 0, end: 0),
      outro: Intro(start: 0, end: 0),
      headers: {'Referer': 'https://kwik.cx/', 'User-Agent': _userAgent},
    );
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    final subServers = [
      ServerData(name: "AnimePahe", id: "animepahe", isDub: false),
    ];

    final dubServers = [
      ServerData(name: "AnimePahe", id: "animepahe", isDub: true),
    ];

    return BaseServerModel(sub: subServers, dub: dubServers);
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }

  // --- Kwik Decryption Logic ---

  final _map =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/";

  int _getString(List<String> content, int s1) {
    final s2 = 10;
    final slice = _map.substring(0, s2);
    int acc = 0;
    content.reversed.toList().asMap().forEach((index, c) {
      acc +=
          (RegExp(r'\d').hasMatch(c) ? int.parse(c) : 0) *
          pow(s1, index).toInt();
    });
    String k = "";
    while (acc > 0) {
      k = slice[acc % s2] + k;
      acc = (acc / s2).floor();
    }
    return int.parse(k);
  }

  String _decrypt(String fullKey, String key, int v1, int v2) {
    String r = "";
    int i = 0;
    while (i < fullKey.length) {
      String s = "";
      while (fullKey[i] != key[v2]) {
        s += fullKey[i];
        i++;
      }
      for (int j = 0; j < key.length; j++) {
        s = s.replaceAll(key[j], j.toString());
      }
      r += String.fromCharCode(_getString(s.split(""), v2) - v1);
      i++;
    }
    return r;
  }

  Future<String> _extractDownloadLink(String downloadLink) async {
    if (downloadLink == '') throw Exception("Invalid download link");

    final redirectRegex = RegExp(r'\("href","(.*?)"\)');
    final paramRegex = RegExp(r'\("(\w+)",\d+,"(\w+)",(\d+),(\d+),(\d+)\)');
    final urlRegex = RegExp(r'action="(.+?)"');
    final tokenRegex = RegExp(r'value="(.+?)"');

    final resp = await UniversalHttpClient.instance.get(
      Uri.parse(downloadLink),
      headers: headers,
      cacheConfig: CacheConfig.veryLong,
    );
    final scripts = html.parse(resp.body).querySelectorAll('script');

    String? kwikLink;
    for (var e in scripts) {
      if (kwikLink != null) break;
      if (e.text.isNotEmpty) {
        final matches = redirectRegex.allMatches(e.innerHtml).toList();
        if (matches.isNotEmpty) {
          final candidate = matches.last.group(1);
          if (candidate != null && candidate.contains('http')) {
            kwikLink = candidate;
          }
        }
      }
    }

    if (kwikLink == null) throw Exception("Couldnt extract kwik link");

    final kwikRes = await UniversalHttpClient.instance.get(
      Uri.parse(kwikLink),
      headers: {'referer': downloadLink, 'User-Agent': _userAgent},
      cacheConfig: CacheConfig.veryLong,
    );

    String cookieHeader = "";
    if (kwikRes.headers['set-cookie'] != null) {
      cookieHeader = kwikRes.headers['set-cookie']!;
    }

    final match = paramRegex.firstMatch(kwikRes.body);
    if (match == null) throw Exception("Couldnt extract download params");

    final fullKey = match.group(1)!;
    final key = match.group(2)!;
    final v1 = int.parse(match.group(3)!);
    final v2 = int.parse(match.group(4)!);

    final decrypted = _decrypt(fullKey, key, v1, v2);

    final postUrlMatch = urlRegex.firstMatch(decrypted);
    final tokenMatch = tokenRegex.firstMatch(decrypted);

    if (postUrlMatch == null || tokenMatch == null) {
      throw Exception("Decryption failed to produce valid form data");
    }

    final postUrl = postUrlMatch.group(1)!;
    final token = tokenMatch.group(1)!;

    try {
      final r2 = await UniversalHttpClient.instance.post(
        Uri.parse(postUrl),
        body: {'_token': token},
        headers: {
          'referer': kwikLink,
          'cookie': cookieHeader,
          'User-Agent': _userAgent,
        },
      );
      final mp4Url = r2.headers['location'];
      if (mp4Url == null)
        throw Exception("Couldnt extract media link location");
      return mp4Url;
    } catch (err) {
      rethrow;
    }
  }
}
