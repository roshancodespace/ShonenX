import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/jikan/models/jikan_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class JikanEpisode {
  final int malId;
  final String title;
  final String? aired;
  final double? filler;
  final double? recap;

  JikanEpisode({
    required this.malId,
    required this.title,
    this.aired,
    this.filler,
    this.recap,
  });

  factory JikanEpisode.fromJson(Map<String, dynamic> json) {
    return JikanEpisode(
      malId: json['mal_id'] ?? 0,
      title: json['title'] ?? 'Episode ${json['mal_id']}',
      aired: json['aired'] != null ? json['aired'].toString() : null,
      filler: json['filler'] != null
          ? (json['filler'] as num).toDouble()
          : null,
      recap: json['recap'] != null ? (json['recap'] as num).toDouble() : null,
    );
  }
}

class JikanService {
  static const _baseUrl = 'https://api.jikan.moe/v4';

  Future<List<JikanMedia>> getSearch({
    required String title,
    int limit = 5,
  }) async {
    try {
      // Jikan search logic
      final url = '$_baseUrl/anime?q=$title&limit=$limit';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];
        return results.map((e) => JikanMedia.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Jikan Search Error: $e');
      return [];
    }
  }

  Future<List<JikanEpisode>> getEpisodes(int malId, int page) async {
    try {
      final url = '$_baseUrl/anime/$malId/episodes?page=$page';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> episodes = data['data'];
        return episodes.map((e) => JikanEpisode.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Jikan Episodes Error: $e');
      return [];
    }
  }
}
