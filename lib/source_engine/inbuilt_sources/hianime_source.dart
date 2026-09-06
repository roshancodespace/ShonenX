import 'dart:async';
import 'dart:convert';
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
  static const String defaultBaseUrl = 'https://hianime.to';
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
        defaultValue: 'https://hianime.to',
        options: const [
          'https://hianime.to',
          'https://hianime.at',
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

      final response = await _client.get(
        Uri.parse(url),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 5));

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

        final cleanSlug = href.startsWith('/') ? href.substring(1) : href;
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
      ).timeout(const Duration(seconds: 5));

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
      }

      if (rawId == null) {
        final detailUrl = cleanId.startsWith('http') ? cleanId : '$_baseUrl/$cleanId';
        final pageRes = await _client.get(
          Uri.parse(detailUrl),
          headers: _defaultHeaders,
        ).timeout(const Duration(seconds: 4));

        final doc = html_parser.parse(pageRes.body);
        final syncData = doc.querySelector('#sync-data');
        if (syncData != null) {
          try {
            final json = jsonDecode(syncData.text);
            rawId = json['anime_id']?.toString();
          } catch (_) {}
        }

        rawId ??= doc.querySelector('.anisc-detail')?.attributes['data-id'] ??
            doc.querySelector('[data-id]')?.attributes['data-id'];
      }

      if (rawId == null) {
        methodLog.w('Could not resolve raw numeric ID for $animeId');
        return [];
      }

      // 2. Fetch episodes list AJAX
      final ajaxUrl = '$_baseUrl/ajax/v2/episode/list/$rawId';
      final response = await _client.get(
        Uri.parse(ajaxUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$_baseUrl/$cleanId',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return [];

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
      final ajaxUrl = '$_baseUrl/ajax/v2/episode/servers?episodeId=$epId';
      final response = await _client.get(
        Uri.parse(ajaxUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final html = data['html'] as String? ?? '';
      if (html.isEmpty) return [];

      final doc = html_parser.parse(html);
      final serverItems = doc.querySelectorAll('.server-item');

      final servers = <VideoServer>[];

      for (final item in serverItems) {
        final serverId = item.attributes['data-id'];
        final serverTypeStr = item.attributes['data-type']?.toLowerCase() ?? 'sub';
        final serverName = item.text.trim();

        if (serverId == null) continue;

        final isDub = serverTypeStr == 'dub';
        final serverType = isDub ? ServerType.dub : ServerType.sub;

        servers.add(
          VideoServer(
            id: serverId,
            name: '$serverName (${isDub ? 'Dub' : 'Sub'})',
            type: serverType,
          ),
        );
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
      // 1. Get embed sources iframe link
      final sourcesUrl = '$_baseUrl/ajax/v2/episode/sources?id=${server.id}';
      final response = await _client.get(
        Uri.parse(sourcesUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final link = data['link'] as String?;
      if (link == null || link.isEmpty) return [];

      // 2. Parse embed host & source ID (MegaCloud / RapidCloud)
      final embedUri = Uri.parse(link);
      final embedHost = '${embedUri.scheme}://${embedUri.host}';
      final pathSegments = embedUri.pathSegments;
      final sourceId = pathSegments.isNotEmpty ? pathSegments.last : '';

      if (sourceId.isEmpty) return [];

      // 3. Resolve direct HLS stream manifest and subtitles
      final embedApiUrl = '$embedHost/embed-2/ajax/e-1/getSources?id=$sourceId';
      final streamResponse = await _client.get(
        Uri.parse(embedApiUrl),
        headers: {
          ..._defaultHeaders,
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': link,
        },
      ).timeout(const Duration(seconds: 4));

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
