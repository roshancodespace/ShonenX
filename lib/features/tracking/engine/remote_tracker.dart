import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_filter_options.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';

abstract interface class RemoteTracker implements TrackingService {
  Authenticator get authenticator;

  Future<TrackerProfile> fetchProfile();

  Future<TrackerFilterOptions> fetchFilterOptions([MediaType? type]) async =>
      const TrackerFilterOptions();

  @Deprecated('Use fetchFilterOptions() instead')
  Future<List<String>> fetchGenres();

  @Deprecated('Use fetchFilterOptions() instead')
  Future<List<String>> fetchTags();

  List<TrackerCategory> get supportedCategories => [
    TrackerCategory.trending,
    TrackerCategory.popular,
    TrackerCategory.topRated,
    TrackerCategory.upcoming,
  ];

  Future<PaginatedResult<UnifiedMedia>> getCategoryItems(
    TrackerCategory category, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  });

  @Deprecated('Use getCategoryItems(TrackerCategory.trending) instead')
  Future<PaginatedResult<UnifiedMedia>> getTrending({
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) => getCategoryItems(
    TrackerCategory.trending,
    page: page,
    type: type,
    cacheDuration: cacheDuration,
    adultMode: adultMode,
  );

  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
  });

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
  });

  Future<UnifiedMedia> getDetails(String providerId, MediaType type);

  Future<PaginatedResult<MediaCharacter>> getCharacters(
    String providerId, {
    int page = 1,
    int perPage = 25,
    MediaType type = MediaType.ANIME,
  }) => Future.value(PaginatedResult(items: [], hasNextPage: false));

  Future<MediaCharacter?> getCharacterDetails(String characterId) =>
      Future.value(null);
}
