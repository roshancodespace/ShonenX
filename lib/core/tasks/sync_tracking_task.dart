import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/services/anilist/anilist_service.dart';
import 'package:shonenx/core/services/myanimelist/mal_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class SyncTrackingTask {
  static Future<bool> performSync(Map<String, dynamic>? inputData) async {
    if (inputData == null) return false;

    try {
      final progress = inputData['progress'] as int?;
      if (progress == null) return false;

      final anilistId = inputData['anilistId'] as String?;
      final malId = inputData['malId'] as String?;

      bool success = true;
      const secureStorage = FlutterSecureStorage();

      if (anilistId != null) {
        final anilistToken = await secureStorage.read(key: 'anilist-token');

        if (anilistToken != null && anilistToken.isNotEmpty) {
          final service = AnilistService(
            getAuthContext: () => (userId: '', accessToken: anilistToken),
            getAdultParam: () => false,
          );

          try {
            final id = int.tryParse(anilistId);
            if (id != null) {
              await service.updateUserAnimeList(
                mediaId: id,
                status: 'CURRENT',
                progress: progress,
              );
              AppLogger.i('Background sync to Anilist succeeded for id $id');
            }
          } catch (e) {
            AppLogger.e('Background sync to Anilist failed', e);
            success = false;
          }
        }
      }

      if (malId != null) {
        final malToken = await secureStorage.read(key: 'mal-token');
        if (malToken != null && malToken.isNotEmpty) {
          final service = MyAnimeListService(
            getAccessToken: () => malToken,
            getShowAdult: () => false,
            onTokenRefresh: () async => false,
          );

          try {
            final id = int.tryParse(malId);
            if (id != null) {
              await service.updateUserAnimeList(
                mediaId: id,
                status: 'watching',
                progress: progress,
              );
              AppLogger.i('Background sync to MAL succeeded for id $id');
            }
          } catch (e) {
            AppLogger.e('Background sync to MAL failed', e);
            success = false;
          }
        }
      }

      return success;
    } catch (e) {
      AppLogger.e('SyncTrackingTask crashed', e);
      return false;
    }
  }
}
