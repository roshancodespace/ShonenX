import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/anilist/anilist_service.dart';
import 'package:shonenx/core/services/myanimelist/auth_service.dart';
import 'package:shonenx/core/services/myanimelist/mal_service.dart';
import 'package:shonenx/core/services/tracker/external_tracker_service.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/settings/content_settings_notifier.dart';

final trackerAnilistServiceProvider = Provider<AnilistService?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isAniListAuthenticated) return null;

  final userId = authState.anilistUser?.id;
  final accessToken = authState.anilistAccessToken;

  if (userId == null || accessToken == null || accessToken.isEmpty) return null;

  return AnilistService(
    getAuthContext: () => (userId: userId.toString(), accessToken: accessToken),
    getAdultParam: () {
      final settings = ref.read(contentSettingsProvider);
      return (settings.showAnilistAdult == true) ? null : false;
    },
  );
});

final trackerMalServiceProvider = Provider<MyAnimeListService?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isMalAuthenticated) return null;

  final token = authState.malAccessToken;
  if (token == null || token.isEmpty) return null;

  return MyAnimeListService(
    MyAnimeListAuthService(),
    getAccessToken: () => token,
    getShowAdult: () {
      final settings = ref.read(contentSettingsProvider);
      return settings.showMalAdult;
    },
    onTokenRefresh: () async {
      await ref.read(authProvider.notifier).refreshMalToken();
    },
  );
});

final externalTrackerServiceProvider = Provider<ExternalTrackerService>((ref) {
  return ExternalTrackerService(
    anilistService: ref.watch(trackerAnilistServiceProvider),
    malService: ref.watch(trackerMalServiceProvider),
  );
});
