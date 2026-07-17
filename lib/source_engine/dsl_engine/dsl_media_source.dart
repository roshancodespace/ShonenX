import 'package:shonenx/shared/models/unified_chapter.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_runtime.dart';

class DSLAnimeSource extends MediaSource implements AnimeSource {
  final Map<String, dynamic> providerDef;
  final DSLRuntime runtime;

  DSLAnimeSource({required this.providerDef, required this.runtime});

  @override
  SourceInfo get sourceInfo => SourceInfo(
    id: providerDef['id']?.toString() ?? '',
    name: providerDef['name']?.toString() ?? 'DSL Anime Source',
    type: SourceType.dsl,
    mediaType: MediaType.ANIME,
    iconUrl: providerDef['iconUrl']?.toString(),
    baseUrl: providerDef['baseUrl']?.toString(),
    lang: providerDef['lang']?.toString(),
    isNsfw: providerDef['isNsfw'] == true,
  );

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
    try {
      final res = await runtime.executeMethod(providerDef, 'search', {
        'query': query,
        'page': page,
        'isAdult': isAdult,
        'sort': sort,
        'genres': genres,
        'tags': tags,
      });
      return _parseMediaList(res, MediaType.ANIME);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'trending', {
        'page': page,
      });
      return _parseMediaList(res, MediaType.ANIME);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'details', {
        'id': providerId,
        'mediaType': type.name,
      });
      return _parseMedia(res, fallbackId: providerId, type: MediaType.ANIME);
    } catch (_) {
      return UnifiedMedia(
        id: providerId,
        type: MediaType.ANIME,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
      );
    }
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'episodes', {
        'animeId': animeId,
      });
      return _parseEpisodeList(res);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'servers', {
        'episodeId': episodeId,
      });
      return _parseServerList(res);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'sources', {
        'episodeId': episodeId,
        'serverId': server.id,
        'serverName': server.name,
        'serverType': server.type.name,
      });
      return _parseStreamList(res);
    } catch (_) {
      return [];
    }
  }

  UnifiedMedia _parseMedia(
    dynamic item, {
    required String fallbackId,
    required MediaType type,
  }) {
    if (item is! Map) {
      return UnifiedMedia(
        id: fallbackId,
        type: type,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
      );
    }
    final titleObj = item['title'];
    String? engTitle;
    String? romTitle;
    String? natTitle;

    if (titleObj is Map) {
      engTitle = titleObj['english']?.toString();
      romTitle = titleObj['romaji']?.toString();
      natTitle = titleObj['native']?.toString();
    } else {
      engTitle = titleObj?.toString();
    }

    return UnifiedMedia(
      id: (item['id'] ?? fallbackId).toString(),
      type: type,
      sourceId: sourceInfo.id,
      sourceName: sourceInfo.name,
      cover: item['cover']?.toString(),
      title: MediaTitle(english: engTitle, romaji: romTitle, native: natTitle),
      description: item['description']?.toString(),
      score: double.tryParse(item['score']?.toString() ?? ''),
      banner: item['banner']?.toString(),
      genres: item['genres'] is List
          ? List<String>.from(item['genres'] as List)
          : const [],
    );
  }

  List<UnifiedMedia> _parseMediaList(dynamic res, MediaType type) {
    if (res is! List) return [];
    return res
        .map((item) => _parseMedia(item, fallbackId: '', type: type))
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  List<UnifiedEpisode> _parseEpisodeList(dynamic res) {
    if (res is! List) return [];
    return res
        .map((item) {
          if (item is! Map) return null;
          return UnifiedEpisode(
            id: item['id']?.toString() ?? '',
            number: double.tryParse(item['number']?.toString() ?? '') ?? 0.0,
            title: item['title']?.toString(),
            thumbnailUrl:
                item['thumbnailUrl']?.toString() ?? item['cover']?.toString(),
            isFiller: item['isFiller'] == true,
            scanlator: item['scanlator']?.toString(),
            airDate: item['airDate']?.toString(),
            uploadDate: item['uploadDate']?.toString(),
          );
        })
        .whereType<UnifiedEpisode>()
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  List<VideoServer> _parseServerList(dynamic res) {
    if (res is! List) return [];
    return res
        .map((item) {
          if (item is! Map) return null;
          final typeStr = item['type']?.toString().toLowerCase();
          ServerType sType = ServerType.unknown;
          if (typeStr == 'sub') sType = ServerType.sub;
          if (typeStr == 'dub') sType = ServerType.dub;
          if (typeStr == 'raw') sType = ServerType.raw;

          return VideoServer(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Server',
            type: sType,
          );
        })
        .whereType<VideoServer>()
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  List<VideoStream> _parseStreamList(dynamic res) {
    if (res is! List) return [];
    return res
        .map((item) {
          if (item is! Map) return null;
          final headers = item['headers'] is Map
              ? Map<String, String>.from(item['headers'] as Map)
              : null;
          final subsList = <SubtitleTrack>[];
          if (item['subtitles'] is List) {
            for (final sub in item['subtitles'] as List) {
              if (sub is Map) {
                subsList.add(
                  SubtitleTrack(
                    url: sub['url']?.toString() ?? '',
                    language: sub['language']?.toString() ?? 'Unknown',
                  ),
                );
              }
            }
          }
          return VideoStream(
            url: item['url']?.toString() ?? '',
            quality: item['quality']?.toString() ?? 'Auto',
            headers: headers,
            subtitles: subsList,
          );
        })
        .whereType<VideoStream>()
        .where((s) => s.url.isNotEmpty)
        .toList();
  }
}

class DSLMangaSource extends MediaSource implements MangaSource {
  final Map<String, dynamic> providerDef;
  final DSLRuntime runtime;

  DSLMangaSource({required this.providerDef, required this.runtime});

  @override
  SourceInfo get sourceInfo => SourceInfo(
    id: providerDef['id']?.toString() ?? '',
    name: providerDef['name']?.toString() ?? 'DSL Manga Source',
    type: SourceType.inbuilt,
    mediaType: MediaType.MANGA,
    iconUrl: providerDef['iconUrl']?.toString(),
    baseUrl: providerDef['baseUrl']?.toString(),
    lang: providerDef['lang']?.toString(),
    isNsfw: providerDef['isNsfw'] == true,
  );

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
    try {
      final res = await runtime.executeMethod(providerDef, 'search', {
        'query': query,
        'page': page,
        'isAdult': isAdult,
        'sort': sort,
        'genres': genres,
        'tags': tags,
      });
      return _parseMediaList(res, MediaType.MANGA);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'trending', {
        'page': page,
      });
      return _parseMediaList(res, MediaType.MANGA);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'details', {
        'id': providerId,
        'mediaType': type.name,
      });
      return _parseMedia(res, fallbackId: providerId, type: MediaType.MANGA);
    } catch (_) {
      return UnifiedMedia(
        id: providerId,
        type: MediaType.MANGA,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
      );
    }
  }

  @override
  Future<List<UnifiedChapter>> getChapters(String mangaId) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'chapters', {
        'mangaId': mangaId,
      });
      return _parseChapterList(res);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ChapterPage>> getPages(String chapterId) async {
    try {
      final res = await runtime.executeMethod(providerDef, 'pages', {
        'chapterId': chapterId,
      });
      return _parsePageList(res);
    } catch (_) {
      return [];
    }
  }

  UnifiedMedia _parseMedia(
    dynamic item, {
    required String fallbackId,
    required MediaType type,
  }) {
    if (item is! Map) {
      return UnifiedMedia(
        id: fallbackId,
        type: type,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
      );
    }
    final titleObj = item['title'];
    String? engTitle;
    String? romTitle;
    String? natTitle;

    if (titleObj is Map) {
      engTitle = titleObj['english']?.toString();
      romTitle = titleObj['romaji']?.toString();
      natTitle = titleObj['native']?.toString();
    } else {
      engTitle = titleObj?.toString();
    }

    return UnifiedMedia(
      id: (item['id'] ?? fallbackId).toString(),
      type: type,
      sourceId: sourceInfo.id,
      sourceName: sourceInfo.name,
      cover: item['cover']?.toString(),
      title: MediaTitle(english: engTitle, romaji: romTitle, native: natTitle),
      description: item['description']?.toString(),
      score: double.tryParse(item['score']?.toString() ?? ''),
      banner: item['banner']?.toString(),
      genres: item['genres'] is List
          ? List<String>.from(item['genres'] as List)
          : const [],
    );
  }

  List<UnifiedMedia> _parseMediaList(dynamic res, MediaType type) {
    if (res is! List) return [];
    return res
        .map((item) => _parseMedia(item, fallbackId: '', type: type))
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  List<UnifiedChapter> _parseChapterList(dynamic res) {
    if (res is! List) return [];
    return res
        .map((item) {
          if (item is! Map) return null;
          return UnifiedChapter(
            id: item['id']?.toString() ?? '',
            number: double.tryParse(item['number']?.toString() ?? '') ?? 0.0,
            title: item['title']?.toString(),
            scanlator: item['scanlator']?.toString(),
            airDate: item['airDate']?.toString(),
            uploadDate: item['uploadDate']?.toString(),
          );
        })
        .whereType<UnifiedChapter>()
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  List<ChapterPage> _parsePageList(dynamic res) {
    if (res is! List) return [];
    return res
        .map((item) {
          if (item is Map) {
            final headers = item['headers'] is Map
                ? Map<String, String>.from(item['headers'] as Map)
                : null;
            return ChapterPage(
              url: item['url']?.toString() ?? '',
              headers: headers,
            );
          }
          final urlStr = item?.toString() ?? '';
          if (urlStr.isEmpty) return null;
          return ChapterPage(url: urlStr);
        })
        .whereType<ChapterPage>()
        .where((p) => p.url.isNotEmpty)
        .toList();
  }
}
