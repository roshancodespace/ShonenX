import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core/jikan/jikan_service.dart';
import 'package:shonenx/core/models/aniskip/aniskip_result.dart';
import 'package:shonenx/core/services/aniskip_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

part 'aniskip_notifier.g.dart';

@riverpod
class AniSkipNotifier extends _$AniSkipNotifier {
  final JikanService _jikan = JikanService();
  @override
  List<AniSkipResultItem> build() {
    return const [];
  }

  Future<void> fetchSkipTimes({
    required String mediaId,
    required String animeTitle,
    required int episodeNumber,
    required int episodeLength,
  }) async {
    state = [];
    int? malId;

    try {
      // Try to get MAL ID from Anilist ID
      final anilistId = int.tryParse(mediaId);
      if (anilistId != null) {
        final media = await ref
            .read(anilistServiceProvider)
            .getAnimeDetails(anilistId);
        malId = media?.idMal;
      }

      // If not found, search via Jikan
      if (malId == null) {
        final results = await _jikan.getSearch(title: animeTitle, limit: 1);
        if (results.isNotEmpty) {
          malId = results.first.malId;
        }
      }

      if (malId != null) {
        final results = await aniSkipService.getSkipTimes(
          malId,
          episodeNumber,
          episodeLength,
        );
        state = results;
      } else {
        AppLogger.w('Could not resolve MAL ID for $animeTitle ($mediaId)');
      }
    } catch (e) {
      AppLogger.e('Failed to fetch skip times: $e');
      showAppSnackBar(
        'Aniskip',
        'Failed to fetch skip times: $e',
        type: ContentType.failure,
      );
    }
  }

  void clear() {
    state = [];
  }
}
