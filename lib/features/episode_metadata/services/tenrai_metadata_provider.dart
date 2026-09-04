import 'dart:convert';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/episode_metadata/domain/interfaces/episode_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/features/episode_metadata/services/title_matcher.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TenraiEpisodeMetadataProvider implements EpisodeMetadataProvider {
  final HTTP _http;
  final _log = AppLogger.scope('EpisodeMetadata.Tenrai');
  static const _cacheDuration = Duration(days: 30);

  TenraiEpisodeMetadataProvider({HTTP? http}) : _http = http ?? HTTP();

  @override
  String get id => 'tenrai';

  @override
  String get name => 'Tenrai';

  @override
  Future<String?> resolveId({required UnifiedMedia media}) async {
    // 1. Direct Provider Match (O(1))
    final providerId = media.providerId?.toLowerCase();
    if ((providerId == 'mal' || providerId == 'myanimelist') &&
        media.id.isNotEmpty) {
      _log.d('Direct MAL ID from provider: ${media.id}');
      return media.id;
    }

    // 2. Direct MAL ID or External Cross-Mapping (O(1))
    if (media.idMal?.isNotEmpty == true) {
      _log.d('Resolved MAL ID from idMal: ${media.idMal}');
      return media.idMal;
    }
    if (media.externalIds.mal?.isNotEmpty == true) {
      _log.d('Resolved MAL ID from externalIds: ${media.externalIds.mal}');
      return media.externalIds.mal;
    }

    // 3. Fallback: Fuzzy Search by Title via Tenrai API
    _log.i(
      'No direct MAL ID found for Tenrai; resolving by title for "${media.title.availableTitle}"',
    );
    return await _resolveIdByTitle(media);
  }

  Future<String?> _resolveIdByTitle(UnifiedMedia media) async {
    final targetTitles = TitleMatcher.extractTargetTitles(media);
    if (targetTitles.isEmpty) return null;

    final queryTitle = targetTitles.first;

    try {
      final url =
          'https://api.tenrai.org/v1/anime?q=${Uri.encodeComponent(queryTitle)}&limit=10';
      var res = await _http.get(url, cacheDuration: _cacheDuration);

      if (res.statusCode == 429) {
        await Future.delayed(const Duration(milliseconds: 1500));
        res = await _http.get(url, cacheDuration: _cacheDuration);
      }

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data'];
      if (data is! List || data.isEmpty) return null;

      final match = TitleMatcher.findBestMatch<dynamic>(
        targetTitles: targetTitles,
        candidates: data,
        extractCandidateTitles: (item) {
          final titles = <String>[];
          if (item is Map) {
            if (item['title'] is String) titles.add(item['title']);
            if (item['title_english'] is String) {
              titles.add(item['title_english']);
            }
            if (item['title_japanese'] is String) {
              titles.add(item['title_japanese']);
            }
            if (item['titles'] is List) {
              for (final t in item['titles']) {
                if (t is Map && t['title'] is String) titles.add(t['title']);
              }
            }
          }
          return titles;
        },
      );

      final matchedId = match?.item is Map
          ? match!.item['mal_id']?.toString()
          : null;
      if (matchedId != null) {
        _log.d('Resolved MAL ID via Tenrai title search: $matchedId');
      }
      return matchedId;
    } catch (e) {
      _log.d('Tenrai title search failed: $e');
      return null;
    }
  }

  @override
  Future<List<EpisodeMetadata>> fetchEpisodes({
    required UnifiedMedia media,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Matching anime with Tenrai...');
    final malId = await resolveId(media: media);
    if (malId == null || malId.isEmpty) return const [];

    try {
      onProgress?.call('Fetching episodes 1-100 from Tenrai...');
      final page1Url = 'https://api.tenrai.org/v1/anime/$malId/episodes?page=1';
      var page1Res = await _http.get(page1Url, cacheDuration: _cacheDuration);

      if (page1Res.statusCode == 429) {
        await Future.delayed(const Duration(milliseconds: 1500));
        page1Res = await _http.get(page1Url, cacheDuration: _cacheDuration);
      }

      if (page1Res.statusCode != 200) return const [];

      final page1Json = jsonDecode(page1Res.body);
      final page1Data = page1Json['data'];
      if (page1Data is! List || page1Data.isEmpty) return const [];

      final episodes = _parseEpisodes(page1Data);

      final pagination = page1Json['pagination'];
      final lastPage =
          (pagination is Map && pagination['last_visible_page'] is int)
          ? pagination['last_visible_page'] as int
          : 1;

      if (lastPage > 1) {
        for (int p = 2; p <= lastPage; p++) {
          await Future.delayed(const Duration(milliseconds: 600));

          final firstEpInPage = (p - 1) * 100 + 1;
          final lastEpInPage = p * 100;
          onProgress?.call(
            'Fetching episodes $firstEpInPage-$lastEpInPage (Page $p/$lastPage)...',
          );

          final pageEps = await _fetchSinglePage(malId, p);
          if (pageEps.isEmpty) break;
          episodes.addAll(pageEps);
        }
      }

      if (episodes.isNotEmpty) {
        _log.s('Loaded ${episodes.length} episodes from Tenrai ($malId)');
      }
      return episodes;
    } catch (e, st) {
      _log.e('Failed to fetch Tenrai episodes ($malId)', [e, st]);
      return const [];
    }
  }

  Future<List<EpisodeMetadata>> _fetchSinglePage(String malId, int page) async {
    try {
      final url = 'https://api.tenrai.org/v1/anime/$malId/episodes?page=$page';
      var res = await _http.get(url, cacheDuration: _cacheDuration);

      if (res.statusCode == 429) {
        await Future.delayed(const Duration(milliseconds: 1500));
        res = await _http.get(url, cacheDuration: _cacheDuration);
      }

      if (res.statusCode != 200) return const [];

      final jsonBody = jsonDecode(res.body);
      final data = jsonBody['data'];
      if (data is! List) return const [];

      return _parseEpisodes(data);
    } catch (_) {
      return const [];
    }
  }

  List<EpisodeMetadata> _parseEpisodes(List<dynamic> data) {
    final list = <EpisodeMetadata>[];
    for (final item in data) {
      if (item is! Map) continue;
      final epNumRaw = item['mal_id'];
      final epNum = epNumRaw is num
          ? epNumRaw.toDouble()
          : double.tryParse(epNumRaw?.toString() ?? '');
      if (epNum == null) continue;

      String? thumbnailUrl;
      final images = item['images'];
      if (images is Map) {
        final jpg = images['jpg'];
        if (jpg is Map) {
          thumbnailUrl = jpg['image_url'] as String?;
        }
      }

      list.add(
        EpisodeMetadata(
          number: epNum,
          title: item['title'] as String?,
          japaneseTitle: item['title_japanese'] as String?,
          romanjiTitle: item['title_romanji'] as String?,
          description: item['synopsis'] as String?,
          thumbnailUrl: thumbnailUrl,
          airDate: item['aired'] as String?,
          isFiller: item['filler'] == true,
          score: (item['score'] as num?)?.toDouble(),
        ),
      );
    }
    return list;
  }
}
