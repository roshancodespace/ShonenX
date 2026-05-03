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
    int? episodeLength,
  }) async {
    final log = _log.child('getSkipTimes');

    try {
      final uri = Uri.parse(
        '$_baseUrl/$idMal/$episodeNumber'
        '?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap'
        '${episodeLength != null ? '&episodeLength=$episodeLength' : ''}',
      );

      log.d('Request → $uri');

      final response = await HTTP().get(uri.toString());

      if (response.statusCode != 200) {
        log.w('HTTP ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['found'] != true) {
        log.i('No skip data found');
        return [];
      }

      final List<dynamic> rawStamps = data['results'];

      final result = rawStamps
          .map((s) {
            final typeStr = s['skipType'] as String?;
            final interval = s['interval'] as Map<String, dynamic>?;

            if (typeStr == null || interval == null) return null;

            final start = (interval['startTime'] as num?)?.toDouble();
            final end = (interval['endTime'] as num?)?.toDouble();

            if (start == null || end == null) return null;

            return AniSkipStamp(
              type: _mapType(typeStr),
              startTime: start,
              endTime: end,
            );
          })
          .whereType<AniSkipStamp>()
          .toList();

      log.s('Fetched ${result.length} stamps');

      return result;
    } catch (e, st) {
      log.e('Fetch failed', e, st);
      return [];
    }
  }

  SkipType _mapType(String type) {
    switch (type) {
      case 'op':
      case 'mixed-op':
        return SkipType.opening;
      case 'ed':
      case 'mixed-ed':
        return SkipType.ending;
      case 'recap':
        return SkipType.recap;
      default:
        return SkipType.intro;
    }
  }
}
