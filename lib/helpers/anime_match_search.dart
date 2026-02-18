import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/providers/anime_match_service.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/shared/ui/anime/anime_search_dialog.dart';

Future<BaseAnimeModel?> providerAnimeMatchSearch({
  Function? beforeSearchCallback,
  Function? afterSearchCallback,
  required BuildContext context,
  required WidgetRef ref,
  required UniversalMedia animeMedia,
  bool withAnimeMatch = true,
  int? startAt,
  bool showSnackbar = false,
}) async {
  beforeSearchCallback?.call();

  try {
    // Check saved source preference
    final restoredAnime = await ref
        .read(animeMatchServiceProvider)
        .restoreSource(animeMedia.id.toString(), showSnackbar: showSnackbar);

    if (restoredAnime != null && withAnimeMatch) {
      AppLogger.d('Navigating to watch screen...');
      if (context.mounted) {
        navigateToWatch(
          context: context,
          ref: ref,
          mediaId: animeMedia.id.toString(),
          animeId: restoredAnime.id!,
          animeName: restoredAnime.name ?? 'Unknown',
          animeFormat: animeMedia.format ?? '',
          animeCover: restoredAnime.poster ?? '',
          episodes: const [],
          currentEpisode: startAt ?? 1,
        );
      }
      return restoredAnime;
    }

    // Show search dialog
    final animeProvider = ref.read(selectedAnimeProvider);
    if (animeProvider == null) throw Exception('Anime provider is missing.');
    if (!context.mounted) return null;

    return await showDialog<BaseAnimeModel>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AnimeSearchDialog(
        animeProvider: animeProvider,
        media: animeMedia,
        autoMatch: withAnimeMatch,
        startAt: startAt,
      ),
    );
  } catch (e, s) {
    AppLogger.e('Search failed', e, s);
    if (context.mounted) {
      // Use your snackbar helper
      showAppSnackBar(
        'Error',
        'Failed to load details.',
        type: ContentType.failure,
      );
    }
    return null;
  } finally {
    afterSearchCallback?.call();
  }
}