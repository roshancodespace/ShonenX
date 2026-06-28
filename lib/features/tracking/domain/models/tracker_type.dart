import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/local/local_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/mal/mal_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';

enum TrackerType {
  anilist('AniList'),
  myanimelist('MyAnimeList'),
  // kitsu('Kitsu'),
  local('Local');

  final String displayName;
  const TrackerType(this.displayName);

  String get id => name;

  factory TrackerType.fromId(String id) {
    return values.firstWhere((e) => e.id == id);
  }

  static TrackerType? tryFromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

extension TrackerTypeX on TrackerType {
  bool isAuthenticated(WidgetRef ref) =>
      this == TrackerType.local ||
      ref.watch(trackerProfileProvider)[this] != null;

  TrackerProfile? getProfile(WidgetRef ref) =>
      ref.watch(trackerProfileProvider)[this];

  TrackingService getTracker(Ref ref) {
    switch (this) {
      case TrackerType.anilist:
        return AnilistTracker(ref);
      case TrackerType.myanimelist:
        return MalTracker(ref);
      case TrackerType.local:
        return LocalTracker(ref.watch(databaseProvider));
      // default:
      //   throw UnimplementedError('Tracker type $this not implemented');
    }
  }

  String get iconSvgString {
    switch (this) {
      case TrackerType.anilist:
        return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path fill="currentColor" d="M24 17.53v2.421c0 .71-.391 1.101-1.1 1.101h-5l-.057-.165L11.84 3.736c.106-.502.46-.788 1.053-.788h2.422c.71 0 1.1.391 1.1 1.1v12.38H22.9c.71 0 1.1.392 1.1 1.101zM11.034 2.947l6.337 18.104h-4.918l-1.052-3.131H6.019l-1.077 3.131H0L6.361 2.948h4.673zm-.66 10.96l-1.69-5.014l-1.541 5.015h3.23z" />
        </svg>
        ''';
      case TrackerType.myanimelist:
        return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
          <path fill="currentColor" d="M14.921 6.479c-.82 0-3.683 0-4.947 3.156c-.662 1.652-.986 4.812.876 7.886l1.934-1.41s-.767-1.095-1.083-3.191h2.897l.022 3.19h2.604V8.835h-2.581v2.043l-2.46-.023s.413-2.408 2.877-2.336h2.454l-.572-2.04ZM0 6.528v9.624h2.348v-5.84l2.031 2.664l2.047-2.652v5.828h2.336V6.528H6.437L4.368 9.474L2.31 6.528Zm18.447.022v9.583h5.022L24 14.09h-3.232V6.55Z" />
        </svg>
        ''';
      default:
        throw UnimplementedError('Tracker type $this not implemented');
    }
  }
}
