import 'dart:convert';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/episode_metadata/domain/interfaces/episode_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/features/episode_metadata/services/title_matcher.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class JikanEpisodeMetadataProvider implements EpisodeMetadataProvider {
  final HTTP _http;
  final _log = AppLogger.scope('EpisodeMetadata.Jikan');
  static const _cacheDuration = Duration(days: 30);

  JikanEpisodeMetadataProvider({HTTP? http}) : _http = http ?? HTTP();

  @override
  String get id => 'jikan';

  @override
  String get name => 'Jikan (MyAnimeList)';

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

    // 3. Fallback: Fuzzy Search by Title via Jikan API
    _log.i(
      'No direct MAL ID found for Jikan; resolving by title for "${media.title.availableTitle}"',
    );
    return await _resolveIdByTitle(media);
  }

  Future<String?> _resolveIdByTitle(UnifiedMedia media) async {
    final targetTitles = TitleMatcher.extractTargetTitles(media);
    if (targetTitles.isEmpty) return null;

    final queryTitle = targetTitles.first;

    try {
      final url =
          'https://api.jikan.moe/v4/anime?q=${Uri.encodeComponent(queryTitle)}&limit=10';
      var res = await _http.get(url, cacheDuration: _cacheDuration);

      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(const Duration(milliseconds: 1000));
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
        _log.d('Resolved MAL ID via Jikan title search: $matchedId');
      }
      return matchedId;
    } catch (e) {
      _log.d('Jikan title search failed: $e');
      return null;
    }
  }

  @override
  Future<List<EpisodeMetadata>> fetchEpisodes({
    required UnifiedMedia media,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Matching anime ID...');
    final malId = await resolveId(media: media);
    if (malId == null || malId.isEmpty) return const [];

    try {
      onProgress?.call('Fetching episodes from Jikan...');
      final url = 'https://api.jikan.moe/v4/anime/$malId/episodes?page=1';
      var res = await _http.get(url, cacheDuration: _cacheDuration);

      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(const Duration(milliseconds: 1000));
        res = await _http.get(url, cacheDuration: _cacheDuration);
      }

      if (res.statusCode != 200) return const [];

      final data = jsonDecode(res.body)['data'];
      if (data is! List || data.isEmpty) return const [];

      final episodes = <EpisodeMetadata>[];
      for (final item in data) {
        if (item is! Map) continue;
        final epNumRaw = item['mal_id'];
        final epNum = epNumRaw is num
            ? epNumRaw.toDouble()
            : double.tryParse(epNumRaw?.toString() ?? '');
        if (epNum == null) continue;

        episodes.add(
          EpisodeMetadata(
            number: epNum,
            title: item['title'] as String?,
            japaneseTitle: item['title_japanese'] as String?,
            romanjiTitle: item['title_romanji'] as String?,
            airDate: item['aired'] as String?,
            isFiller: item['filler'] == true,
            score: (item['score'] as num?)?.toDouble(),
          ),
        );
      }

      if (episodes.isNotEmpty) {
        _log.s('Loaded ${episodes.length} episodes from Jikan ($malId)');
      }
      return episodes;
    } catch (e, st) {
      _log.e('Failed to fetch Jikan episodes ($malId)', [e, st]);
      return const [];
    }
  }
}
