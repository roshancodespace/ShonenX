import 'dart:convert';

import 'package:shonenx/core/jikan/models/jikan_media.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';

class JikanService {
  static const _baseUrl = "https://api.jikan.moe/v4";

  static Future<dynamic> _fetch(String endpoint) async {
    AppLogger.w("$_baseUrl$endpoint");
    return jsonDecode((await http.get(Uri.parse("$_baseUrl$endpoint"))).body);
  }

  Future<List<JikanMedia>> getSearch(
      {required String title,
      int page = 1,
      int limit = 10,
      String mediaType = 'anime'}) async {
    try {
      final data = await _fetch("/$mediaType?q=$title?page=$page&limit=$limit");
      return (data?['data'] as List<dynamic>)
          .map((itemJson) =>
              JikanMedia.fromMap(itemJson as Map<String, dynamic>))
          .toList();
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<List<StreamingEpisode>> getEpisodes(int animeId, int page) async {
    try {
      final data = await _fetch('/anime/$animeId/episodes?page=$page');
      return (data?['data'] as List<dynamic>)
          .map((itemJson) => StreamingEpisode(
              title: _parseJikanTitle(itemJson['title']),
              url: itemJson['url'] ?? '',
              id: itemJson['mal_id']))
          .toList();
    } catch (err) {
      throw Exception(err);
    }
  }

  String _parseJikanTitle(dynamic raw) {
    if (raw == null) return 'Unknown';
    if (raw is String) return raw;
    if (raw is Map<String, dynamic>) {
      return raw['english'] ?? raw['romaji'] ?? 'Unknown';
    }
    return 'Unknown';
  }
}
