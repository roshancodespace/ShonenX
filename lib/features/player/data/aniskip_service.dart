import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';

class AniSkipService {
  static const _baseUrl = 'https://api.aniskip.com/v2/skip-times';

  final _log = AppLogger.scope(AniSkipService);

  Future<List<AniSkipStamp>> getSkipTimes({
    required int idMal,
    required int episodeNumber,
    required List<SkipType> types,
    int? episodeLength,
  }) async {
    final log = _log.child('getSkipTimes');

    try {
      // 1. First attempt: Query with specific episode length if provided
      List<AniSkipStamp> stamps = await _fetchStamps(
        idMal: idMal,
        episodeNumber: episodeNumber,
        types: types,
        episodeLength: (episodeLength != null && episodeLength >= 50)
            ? episodeLength
            : 0,
        log: log,
      );

      // 2. Fallback attempt: If not found and length was specified, query with episodeLength=0 (generic match)
      if (stamps.isEmpty && episodeLength != null && episodeLength > 0) {
        log.d('Retrying AniSkip with episodeLength=0 for fallback match...');
        stamps = await _fetchStamps(
          idMal: idMal,
          episodeNumber: episodeNumber,
          types: types,
          episodeLength: 0,
          log: log,
        );
      }

      log.s('Fetched ${stamps.length} stamps for MAL $idMal ep $episodeNumber');
      return stamps;
    } catch (e) {
      log.w('AniSkip fetch failed for MAL $idMal ep $episodeNumber: $e');
      return [];
    }
  }

  Future<List<AniSkipStamp>> _fetchStamps({
    required int idMal,
    required int episodeNumber,
    required List<SkipType> types,
    required int episodeLength,
    required dynamic log,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$idMal/$episodeNumber'
        '?types[]=${types.map((t) => t.apiID).join('&types[]=')}'
        '&episodeLength=$episodeLength',
      );

      final response = await HTTP().get(uri.toString());

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data['found'] != true) {
        return [];
      }

      final List<dynamic> rawStamps = data['results'] ?? [];

      return rawStamps
          .map((s) {
            final typeStr = s['skipType'] as String?;
            final interval = s['interval'] as Map<String, dynamic>?;

            if (typeStr == null || interval == null) return null;

            final mappedType = _mapType(typeStr);
            if (mappedType == null) return null;

            final start = (interval['startTime'] as num?)?.toDouble();
            final end = (interval['endTime'] as num?)?.toDouble();

            if (start == null || end == null || start < 0 || end <= start) {
              return null;
            }

            return AniSkipStamp(
              type: mappedType,
              startTime: start,
              endTime: end,
            );
          })
          .whereType<AniSkipStamp>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  SkipType? _mapType(String type) {
    switch (type.toLowerCase()) {
      case 'op':
        return SkipType.opening;
      case 'ed':
        return SkipType.ending;
      case 'mixed-op':
        return SkipType.mixedOpening;
      case 'mixed-ed':
        return SkipType.mixedEnding;
      case 'recap':
        return SkipType.recap;
      default:
        return null;
    }
  }
}
