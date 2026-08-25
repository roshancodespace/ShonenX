import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final aniSkipResolverProvider = Provider<AniSkipResolver>((ref) {
  return AniSkipResolver(ref);
});

class AniSkipResolver {
  final Ref _ref;
  final _log = AppLogger.scope(AniSkipResolver);
  static const _anilistEndpoint = 'https://graphql.anilist.co';

  AniSkipResolver(this._ref);

  /// Resolves the MyAnimeList (MAL) ID required by AniSkip from available media metadata.
  Future<int?> resolveMalId({UnifiedMedia? media, int? idMal}) async {
    // 1. Direct MAL ID parameter
    if (idMal != null && idMal > 0) {
      return idMal;
    }

    if (media == null) {
      return null;
    }

    final title = media.title.availableTitle;

    // 2. Check externalIds.mal
    final extMalStr = media.externalIds.mal;
    if (extMalStr != null && extMalStr.isNotEmpty) {
      final parsed = int.tryParse(extMalStr);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    // 3. Check media.idMal
    final directMalStr = media.idMal;
    if (directMalStr != null && directMalStr.isNotEmpty) {
      final parsed = int.tryParse(directMalStr);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    // 4. Check if provider is MAL itself
    final providerId = media.providerId?.toLowerCase();
    if (providerId == 'mal' || providerId == 'myanimelist') {
      final parsed = int.tryParse(media.id);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    // 5. Check local database tracker links
    try {
      final links = await _ref.read(trackerLinkProvider(media.id).future);
      final malMapping = links[TrackerType.myanimelist];
      if (malMapping?.trackingId != null) {
        final parsed = int.tryParse(malMapping!.trackingId!);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    } catch (_) {}

    // 6. Resolve from AniList ID
    final anilistIdStr =
        media.externalIds.anilist ??
        ((providerId == 'anilist' || media.sourceId == 'anilist')
            ? media.id
            : null);

    if (anilistIdStr != null && anilistIdStr.isNotEmpty) {
      final anilistId = int.tryParse(anilistIdStr);
      if (anilistId != null && anilistId > 0) {
        final resolved = await _resolveMalFromAniListId(anilistId);
        if (resolved != null) {
          return resolved;
        }
      }
    }

    // 7. Resolve from Title search (e.g. Source Discovery mode)
    if (title.isNotEmpty && title != 'Unknown' && title != 'Local Media') {
      final resolved = await _resolveMalFromTitle(title);
      if (resolved != null) {
        return resolved;
      }
    }

    _log.i('AniSkip lookup skipped: no MAL identifier resolved for "$title"');
    return null;
  }

  Future<int?> _resolveMalFromAniListId(int anilistId) async {
    try {
      const query = '''
        query (\$id: Int) {
          Media(id: \$id, type: ANIME) {
            idMal
          }
        }
      ''';

      final response = await HTTP().post(
        _anilistEndpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'id': anilistId},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idMal = data['data']?['Media']?['idMal'] as int?;
        if (idMal != null && idMal > 0) {
          return idMal;
        }
      }
    } catch (e) {
      _log.w('Failed to resolve MAL ID from AniList ID $anilistId: $e');
    }
    return null;
  }

  Future<int?> _resolveMalFromTitle(String title) async {
    try {
      const query = '''
        query (\$search: String) {
          Media(search: \$search, type: ANIME) {
            id
            idMal
          }
        }
      ''';

      final response = await HTTP().post(
        _anilistEndpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'search': title},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idMal = data['data']?['Media']?['idMal'] as int?;
        if (idMal != null && idMal > 0) {
          return idMal;
        }
      }
    } catch (e) {
      _log.w('Failed to resolve MAL ID from title "$title": $e');
    }
    return null;
  }
}
