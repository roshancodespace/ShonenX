import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

class HiAnimeSource implements AnimeSource {
  static const String defaultBaseUrl = 'https://hianime.at';
  String _baseUrl = defaultBaseUrl;

  final http.Client _client = http.Client();
  final ScopedLogger _log = AppLogger.scope('HiAnimeSource');

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  SourceInfo get sourceInfo => SourceInfo(
        id: 'inbuilt_hianime',
        name: 'HiAnime (Native)',
        type: SourceType.inbuilt,
        mediaType: MediaType.ANIME,
        iconUrl: 'https://hianime.to/images/favicon.png',
        baseUrl: _baseUrl,
        lang: 'en',
      );

  // In-memory response caches for instant (<100ms) re-queries
  final Map<String, List<UnifiedMedia>> _searchCache = {};
  final Map<String, List<UnifiedEpisode>> _episodesCache = {};
  final Map<String, List<VideoServer>> _serversCache = {};

  @override
  Future<List<SourceSetting>> getSettingsSchema() async {
    return [
      SourceSetting(
        id: 'base_url',
        name: 'Mirror Domain',
        description: 'Primary domain for HiAnime streams',
        type: SettingType.select,
        defaultValue: 'https://hianime.at',
        options: const [
          'https://hianime.at',
          'https://hianime.to',
          'https://aniwatchtv.to',
        ],
      ),
    ];
  }

  Future<bool> saveSetting(String settingId, dynamic value) async {
    if (settingId == 'base_url' && value is String && value.isNotEmpty) {
      _baseUrl = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
      _searchCache.clear();
      _episodesCache.clear();
      _serversCache.clear();
      return true;
    }
    return false;
  }

  @override
  Future<List<String>> getFilterGenres() async => const [
        'Action',
        'Adventure',
        'Comedy',
        'Drama',
        'Fantasy',
        'Horror',
        'Mystery',
        'Romance',
        'Sci-Fi',
        'Slice of Life',
        'Sports',
        'Supernatural',
        'Thriller',
      ];

  @override
  Future<List<String>> getFilterTags() async => const [];

  @override
  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
    List<String> genres = const [],
    List<String> tags = const [],
  }) async {
    final cacheKey = '$query|$page';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    final methodLog = _log.child('search');
    try {
      final cleanQuery = query.trim();
      final url = cleanQuery.isEmpty
          ? '$_baseUrl/top-airing?page=$page'
          : '$_baseUrl/search?keyword=${Uri.encodeQueryComponent(cleanQuery)}&page=$page';

      http.Response response;
      try {
        response = await _client.get(
          Uri.parse(url),
          headers: _defaultHeaders,
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        // Fallback to hianime.at if original domain timed out
        final fallbackUrl = cleanQuery.isEmpty
            ? 'https://hianime.at/top-airing?page=$page'
            : 'https://hianime.at/search?keyword=${Uri.encodeQueryComponent(cleanQuery)}&page=$page';
        response = await _client.get(
          Uri.parse(fallbackUrl),
          headers: _defaultHeaders,
        ).timeout(const Duration(seconds: 6));
      }

      if (response.statusCode != 200) return [];

      final document = html_parser.parse(response.body);
      final items = document.querySelectorAll('.film_list-wrap .flw-item');

      final results = <UnifiedMedia>[];

      for (final item in items) {
        final titleEl = item.querySelector('.film-detail .film-name a') ??
            item.querySelector('.film-name a');
        final posterEl = item.querySelector('.film-poster img');

        if (titleEl == null) continue;

        final title = titleEl.text.trim();
        final href = titleEl.attributes['href'] ?? '';
        final poster = posterEl?.attributes['data-src'] ??
            posterEl?.attributes['src'] ??
            '';

        String cleanSlug = href;
        if (cleanSlug.startsWith('http')) {
          final uri = Uri.tryParse(cleanSlug);
          cleanSlug = (uri != null && uri.pathSegments.isNotEmpty)
              ? uri.pathSegments.last
              : cleanSlug;
        } else if (cleanSlug.startsWith('/')) {
          cleanSlug = cleanSlug.substring(1);
        }

        if (cleanSlug.isEmpty) continue;

        results.add(
          UnifiedMedia(
            id: cleanSlug,
            type: MediaType.ANIME,
            sourceId: sourceInfo.id,
            sourceName: sourceInfo.name,
            providerId: cleanSlug,
            title: MediaTitle(english: title),
            cover: poster,
          ),
        );
      }

      if (results.isNotEmpty) {
        _searchCache[cacheKey] = results;
      }
      return results;
    } catch (e, st) {
      methodLog.e('Search failed for "$query"', [e, st]);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    return search('', MediaType.ANIME, page: page);
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    final methodLog = _log.child('getDetails');
    try {
      final slug = providerId.contains('|')
          ? providerId.split('|')[0]
          : providerId;

      final url = slug.startsWith('http') ? slug : '$_baseUrl/$slug';
      final response = await _client.get(
        Uri.parse(url),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch details (HTTP ${response.statusCode})');
      }

      final document = html_parser.parse(response.body);
      final title = document.querySelector('.anisc-detail .film-name')?.text.trim() ??
          document.querySelector('h2.film-name')?.text.trim() ??
          slug;

      final poster = document.querySelector('.anisc-poster img')?.attributes['src'] ??
          document.querySelector('.film-poster img')?.attributes['src'];

      final desc = document.querySelector('.anisc-detail .text')?.text.trim() ??
          document.querySelector('.film-description')?.text.trim();

      final genres = document
          .querySelectorAll('.item-list a')
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      return UnifiedMedia(
        id: providerId,
        type: MediaType.ANIME,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
        providerId: slug,
        title: MediaTitle(english: title),
        cover: poster,
        description: desc,
        genres: genres,
      );
    } catch (e, st) {
      methodLog.e('getDetails failed for $providerId', [e, st]);
      return UnifiedMedia(
        id: providerId,
        type: MediaType.ANIME,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
        providerId: providerId,
        title: MediaTitle(english: providerId),
      );
    }
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final cleanId = animeId.contains('|') ? animeId.split('|')[0] : animeId;
    if (_episodesCache.containsKey(cleanId)) {
      return _episodesCache[cleanId]!;
    }

    final methodLog = _log.child('getEpisodes');
    try {
      // 1. Resolve raw anime numeric id
      String? rawId;
      final numericMatch = RegExp(r'-(\d+)$').firstMatch(cleanId);
      if (numericMatch != null) {
        rawId = numericMatch.group(1);
      } else if (RegExp(r'^\d+$').hasMatch(cleanId)) {
        rawId = cleanId;
      }

      if (rawId == null) {
        final detailUrl = cleanId.startsWith('http') ? cleanId : '$_baseUrl/$cleanId';
        final pageRes = await _client.get(
          Uri.parse(detailUrl),
          headers: _defaultHeaders,
        ).timeout(const Duration(seconds: 5));

        final doc = html_parser.parse(pageRes.body);
        rawId = doc.querySelector('#ani_detail')?.attributes['data-anime-id'] ??
            doc.querySelector('.anis-content')?.attributes['data-anime-id'] ??
            doc.querySelector('.anisc-detail')?.attributes['data-id'];
      }

      if (rawId == null) {
        methodLog.w('Could not resolve raw numeric ID for $animeId');
        return [];
      }

      // 2. Fetch episodes list AJAX (supports both hianime.at and hianime.to)
      final epEndpoints = [
        '$_baseUrl/api/theme/episode/list/$rawId',
        '$_baseUrl/ajax/v2/episode/list/$rawId',
        'https://hianime.at/api/theme/episode/list/$rawId',
      ];

      http.Response? response;
      for (final endpoint in epEndpoints) {
        try {
          final res = await _client.get(
            Uri.parse(endpoint),
            headers: {
              ..._defaultHeaders,
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': '$_baseUrl/$cleanId',
            },
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200 && res.body.contains('ep-item')) {
            response = res;
            break;
          }
        } catch (_) {}
      }

      if (response == null || response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final html = data['html'] as String? ?? '';
      if (html.isEmpty) return [];

      final doc = html_parser.parse(html);
      final epItems = doc.querySelectorAll('.ep-item');

      final episodes = <UnifiedEpisode>[];

      for (final item in epItems) {
        final id = item.attributes['data-id'];
        final numberStr = item.attributes['data-number'];
        final title = item.attributes['title']?.trim() ??
            item.querySelector('.ep-name')?.text.trim() ??
            'Episode $numberStr';

        if (id == null || numberStr == null) continue;

        final epNum = double.tryParse(numberStr) ?? 0.0;

        episodes.add(
          UnifiedEpisode(
            id: '$id|$numberStr|$title',
            title: title,
            number: epNum,
          ),
        );
      }

      episodes.sort((a, b) => a.number.compareTo(b.number));

      if (episodes.isNotEmpty) {
        _episodesCache[cleanId] = episodes;
      }
      return episodes;
    } catch (e, st) {
      methodLog.e('getEpisodes failed for $animeId', [e, st]);
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    final epId = episodeId.contains('|') ? episodeId.split('|')[0] : episodeId;
    if (_serversCache.containsKey(epId)) {
      return _serversCache[epId]!;
    }

    final methodLog = _log.child('getServers');
    try {
      final srvEndpoints = [
        '$_baseUrl/api/theme/episode/servers?episodeId=$epId',
        '$_baseUrl/ajax/v2/episode/servers?episodeId=$epId',
        'https://hianime.at/api/theme/episode/servers?episodeId=$epId',
      ];

      http.Response? response;
      for (final endpoint in srvEndpoints) {
        try {
          final res = await _client.get(
            Uri.parse(endpoint),
            headers: {
              ..._defaultHeaders,
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': '$_baseUrl/',
            },
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200 && res.body.contains('server-item')) {
            response = res;
            break;
          }
        } catch (_) {}
      }

      if (response == null || response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final html = data['html'] as String? ?? '';
      if (html.isEmpty) return [];

      final doc = html_parser.parse(html);
      final serverItems = doc.querySelectorAll('.server-item');

      final servers = <VideoServer>[];

      for (final item in serverItems) {
        final serverHash = item.attributes['data-hash'];
        final serverId = item.attributes['data-id'];
        final serverTypeStr = item.attributes['data-type']?.toLowerCase() ?? 'sub';
        final serverName = item.attributes['data-server-name'] ?? item.text.trim();

        final isDub = serverTypeStr == 'dub';
        final serverType = isDub ? ServerType.dub : ServerType.sub;

        if (serverHash != null && serverHash.isNotEmpty) {
          // hianime.at direct embed hash
          servers.add(
            VideoServer(
              id: 'hash:$serverHash',
              name: '$serverName (${isDub ? 'Dub' : 'Sub'})',
              type: serverType,
            ),
          );
        } else if (serverId != null && serverId.isNotEmpty) {
          // hianime.to server id
          servers.add(
            VideoServer(
              id: serverId,
              name: '$serverName (${isDub ? 'Dub' : 'Sub'})',
              type: serverType,
            ),
          );
        }
      }

      if (servers.isNotEmpty) {
        _serversCache[epId] = servers;
      }
      return servers;
    } catch (e, st) {
      methodLog.e('getServers failed for $episodeId', [e, st]);
      return [];
    }
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final methodLog = _log.child('getSources');
    try {
      // 1. Direct embed resolution (e.g. zokoanime / megaplay on hianime.at)
      if (server.id.startsWith('hash:')) {
        final rawHash = server.id.substring(5);
        final embedUrl = utf8.decode(base64.decode(base64.normalize(rawHash)));

        final embedUri = Uri.parse(embedUrl);
        final embedHost = '${embedUri.scheme}://${embedUri.host}';

        final embedRes = await _client.get(
          embedUri,
          headers: {
            ..._defaultHeaders,
            'Referer': '$_baseUrl/',
          },
        ).timeout(const Duration(seconds: 5));

        if (embedRes.statusCode != 200) return [];

        final pMatch = RegExp(r'window\.__P\s*=\s*"([^"]+)"').firstMatch(embedRes.body);
        if (pMatch != null) {
          final blob = pMatch.group(1)!;
          final bytes = base64.decode(base64.normalize(blob));
          final xored = Uint8List(bytes.length);
          const key = 'otaku-embed-v1';
          for (int i = 0; i < bytes.length; i++) {
            xored[i] = bytes[i] ^ key.codeUnitAt(i % key.length);
          }

          final jsonStr = utf8.decode(xored);
          final streamData = jsonDecode(jsonStr);
          final m3u8Url = streamData['src']?.toString();

          if (m3u8Url != null && m3u8Url.isNotEmpty) {
            final subtitles = <SubtitleTrack>[];
            if (streamData['subtitles'] is List) {
              for (final sub in streamData['subtitles']) {
                if (sub is Map && sub['src'] != null) {
                  final label = sub['label']?.toString() ?? sub['lang']?.toString() ?? 'English';
                  subtitles.add(SubtitleTrack(
                    url: sub['src'].toString(),
                    language: label,
                  ));
                }
              }
            }

            final isDub = server.type == ServerType.dub;
            final defaultQuality = isDub ? 'Auto (Dub)' : 'Auto';

            return [
              VideoStream(
                url: m3u8Url,
                quality: defaultQuality,
                headers: {
                  'Referer': '$embedHost/',
                  'User-Agent': _defaultHeaders['User-Agent']!,
                },
                subtitles: subtitles,
              ),
            ];
          }
        }
      }

      // 2. Fallback to Zorotheme / MegaCloud resolution (hianime.to)
      final sourcesUrl = '$_baseUrl/ajax/v2/episode/sources?id=${server.id}';
      final response = await _client.get(
        Uri.parse(sourcesUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final link = data['link'] as String?;
      if (link == null || link.isEmpty) return [];

      final embedUri = Uri.parse(link);
      final embedHost = '${embedUri.scheme}://${embedUri.host}';
      final pathSegments = embedUri.pathSegments;
      final sourceId = pathSegments.isNotEmpty ? pathSegments.last : '';

      if (sourceId.isEmpty) return [];

      final embedApiUrl = '$embedHost/embed-2/ajax/e-1/getSources?id=$sourceId';
      final streamResponse = await _client.get(
        Uri.parse(embedApiUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': link,
        },
      ).timeout(const Duration(seconds: 5));

      if (streamResponse.statusCode != 200) return [];

      final streamData = jsonDecode(streamResponse.body);
      final sources = streamData['sources'];
      final tracks = streamData['tracks'] as List<dynamic>? ?? [];

      final subtitles = <SubtitleTrack>[];
      for (final t in tracks) {
        if (t is Map) {
          final file = t['file']?.toString();
          final label = t['label']?.toString() ?? 'English';
          final kind = t['kind']?.toString() ?? 'captions';
          if (file != null && file.isNotEmpty && (kind == 'captions' || kind == 'subtitles')) {
            subtitles.add(SubtitleTrack(url: file, language: label));
          }
        }
      }

      final isDub = server.type == ServerType.dub;
      final defaultQuality = isDub ? 'Auto (Dub)' : 'Auto';
      final headers = <String, String>{
        'Referer': '$embedHost/',
        'User-Agent': _defaultHeaders['User-Agent']!,
      };

      final videoStreams = <VideoStream>[];

      if (sources is List) {
        for (final s in sources) {
          if (s is Map && s['file'] != null) {
            final streamUrl = s['file'].toString();
            videoStreams.add(
              VideoStream(
                url: streamUrl,
                quality: defaultQuality,
                headers: headers,
                subtitles: subtitles,
              ),
            );
          }
        }
      }

      return videoStreams;
    } catch (e, st) {
      methodLog.e('getSources failed for server ${server.id}', [e, st]);
      return [];
    }
  }
}
