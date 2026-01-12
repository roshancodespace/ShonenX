import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/anilist/services/anilist_service.dart';
export 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';

final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService(
    getAuthContext: () {
      final authState = ref.read(authProvider);

      if (!authState.isAniListAuthenticated ||
          authState.activePlatform != AuthPlatform.anilist) {
        AppLogger.w('Anilist operation requires a logged-in Anilist user.');
        return null;
      }

      final userId = authState.anilistUser?.id;
      final accessToken = authState.anilistAccessToken;

      if (userId == null || accessToken == null || accessToken.isEmpty) {
        AppLogger.w(
            'Invalid user ID or access token for authenticated operation.');
        return null;
      }
      return (userId: userId.toString(), accessToken: accessToken);
    },
    getAdultParam: () {
      final settings = ref.read(contentSettingsProvider);
      return (settings.showAnilistAdult == true) ? null : false;
    },
  );
});
