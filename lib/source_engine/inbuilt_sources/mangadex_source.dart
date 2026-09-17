import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_chapter.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';

class MangaDexSource implements MangaSource {
  static const String defaultApiUrl = 'https://api.mangadex.org';
  static const String defaultCoverUrl = 'https://uploads.mangadex.org/covers';

  final http.Client _client = http.Client();
  final ScopedLogger _log = AppLogger.scope('MangaDexSource');

  static const Map<String, String> _headers = {
    'User-Agent': 'KuroX-MangaReader/1.0 (https://github.com/Zcross091/KuroX)',
    'Accept': 'application/json',
  };

  @override
  SourceInfo get sourceInfo => const SourceInfo(
        id: 'inbuilt_mangadex',
        name: 'Public API',
        type: SourceType.inbuilt,
        mediaType: MediaType.MANGA,
        iconUrl: null,
        baseUrl: defaultApiUrl,
        lang: 'en',
      );

  // In-memory caches for fast navigation
  final Map<String, List<UnifiedMedia>> _searchCache = {};
  final Map<String, List<UnifiedChapter>> _chaptersCache = {};

  @override
  Future<List<SourceSetting>> getSettingsSchema() async => const [];

  @override
  Future<List<String>> getFilterGenres() async => const [
        'Action',
        'Adventure',
        'Comedy',
        'Drama',
        'Fantasy',
        'Horror',
        'Mystery',
        'Psychological',
        'Romance',
        'Sci-Fi',
        'Slice of Life',
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
    final cacheKey = '${query.toLowerCase()}_$page';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    try {
      final offset = (page - 1) * 20;
      final uri = Uri.parse(
        '$defaultApiUrl/manga?title=${Uri.encodeComponent(query)}&limit=20&offset=$offset&includes[]=cover_art&includes[]=author&contentRating[]=safe&contentRating[]=suggestive',
      );

      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];

      final results = data.map((item) => _parseMangaItem(item)).whereType<UnifiedMedia>().toList();
      _searchCache[cacheKey] = results;
      return results;
    } catch (e) {
      _log.warning('MangaDex search failed: $e');
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    try {
      final offset = (page - 1) * 20;
      final uri = Uri.parse(
        '$defaultApiUrl/manga?order[followedCount]=desc&limit=20&offset=$offset&includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive',
      );

      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];

      return data.map((item) => _parseMangaItem(item)).whereType<UnifiedMedia>().toList();
    } catch (e) {
      _log.warning('MangaDex getTrending failed: $e');
      return [];
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    try {
      final uri = Uri.parse(
        '$defaultApiUrl/manga/$providerId?includes[]=cover_art&includes[]=author',
      );

      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'];
        final parsed = _parseMangaItem(data);
        if (parsed != null) return parsed;
      }
    } catch (e) {
      _log.warning('MangaDex getDetails failed: $e');
    }

    return UnifiedMedia(
      id: providerId,
      title: const MediaTitle(english: 'Manga'),
      type: MediaType.MANGA,
      sourceId: sourceInfo.id,
      sourceName: sourceInfo.name,
      providerId: providerId,
    );
  }

  @override
  Future<List<UnifiedChapter>> getChapters(String mangaId) async {
    if (_chaptersCache.containsKey(mangaId)) {
      return _chaptersCache[mangaId]!;
    }

    try {
      final uri = Uri.parse(
        '$defaultApiUrl/manga/$mangaId/feed?translatedLanguage[]=en&order[chapter]=asc&limit=500&includes[]=scanlation_group',
      );

      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];

      final chapters = <UnifiedChapter>[];
      final seenNumbers = <double>{};

      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final id = item['id'] as String? ?? '';
        final attrs = item['attributes'] as Map<String, dynamic>? ?? {};

        final chapterStr = attrs['chapter'] as String?;
        final chapterNum = double.tryParse(chapterStr ?? '') ?? (i + 1.0);

        // Deduplicate multiple scanlations of the same chapter number
        if (seenNumbers.contains(chapterNum)) continue;
        seenNumbers.add(chapterNum);

        final title = attrs['title'] as String?;
        final cleanTitle = (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : 'Chapter ${chapterStr ?? (i + 1)}';

        String? scanlator;
        final rels = item['relationships'] as List<dynamic>? ?? [];
        for (final r in rels) {
          if (r is Map<String, dynamic> && r['type'] == 'scanlation_group') {
            final groupAttrs = r['attributes'] as Map<String, dynamic>?;
            scanlator = groupAttrs?['name'] as String?;
            break;
          }
        }

        final uploadDate = attrs['publishAt'] as String? ?? attrs['createdAt'] as String?;

        chapters.add(
          UnifiedChapter(
            id: id,
            number: chapterNum,
            title: cleanTitle,
            scanlator: scanlator,
            uploadDate: uploadDate,
          ),
        );
      }

      chapters.sort((a, b) => a.number.compareTo(b.number));
      _chaptersCache[mangaId] = chapters;
      return chapters;
    } catch (e) {
      _log.warning('MangaDex getChapters failed: $e');
      return [];
    }
  }

  @override
  Future<List<ChapterPage>> getPages(String chapterId) async {
    try {
      final uri = Uri.parse('$defaultApiUrl/at-home/server/$chapterId');
      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final baseUrl = json['baseUrl'] as String? ?? '';
      final chapterObj = json['chapter'] as Map<String, dynamic>? ?? {};
      final hash = chapterObj['hash'] as String? ?? '';
      final dataFiles = chapterObj['data'] as List<dynamic>? ?? [];

      final pages = <ChapterPage>[];
      for (int i = 0; i < dataFiles.length; i++) {
        final fileName = dataFiles[i] as String;
        final imageUrl = '$baseUrl/data/$hash/$fileName';
        pages.add(
          ChapterPage(
            page: i + 1,
            url: imageUrl,
            headers: {'Referer': 'https://mangadex.org'},
          ),
        );
      }

      return pages;
    } catch (e) {
      _log.warning('MangaDex getPages failed: $e');
      return [];
    }
  }

  UnifiedMedia? _parseMangaItem(dynamic item) {
    if (item is! Map<String, dynamic>) return null;

    final id = item['id'] as String? ?? '';
    final attrs = item['attributes'] as Map<String, dynamic>? ?? {};
    final titleObj = attrs['title'] as Map<String, dynamic>? ?? {};

    final mainTitle = titleObj['en'] as String? ??
        titleObj['ja-ro'] as String? ??
        (titleObj.values.isNotEmpty ? titleObj.values.first as String? : 'Manga');

    final descObj = attrs['description'] as Map<String, dynamic>? ?? {};
    final description = descObj['en'] as String? ??
        (descObj.values.isNotEmpty ? descObj.values.first as String? : null);

    // Extract Cover Art
    String? coverUrl;
    final rels = item['relationships'] as List<dynamic>? ?? [];
    for (final r in rels) {
      if (r is Map<String, dynamic> && r['type'] == 'cover_art') {
        final coverAttrs = r['attributes'] as Map<String, dynamic>?;
        final fileName = coverAttrs?['fileName'] as String?;
        if (fileName != null && fileName.isNotEmpty) {
          coverUrl = '$defaultCoverUrl/$id/$fileName.256.jpg';
        }
        break;
      }
    }

    // Extract Genres
    final tags = attrs['tags'] as List<dynamic>? ?? [];
    final genres = <String>[];
    for (final tag in tags) {
      if (tag is Map<String, dynamic>) {
        final tagAttrs = tag['attributes'] as Map<String, dynamic>?;
        if (tagAttrs?['group'] == 'genre') {
          final nameObj = tagAttrs?['name'] as Map<String, dynamic>?;
          final name = nameObj?['en'] as String?;
          if (name != null) genres.add(name);
        }
      }
    }

    return UnifiedMedia(
      id: id,
      title: MediaTitle(
        english: mainTitle,
        romaji: titleObj['ja-ro'] as String?,
      ),
      type: MediaType.MANGA,
      cover: coverUrl,
      banner: coverUrl,
      description: description,
      genres: genres,
      sourceId: sourceInfo.id,
      sourceName: sourceInfo.name,
      providerId: id,
    );
  }

  @override
  int get hashCode => sourceInfo.id.hashCode ^ sourceInfo.mediaType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MangaSource &&
        other.sourceInfo.id == sourceInfo.id &&
        other.sourceInfo.name == sourceInfo.name &&
        other.sourceInfo.type == sourceInfo.type &&
        other.sourceInfo.mediaType == sourceInfo.mediaType;
  }
}
