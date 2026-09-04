import 'dart:convert';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/episode_metadata/domain/interfaces/episode_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/features/episode_metadata/services/title_matcher.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class KitsuEpisodeMetadataProvider implements EpisodeMetadataProvider {
  final HTTP _http;
  final _log = AppLogger.scope('EpisodeMetadata.Kitsu');
  static const _cacheDuration = Duration(days: 30);

  KitsuEpisodeMetadataProvider({HTTP? http}) : _http = http ?? HTTP();

  @override
  String get id => 'kitsu';

  @override
  String get name => 'Kitsu';

  @override
  Future<String?> resolveId({required UnifiedMedia media}) async {
    // 1. Direct Provider Match (O(1))
    if (media.providerId == 'kitsu' && media.id.isNotEmpty) {
      _log.d('Direct Kitsu ID from provider: ${media.id}');
      return media.id;
    }

    // 2. External ID Cross-Mapping (O(1))
    if (media.externalIds.kitsu?.isNotEmpty == true) {
      _log.d('Resolved Kitsu ID from externalIds: ${media.externalIds.kitsu}');
      return media.externalIds.kitsu;
    }

    // 3. Fallback: Fuzzy Search by Title
    _log.i(
      'No direct ID found for Kitsu; resolving by title for "${media.title.availableTitle}"',
    );
    return await _resolveIdByTitle(media);
  }

  Future<String?> _resolveIdByTitle(UnifiedMedia media) async {
    final targetTitles = TitleMatcher.extractTargetTitles(media);
    if (targetTitles.isEmpty) return null;

    final queryTitle = targetTitles.first;

    try {
      final url =
          'https://kitsu.io/api/edge/anime?filter[text]=${Uri.encodeComponent(queryTitle)}&page[limit]=10';
      final res = await _http.get(
        url,
        headers: const {'Accept': 'application/vnd.api+json'},
        cacheDuration: _cacheDuration,
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data'];
      if (data is! List || data.isEmpty) return null;

      final match = TitleMatcher.findBestMatch<dynamic>(
        targetTitles: targetTitles,
        candidates: data,
        extractCandidateTitles: (item) {
          final titles = <String>[];
          if (item is Map) {
            final attrs = item['attributes'];
            if (attrs is Map) {
              if (attrs['canonicalTitle'] is String) {
                titles.add(attrs['canonicalTitle']);
              }
              if (attrs['titles'] is Map) {
                for (final v in (attrs['titles'] as Map).values) {
                  if (v is String && v.isNotEmpty) titles.add(v);
                }
              }
            }
          }
          return titles;
        },
      );

      final matchedId = match?.item is Map
          ? match!.item['id']?.toString()
          : null;
      if (matchedId != null) {
        _log.d('Resolved Kitsu ID via title search: $matchedId');
      }
      return matchedId;
    } catch (e) {
      _log.d('Kitsu title search failed: $e');
      return null;
    }
  }

  @override
  Future<List<EpisodeMetadata>> fetchEpisodes({
    required UnifiedMedia media,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Matching anime with Kitsu...');
    final kitsuId = await resolveId(media: media);
    if (kitsuId == null || kitsuId.isEmpty) return const [];

    final episodes = <EpisodeMetadata>[];
    const maxPages = 15; // Up to 300 episodes

    for (int pageIdx = 0; pageIdx < maxPages; pageIdx += 2) {
      final startEp = pageIdx * 20 + 1;
      final endEp = (pageIdx + 2) * 20;
      onProgress?.call('Fetching Kitsu episodes $startEp-$endEp...');

      final offsets = [
        pageIdx * 20,
        if (pageIdx + 1 < maxPages) (pageIdx + 1) * 20,
      ];

      try {
        final results = await Future.wait(
          offsets.map((offset) => _fetchSingleOffset(kitsuId, offset)),
        );

        bool reachedEnd = false;
        for (int i = 0; i < results.length; i++) {
          final pageEps = results[i];
          episodes.addAll(pageEps);

          if (pageIdx == 0 &&
              i == 0 &&
              pageEps.every(
                (e) => e.title == null || e.title!.trim().isEmpty,
              )) {
            reachedEnd = true;
            break;
          }

          if (pageEps.length < 20) {
            reachedEnd = true;
            break;
          }
        }

        if (reachedEnd) break;

        if (pageIdx + 2 < maxPages) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (_) {
        break;
      }
    }

    if (episodes.isNotEmpty) {
      _log.s('Loaded ${episodes.length} episodes from Kitsu ($kitsuId)');
    }
    return episodes;
  }

  Future<List<EpisodeMetadata>> _fetchSingleOffset(
    String kitsuId,
    int offset,
  ) async {
    try {
      final url =
          'https://kitsu.io/api/edge/anime/$kitsuId/episodes?page[limit]=20&page[offset]=$offset&sort=number';
      final res = await _http.get(
        url,
        headers: const {'Accept': 'application/vnd.api+json'},
        cacheDuration: _cacheDuration,
      );

      if (res.statusCode != 200) return const [];

      final data = jsonDecode(res.body)['data'];
      if (data is! List || data.isEmpty) return const [];

      final pageEpisodes = <EpisodeMetadata>[];
      for (final item in data) {
        if (item is! Map) continue;
        final attrs = item['attributes'];
        if (attrs is! Map) continue;

        final numRaw = attrs['number'] ?? attrs['relativeNumber'];
        final epNum = numRaw is num
            ? numRaw.toDouble()
            : double.tryParse(numRaw?.toString() ?? '');
        if (epNum == null) continue;

        String? title = attrs['canonicalTitle'] as String?;
        final titlesMap = attrs['titles'];
        if (titlesMap is Map) {
          title =
              (titlesMap['en_us'] ??
                      titlesMap['en'] ??
                      titlesMap['en_jp'] ??
                      title)
                  as String?;
        }

        String? thumbnailUrl;
        final thumb = attrs['thumbnail'];
        if (thumb is Map) {
          thumbnailUrl =
              (thumb['original'] ??
                      thumb['large'] ??
                      thumb['medium'] ??
                      thumb['small'])
                  as String?;
        }

        pageEpisodes.add(
          EpisodeMetadata(
            number: epNum,
            title: title,
            description: attrs['synopsis'] as String?,
            thumbnailUrl: thumbnailUrl,
            airDate: attrs['airdate'] as String?,
          ),
        );
      }
      return pageEpisodes;
    } catch (_) {
      return const [];
    }
  }
}
