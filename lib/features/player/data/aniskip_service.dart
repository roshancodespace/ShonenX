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
    if (episodeLength == null || episodeLength < 50) {
      return [];
    }

    final log = _log.child('getSkipTimes');

    try {
      final uri = Uri.parse(
        '$_baseUrl/$idMal/$episodeNumber'
        '?types[]=${types.map((t) => t.apiID).join('&types[]=')}'
        '&episodeLength=$episodeLength',
      );

      log.d('Request → $uri');

      final response = await HTTP().get(uri.toString());

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          log.i('No skip data found (404) for MAL $idMal ep $episodeNumber');
        } else {
          log.w(
            'AniSkip HTTP ${response.statusCode} for MAL $idMal ep $episodeNumber',
          );
        }
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['found'] != true) {
        log.i('No skip data found for MAL $idMal ep $episodeNumber');
        return [];
      }

      final List<dynamic> rawStamps = data['results'] ?? [];

      final result = rawStamps
          .map((s) {
            final typeStr = s['skipType'] as String?;
            final interval = s['interval'] as Map<String, dynamic>?;

            if (typeStr == null || interval == null) return null;

            final mappedType = _mapType(typeStr);
            if (mappedType == null) return null;

            final start = (interval['startTime'] as num?)?.toDouble();
            final end = (interval['endTime'] as num?)?.toDouble();

            if (start == null || end == null) return null;

            return AniSkipStamp(
              type: mappedType,
              startTime: start,
              endTime: end,
            );
          })
          .whereType<AniSkipStamp>()
          .toList();

      log.s('Fetched ${result.length} stamps for MAL $idMal ep $episodeNumber');

      return result;
    } catch (e) {
      log.w('AniSkip fetch failed for MAL $idMal ep $episodeNumber: $e');
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
