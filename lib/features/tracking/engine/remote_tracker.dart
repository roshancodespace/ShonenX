import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

abstract interface class RemoteTracker implements TrackingService {
  Authenticator get authenticator;
  
  Future<TrackerProfile> fetchProfile();
  
  Future<List<TrackerSearchResult>> searchMedia(String query);

  Future<PaginatedResult<UnifiedMedia>> getTrending({int page = 1});

  Future<PaginatedResult<UnifiedMedia>> search(String query, {int page = 1});

  Future<UnifiedMedia> getDetails(String providerId, MediaType type);
}
