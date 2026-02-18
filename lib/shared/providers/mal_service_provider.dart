import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/myanimelist/auth_service.dart';
import 'package:shonenx/core/services/myanimelist/mal_service.dart';
export 'package:shonenx/core/services/myanimelist/mal_service.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/settings/content_settings_notifier.dart';

final malServiceProvider = Provider<MyAnimeListService>((ref) {
  return MyAnimeListService(
    MyAnimeListAuthService(),
    getAccessToken: () {
      final authState = ref.read(authProvider);
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
    },
    getShowAdult: () {
      final settings = ref.read(contentSettingsProvider);
      return settings.showMalAdult;
    },
    onTokenRefresh: () async {
      await ref.read(authProvider.notifier).refreshMalToken();
    },
  );
});
