import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:collection/collection.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/main.dart';

part 'anime_match_service.g.dart';

@Riverpod(keepAlive: true)
AnimeMatchService animeMatchService(Ref ref) {
  return AnimeMatchService(ref);
}

class AnimeMatchService {
  final Ref _ref;

  AnimeMatchService(this._ref);

  /// Finds the best match for the given [title] using the active source.
  ///
  /// Iterates through English, Romaji, and Native titles.
  /// Returns the best match as a [BaseAnimeModel] or null if no match is found.
  Future<BaseAnimeModel?> findBestMatch(UniversalTitle title) async {
    final titles = [
      title.english,
      title.romaji,
      title.native,
    ].where((t) => t != null && t.trim().isNotEmpty).cast<String>().toList();

    if (titles.isEmpty) {
      AppLogger.w("No valid title available for searching episodes.");
      return null;
    }

    for (final title in titles) {
      try {
        final results = await search(title);

        if (results.isEmpty) continue;

        final matches = getBestMatches<BaseAnimeModel>(
          results: results,
          title: title,
          nameSelector: (r) => r.name,
          idSelector: (r) => r.id,
        );

        if (matches.isNotEmpty && matches.first.similarity >= 0.75) {
          AppLogger.d(
            'High-confidence match found: ${matches.first.result.name} (via "$title")',
          );
          return matches.first.result;
        }
      } catch (e) {
        AppLogger.e('Error searching for title: $title', e);
        // Continue to next title
      }
    }

    return null;
  }

  /// Searches for anime using the configured source (Mangayomi or Legacy).
  Future<List<BaseAnimeModel>> search(String query) async {
    final useMangayomi = _ref.read(experimentalProvider).useMangayomiExtensions;

    if (useMangayomi) {
      final res = await _ref
          .read(sourceProvider.notifier)
          .search(Uri.encodeComponent(query));

      return res.list
          .where((r) => r.title != null && r.url != null)
          .map((r) => BaseAnimeModel(id: r.url, name: r.title, poster: r.cover))
          .toList();
    } else {
      final provider = _ref.read(selectedAnimeProvider);
      if (provider == null) return [];

      final res = await provider.getSearch(query, null, 1);

      return res.results.where((r) => r.id != null && r.name != null).toList();
    }
  }

  /// Attempts to restore a previously selected source for the given [animeId].
  ///
  /// Checks if smart source is enabled and if a saved selection exists.
  /// resteres the source (legacy or extension) and returns the matched anime.
  /// Returns null if restoration fails or is disabled.
  Future<BaseAnimeModel?> restoreSource(
    String animeId, {
    bool showSnackbar = false,
  }) async {
    try {
      // Smart Source Persistence Check
      final settings = _ref.read(contentSettingsProvider);
      AppLogger.d('Auto-Restore: Check enabled=${settings.smartSourceEnabled}');

      if (!settings.smartSourceEnabled) return null;

      final repo = _ref.read(watchProgressRepositoryProvider);
      final selection = repo.getSourceSelection(animeId);
      AppLogger.d('Auto-Restore: Selection found=${selection != null}');

      if (selection != null) {
        if (selection.sourceType == 'legacy') {
          AppLogger.d(
            'Auto-Restore: Restoring legacy source ${selection.sourceId}',
          );
          _ref
              .read(selectedProviderKeyProvider.notifier)
              .select(selection.sourceId!);
          final provider = _ref.read(selectedAnimeProvider);
          if (provider != null) {
            AppLogger.d('Auto-Restore: Success');
            if (showSnackbar) {
              showAppSnackBar('Smart Source', 'Restored previous source.');
            }
            return BaseAnimeModel(
              id: selection.matchedAnimeId,
              name: selection.matchedAnimeTitle,
            );
          } else {
            AppLogger.w('Auto-Restore: Legacy provider not found');
          }
        } else if (['mangayomi', 'aniyomi'].contains(selection.sourceType)) {
          AppLogger.d(
            'Auto-Restore: Restoring extension source ${selection.sourceId}',
          );
          // Switch to extensions
          _ref.read(experimentalProvider.notifier).toggleExtensions(true);

          final sourceNotifier = _ref.read(sourceProvider.notifier);
          final source = _ref
              .read(sourceProvider)
              .installedAnimeExtensions
              .firstWhereOrNull((s) => s.id.toString() == selection.sourceId);

          if (source != null) {
            sourceNotifier.setActiveSource(source);
            AppLogger.d('Auto-Restore: Success');
            if (showSnackbar) {
              showAppSnackBar('Smart Source', 'Restored previous source.');
            }
            return BaseAnimeModel(
              id: selection.matchedAnimeId,
              name: selection.matchedAnimeTitle,
            );
          } else {
            AppLogger.w('Auto-Restore: Extension source not found');
          }
        }
      }
    } catch (e, st) {
      AppLogger.e('Failed to auto-restore source selection', e, st);
    }
    return null;
  }
}
