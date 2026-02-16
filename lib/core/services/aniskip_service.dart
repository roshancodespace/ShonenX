import 'dart:convert';
import 'package:shonenx/core/models/aniskip/aniskip_result.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class AniSkipService {
  static const String _baseUrl = 'https://api.aniskip.com/v2';

  Future<List<AniSkipResultItem>> getSkipTimes(
    int malId,
    int episodeNumber,
    int episodeLength,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/skip-times/$malId/$episodeNumber?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=$episodeLength',
      );

      final response = await UniversalHttpClient.instance.get(
        uri,
        cacheConfig: CacheConfig.veryLong,
      );

      AppLogger.d('AniSkip API response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AniSkipResponse.fromJson(data);
        if (result.found) {
          return result.results;
        }
      } else {
        AppLogger.w('AniSkip API returned ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('Failed to fetch AniSkip data: $e');
    }
    return [];
  }
}

final aniSkipService = AniSkipService();
