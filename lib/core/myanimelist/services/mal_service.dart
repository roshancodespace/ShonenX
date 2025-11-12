import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/myanimelist/services/auth_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/auth_provider.dart';

class MyAnimeListServiceException implements Exception {
  final String message;
  final dynamic error;
  MyAnimeListServiceException(this.message, [this.error]);

  String toString() =>
      'MyAnimeListServiceException: $message${error != null ? ' ($error)' : ''}';
}

class MyAnimeListService {
  final Ref _ref;
  final MyAnimeListAuthService _authService;
  MyAnimeListService(this._ref, this._authService);

  String get name => 'MyAnimeList';

  String? _getAccessToken() {
    final authState = _ref.read(authProvider);
    if (!authState.isMalAuthenticated ||
        authState.activePlatform != AuthPlatform.mal) {
      AppLogger.w('MAL operation requires a logged-in MAL user.');
      return null;
    }
    final token = authState.malAccessToken;
    if (token == null || token.isEmpty) {
      AppLogger.w('Access token is missing for MAL operation.');
      return null;
    }
    return token;
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final token = _getAccessToken();
    if (token == null) throw Exception('User not authenticated');

    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
      ...?headers,
    });

    if (res.statusCode == 401) {
      // token expired, refresh
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        // update state
        _ref.read(authProvider.notifier).refreshMalToken();
        return _get(url, headers: headers);
      }
    }

    if (res.statusCode != 200) {
      throw MyAnimeListServiceException('GET request failed: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = _getAccessToken();
    if (token == null) throw Exception('User not authenticated');

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      // token expired
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        _ref.read(authProvider.notifier).refreshMalToken();
        return _post(url, body);
      }
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw MyAnimeListServiceException('POST request failed: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------------- USER PROFILE ----------------------
  Future<Map<String, dynamic>> getUserProfile() async {
    final data = await _get('https://api.myanimelist.net/v2/users/@me');
    return data;
  }

  // ---------------------- USER ANIME LIST ----------------------
  Future<PageResponse> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    final endpoint = type == "MANGA" ? "mangalist" : "animelist";
    final url =
        'https://api.myanimelist.net/v2/users/@me/$endpoint?status=$status&limit=$perPage&offset=${(page - 1) * perPage}';
    final data = await _get(url);

    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => MediaListEntry.fromMal(e as Map<String, dynamic>))
        .toList();

    final hasNextPage = data['paging']?['next'] != null;

    return PageResponse(
      pageInfo: PageInfo(
        total: -1,
        currentPage: page,
        lastPage: hasNextPage ? page + 1 : page,
        hasNextPage: hasNextPage,
        perPage: perPage,
      ),
      mediaList: list,
    );
  }

  // ---------------------- ANIME DETAILS ----------------------
  Future<Media?> getAnimeDetails(int animeId) async {
    final url = 'https://api.myanimelist.net/v2/anime/$animeId';
    final data = await _get(url);
    return Media.fromMal(data);
  }

  // ---------------------- FAVORITES ----------------------
  Future<List<Media>> getFavorites() async {
    final url =
        'https://api.myanimelist.net/v2/users/@me/animelist?status=favorites';
    final data = await _get(url);
    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => Media.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Media>> toggleFavorite(int animeId) async {
    // MAL API does not have toggle endpoint; would need POST to add/remove from favorites
    return [] as List<Media>;
  }

  // ---------------------- SEARCH ----------------------
  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10}) async {
    final offset = (page - 1) * perPage;
    final url =
        'https://api.myanimelist.net/v2/anime?q=$title&limit=$perPage&offset=$offset';
    final data = await _get(url);

    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => Media.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

// ---------------------- SINGLE ENTRY ----------------------
  Future<MediaListEntry?> getAnimeEntry(int animeId) async {
    final url = 'https://api.myanimelist.net/v2/users/@me/animelist/$animeId';
    try {
      final data = await _get(url);
      return MediaListEntry.fromMal(data);
    } catch (e) {
      AppLogger.e('Failed to fetch anime entry', e);
      return null;
    }
  }

  Future<List<Media>> getPopularAnime() async {
    // TODO: implement getPopularAnime
    return [] as List<Media>;
  }

  Future<List<Media>> getRecentlyUpdatedAnime() async {
    // TODO: implement getRecentlyUpdatedAnime
    return [] as List<Media>;
  }

  Future<List<Media>> getTopRatedAnime() async {
    // TODO: implement getTopRatedAnime
    return [] as List<Media>;
  }

  Future<List<Media>> getTrendingAnime() async {
    // TODO: implement getTrendingAnime
    return [] as List<Media>;
  }

  Future<List<Media>> getUpcomingAnime() async {
    // TODO: implement getUpcomingAnime
    return [] as List<Media>;
  }

  Future<MediaListEntry?> updateUserAnimeList(
      {required int mediaId,
      String? status,
      double? score,
      int? progress,
      FuzzyDateInput? startedAt,
      FuzzyDateInput? completedAt,
      int? repeat,
      String? notes,
      bool? private}) async {
    // TODO async: implement updateUserAnimeList
    return null;
  }
}

final malServiceProvider = Provider<MyAnimeListService>((ref) {
  final authService = ref.read(malAuthServiceProvider);
  return MyAnimeListService(ref, authService);
});

