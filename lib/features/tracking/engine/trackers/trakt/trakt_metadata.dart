import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_filter_options.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/shared/models/media_title.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

mixin TraktMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  TrackerCredentials? get customCredentials => null;

  static const String _baseUrl = 'https://api.trakt.tv';

  static const String defaultClientId =
      '030ef1d48c8b417c8052aa8bc0d9eb4f40f0c0587d1591880ca0eb65851725cf';

  String get clientId => customCredentials?.clientId ?? defaultClientId;

  @override
  List<TrackerCategory> get supportedCategories => [
        TrackerCategory.trending,
        TrackerCategory.popular,
      ];

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': clientId,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  @override
  Future<TrackerProfile> fetchProfile() async {
    return executeApi('PROFILE', () async {
      final token = await (this as dynamic).getToken();
      if (token == null) throw Exception('Trakt is not authenticated');

      final response = await http.get(
        '$_baseUrl/users/me?extended=full',
        headers: _headers(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Trakt profile: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final username = data['username'] as String? ?? 'Trakt User';
      final ids = data['ids'] as Map<String, dynamic>? ?? {};
      final avatar = data['images']?['avatar']?['full'] as String?;

      return TrackerProfile(
        id: ids['slug']?.toString() ?? username,
        username: username,
        avatarUrl: avatar,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> getCategoryItems(
    TrackerCategory category, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    return executeApi('CATEGORY_ITEMS', () async {
      final endpoint = (category == TrackerCategory.popular) ? 'popular' : 'trending';
      final mediaPath = (type == MediaType.MOVIE) ? 'movies' : 'shows';
      final url = '$_baseUrl/$mediaPath/$endpoint?page=$page&limit=25&extended=full';

      final response = await http.get(url, headers: _headers());
      if (response.statusCode != 200) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      final List<dynamic> data = jsonDecode(response.body);
      final List<UnifiedMedia> items = [];

      for (final item in data) {
        final show = (item is Map && item.containsKey('show'))
            ? item['show']
            : ((item is Map && item.containsKey('movie')) ? item['movie'] : item);

        if (show == null || show is! Map) continue;
        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString() ?? '';
        final title = show['title'] as String? ?? 'Unknown';

        items.add(
          UnifiedMedia(
            id: traktId,
            sourceId: 'trakt',
            providerId: 'trakt',
            type: type,
            title: MediaTitle(english: title, romaji: title, userPreferred: title),
            description: show['overview'] as String?,
            year: show['year'] as int?,
            genres: (show['genres'] as List<dynamic>?)?.cast<String>(),
            externalIds: ExternalIds(
              mal: ids['mal']?.toString(),
              anilist: ids['anilist']?.toString(),
            ),
          ),
        );
      }

      return PaginatedResult(items: items, hasNextPage: items.length >= 25);
    });
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> search(
    String query, {
    int page = 1,
    required MediaType type,
    List<String>? genres,
    List<String>? tags,
    SearchSort sort = SearchSort.popularity,
    SearchStatusFilter status = SearchStatusFilter.all,
    SearchFormatFilter format = SearchFormatFilter.all,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    return executeApi('SEARCH', () async {
      final mediaPath = (type == MediaType.MOVIE) ? 'movie' : 'show';
      final clean = Uri.encodeComponent(query);
      final url = '$_baseUrl/search/$mediaPath?query=$clean&page=$page&limit=25&extended=full';

      final response = await http.get(url, headers: _headers());
      if (response.statusCode != 200) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      final List<dynamic> data = jsonDecode(response.body);
      final List<UnifiedMedia> items = [];

      for (final item in data) {
        final show = item['show'] ?? item['movie'];
        if (show == null || show is! Map) continue;

        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString() ?? '';
        final title = show['title'] as String? ?? 'Unknown';

        items.add(
          UnifiedMedia(
            id: traktId,
            sourceId: 'trakt',
            providerId: 'trakt',
            type: type,
            title: MediaTitle(english: title, romaji: title, userPreferred: title),
            description: show['overview'] as String?,
            year: show['year'] as int?,
            genres: (show['genres'] as List<dynamic>?)?.cast<String>(),
            externalIds: ExternalIds(
              mal: ids['mal']?.toString(),
              anilist: ids['anilist']?.toString(),
            ),
          ),
        );
      }

      return PaginatedResult(items: items, hasNextPage: items.length >= 25);
    });
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) {
    return executeApi('DETAILS', () async {
      final mediaPath = (type == MediaType.MOVIE) ? 'movies' : 'shows';
      final response = await http.get(
        '$_baseUrl/$mediaPath/$providerId?extended=full',
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load Trakt details: ${response.statusCode}');
      }

      final show = jsonDecode(response.body);
      final ids = show['ids'] as Map<String, dynamic>? ?? {};
      final title = show['title'] as String? ?? 'Unknown';

      final List<UnifiedEpisode> episodesList = [];
      if (type != MediaType.MOVIE) {
        final seasonsResp = await http.get(
          '$_baseUrl/shows/$providerId/seasons?extended=episodes',
          headers: _headers(),
        );

        if (seasonsResp.statusCode == 200) {
          final List<dynamic> seasons = jsonDecode(seasonsResp.body);
          for (final season in seasons) {
            final sNum = season['number'] as int? ?? 1;
            final List<dynamic> eps = season['episodes'] ?? [];
            for (final ep in eps) {
              final eNum = ep['number'] as int? ?? 1;
              episodesList.add(
                UnifiedEpisode(
                  id: '${providerId}_s${sNum}_e$eNum',
                  number: eNum.toDouble(),
                  title: ep['title'] as String? ?? 'Episode $eNum',
                  overview: ep['overview'] as String?,
                  seasonNumber: sNum,
                ),
              );
            }
          }
        }
      }

      return UnifiedMedia(
        id: providerId,
        sourceId: 'trakt',
        providerId: 'trakt',
        type: type,
        title: MediaTitle(english: title, romaji: title, userPreferred: title),
        description: show['overview'] as String?,
        year: show['year'] as int?,
        genres: (show['genres'] as List<dynamic>?)?.cast<String>(),
        episodes: episodesList,
        totalEpisodes: episodesList.isNotEmpty ? episodesList.length : null,
        externalIds: ExternalIds(
          mal: ids['mal']?.toString(),
          anilist: ids['anilist']?.toString(),
        ),
      );
    });
  }

  @override
  Future<TrackerFilterOptions> fetchFilterOptions([MediaType? type]) async =>
      const TrackerFilterOptions();

  @override
  Future<List<String>> fetchGenres() async => [];

  @override
  Future<List<String>> fetchTags() async => [];
}
