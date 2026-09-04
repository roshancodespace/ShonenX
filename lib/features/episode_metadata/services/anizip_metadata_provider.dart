import 'dart:convert';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/episode_metadata/domain/interfaces/episode_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/features/episode_metadata/services/title_matcher.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class AniZipEpisodeMetadataProvider implements EpisodeMetadataProvider {
  final HTTP _http;
  final _log = AppLogger.scope('EpisodeMetadata.AniZip');
  static const _cacheDuration = Duration(days: 30);
  static const _aniListEndpoint = 'https://graphql.anilist.co';

  AniZipEpisodeMetadataProvider({HTTP? http}) : _http = http ?? HTTP();

  @override
  String get id => 'anizip';

  @override
  String get name => 'AniZip';

  @override
  Future<String?> resolveId({required UnifiedMedia media}) async {
    // 1. Direct Provider Match (O(1))
    final providerId = media.providerId?.toLowerCase();
    if (providerId == 'anilist' && media.id.isNotEmpty) {
      _log.d('Direct AniList ID from provider: ${media.id}');
      return 'anilist_id=${media.id}';
    }
    if ((providerId == 'mal' || providerId == 'myanimelist') &&
        media.id.isNotEmpty) {
      _log.d('Direct MAL ID from provider: ${media.id}');
      return 'mal_id=${media.id}';
    }
    if (providerId == 'kitsu' && media.id.isNotEmpty) {
      _log.d('Direct Kitsu ID from provider: ${media.id}');
      return 'kitsu_id=${media.id}';
    }
    if (providerId == 'anidb' && media.id.isNotEmpty) {
      _log.d('Direct AniDB ID from provider: ${media.id}');
      return 'anidb_id=${media.id}';
    }

    // 2. External ID Cross-Mappings (O(1))
    if (media.externalIds.anilist?.isNotEmpty == true) {
      _log.d(
        'Resolved AniList ID from externalIds: ${media.externalIds.anilist}',
      );
      return 'anilist_id=${media.externalIds.anilist}';
    }
    if (media.idMal?.isNotEmpty == true) {
      _log.d('Resolved MAL ID from idMal: ${media.idMal}');
      return 'mal_id=${media.idMal}';
    }
    if (media.externalIds.mal?.isNotEmpty == true) {
      _log.d('Resolved MAL ID from externalIds: ${media.externalIds.mal}');
      return 'mal_id=${media.externalIds.mal}';
    }
    if (media.externalIds.kitsu?.isNotEmpty == true) {
      _log.d('Resolved Kitsu ID from externalIds: ${media.externalIds.kitsu}');
      return 'kitsu_id=${media.externalIds.kitsu}';
    }
    final anidbId = media.externalIds.get('anidb');
    if (anidbId?.isNotEmpty == true) {
      _log.d('Resolved AniDB ID from externalIds: $anidbId');
      return 'anidb_id=$anidbId';
    }

    // 3. Title-based Fallback (Simkl, generic scrapers, or sources with no cross-IDs)
    _log.i(
      'No direct ID found for AniZip; resolving by title for "${media.title.availableTitle}" (origin: ${media.providerId ?? media.sourceId})',
    );
    return await _resolveIdByTitle(media);
  }

  /// Searches AniList GraphQL (primary) or Kitsu API (secondary) by title
  /// to discover a valid AniList, MAL, or Kitsu ID for AniZip.
  Future<String?> _resolveIdByTitle(UnifiedMedia media) async {
    final targetTitles = TitleMatcher.extractTargetTitles(media);
    if (targetTitles.isEmpty) return null;

    // A. Try AniList GraphQL search (fast, reliable, provides both AniList ID and MAL ID)
    final aniListMatch = await _searchAniList(media, targetTitles);
    if (aniListMatch != null) {
      _log.d('Resolved AniZip target via AniList title search: $aniListMatch');
      return aniListMatch;
    }

    // B. Fallback to Kitsu title search
    final kitsuMatch = await _searchKitsu(targetTitles);
    if (kitsuMatch != null) {
      _log.d('Resolved AniZip target via Kitsu title search: $kitsuMatch');
      return kitsuMatch;
    }

    _log.w(
      'Could not resolve AniZip ID by title for "${media.title.availableTitle}"',
    );
    return null;
  }

  Future<String?> _searchAniList(
    UnifiedMedia media,
    List<String> targetTitles,
  ) async {
    final title = media.title.availableTitle;
    if (title.trim().isEmpty) return null;

    try {
      const query = '''
        query (\$search: String) {
          Page(page: 1, perPage: 8) {
            media(search: \$search, type: ANIME) {
              id
              idMal
              title {
                romaji
                english
                native
              }
            }
          }
        }
      ''';

      final res = await _http.post(
        _aniListEndpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'search': title},
        }),
        cacheDuration: _cacheDuration,
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data']?['Page']?['media'];
      if (data is! List || data.isEmpty) return null;

      final match = TitleMatcher.findBestMatch<dynamic>(
        targetTitles: targetTitles,
        candidates: data,
        extractCandidateTitles: (item) {
          final titles = <String>[];
          if (item is Map) {
            final tMap = item['title'];
            if (tMap is Map) {
              if (tMap['english'] is String) titles.add(tMap['english']);
              if (tMap['romaji'] is String) titles.add(tMap['romaji']);
              if (tMap['native'] is String) titles.add(tMap['native']);
            }
          }
          return titles;
        },
      );

      if (match?.item is Map) {
        final matchedItem = match!.item as Map;
        final anilistId = matchedItem['id']?.toString();
        if (anilistId != null && anilistId.isNotEmpty) {
          return 'anilist_id=$anilistId';
        }
        final malId = matchedItem['idMal']?.toString();
        if (malId != null && malId.isNotEmpty) {
          return 'mal_id=$malId';
        }
      }
    } catch (e) {
      _log.d('AniList search failed: $e');
    }
    return null;
  }

  Future<String?> _searchKitsu(List<String> targetTitles) async {
    final queryTitle = targetTitles.first;
    try {
      final url =
          'https://kitsu.io/api/edge/anime?filter[text]=${Uri.encodeComponent(queryTitle)}&page[limit]=8';
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

      if (match?.item is Map) {
        final id = match!.item['id']?.toString();
        if (id != null && id.isNotEmpty) {
          return 'kitsu_id=$id';
        }
      }
    } catch (e) {
      _log.d('Kitsu fallback search failed: $e');
    }
    return null;
  }

  @override
  Future<List<EpisodeMetadata>> fetchEpisodes({
    required UnifiedMedia media,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Matching anime with AniZip...');
    final target = await resolveId(media: media);
    if (target == null || target.isEmpty) return const [];

    onProgress?.call('Fetching episodes from AniZip...');

    try {
      final url = 'https://api.ani.zip/mappings?$target';
      final res = await _http.get(url, cacheDuration: _cacheDuration);

      if (res.statusCode != 200) {
        _log.w('AniZip returned status ${res.statusCode} for $target');
        return const [];
      }

      final jsonBody = jsonDecode(res.body);
      if (jsonBody is! Map) return const [];

      final episodesMap = jsonBody['episodes'];
      if (episodesMap is! Map || episodesMap.isEmpty) {
        _log.i('AniZip returned 0 episodes for $target');
        return const [];
      }

      final episodes = <EpisodeMetadata>[];

      for (final entry in episodesMap.entries) {
        final epData = entry.value;
        if (epData is! Map) continue;

        final epNumRaw = epData['episode'] ?? entry.key;
        final epNum = epNumRaw is num
            ? epNumRaw.toDouble()
            : double.tryParse(epNumRaw?.toString() ?? '');
        if (epNum == null) continue; // Skip specials like "S1", "O1" etc.

        String? titleEn;
        String? titleJa;
        String? titleRomaji;

        final rawTitle = epData['title'];
        if (rawTitle is Map) {
          titleEn = _sanitizeTitle(rawTitle['en'] as String?);
          titleJa = _sanitizeTitle(rawTitle['ja'] as String?);
          titleRomaji = _sanitizeTitle(
            (rawTitle['x-jat'] ?? rawTitle['romaji']) as String?,
          );

          if (titleEn == null) {
            for (final v in rawTitle.values) {
              if (v is String && v.trim().isNotEmpty) {
                titleEn = _sanitizeTitle(v);
                break;
              }
            }
          }
        } else if (rawTitle is String) {
          titleEn = _sanitizeTitle(rawTitle);
        }

        final scoreRaw = epData['rating'];
        final score = scoreRaw is num
            ? scoreRaw.toDouble()
            : double.tryParse(scoreRaw?.toString() ?? '');

        final rawThumb = epData['image'] ?? epData['thumbnail'];
        final thumbnailUrl = rawThumb is String && rawThumb.trim().isNotEmpty
            ? rawThumb.trim()
            : null;

        episodes.add(
          EpisodeMetadata(
            number: epNum,
            title: titleEn,
            japaneseTitle: titleJa,
            romanjiTitle: titleRomaji,
            description: epData['summary'] as String?,
            thumbnailUrl: thumbnailUrl,
            airDate: epData['airdate'] as String?,
            score: score,
          ),
        );
      }

      episodes.sort((a, b) => a.number.compareTo(b.number));

      if (episodes.isNotEmpty) {
        _log.s('Loaded ${episodes.length} episodes from AniZip ($target)');
      }
      return episodes;
    } catch (e, st) {
      _log.e('Failed to fetch AniZip episodes ($target)', [e, st]);
      return const [];
    }
  }

  String? _sanitizeTitle(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    return str.replaceAll('`', "'").trim();
  }
}
