import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/anilist/anilist_service.dart';
import 'package:shonenx/core/services/myanimelist/mal_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/isar/external_track_binding.dart';
import 'package:shonenx/main.dart';

class ExternalTrackerService {
  final AnilistService? _anilistService;
  final MyAnimeListService? _malService;

  ExternalTrackerService({
    AnilistService? anilistService,
    MyAnimeListService? malService,
  }) : _anilistService = anilistService,
       _malService = malService;

  Future<List<TrackerSearchResult>> searchMedia(
    TrackerType tracker,
    String query,
  ) async {
    try {
      switch (tracker) {
        case TrackerType.anilist:
          if (_anilistService == null) return [];
          final results = await _anilistService.searchAnime(query, perPage: 10);
          return results
              .map(
                (m) => TrackerSearchResult(
                  remoteId: m.id is int
                      ? m.id as int
                      : int.tryParse(m.id.toString()) ?? 0,
                  title: m.title?.english ?? m.title?.romaji ?? 'Unknown',
                  imageUrl: m.coverImage?.large ?? m.coverImage?.medium,
                  format: m.format,
                  episodes: m.episodes,
                  status: m.status,
                  score: m.averageScore,
                  year: m.seasonYear,
                ),
              )
              .toList();

        case TrackerType.mal:
          if (_malService == null) return [];
          final results = await _malService.searchAnime(query, perPage: 10);
          return results
              .map(
                (m) => TrackerSearchResult(
                  remoteId: int.tryParse(m.id) ?? 0,
                  title: m.title.english ?? m.title.romaji ?? 'Unknown',
                  imageUrl: m.coverImage.large ?? m.coverImage.medium,
                  format: m.format,
                  episodes: m.episodes,
                  status: m.status,
                  score: m.averageScore,
                  year: m.seasonYear,
                ),
              )
              .toList();
      }
    } catch (e, st) {
      AppLogger.e('Tracker search failed for $tracker', e, st);
      return [];
    }
  }

  Future<TrackerEntry?> getTrackerEntry(
    TrackerType tracker,
    int remoteId,
  ) async {
    try {
      switch (tracker) {
        case TrackerType.anilist:
          if (_anilistService == null) return null;
          final entry = await _anilistService.getAnimeEntry(remoteId);
          if (entry == null) return null;
          return TrackerEntry(
            tracker: TrackerType.anilist,
            remoteId: remoteId,
            status: entry.status,
            progress: entry.progress,
            score: entry.score,
            startDate: entry.startedAt?.toDateTime,
            endDate: entry.completedAt?.toDateTime,
          );

        case TrackerType.mal:
          if (_malService == null) return null;
          final entry = await _malService.getAnimeEntry(remoteId);
          if (entry == null) return null;
          return TrackerEntry(
            tracker: TrackerType.mal,
            remoteId: remoteId,
            status: _mapMalStatusToUniversal(entry.status),
            progress: entry.progress,
            score: entry.score,
            title: entry.media.title.userPreferred,
          );
      }
    } catch (e, st) {
      AppLogger.e('Failed to get tracker entry for $tracker:$remoteId', e, st);
      return null;
    }
  }

  Future<bool> updateTrackerEntry(
    TrackerType tracker,
    int remoteId, {
    String? status,
    int? progress,
    double? score,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      switch (tracker) {
        case TrackerType.anilist:
          if (_anilistService == null) return false;
          final result = await _anilistService.updateUserAnimeList(
            mediaId: remoteId,
            status: status,
            score: score,
            progress: progress,
            startedAt: startDate != null
                ? FuzzyDate(
                    year: startDate.year,
                    month: startDate.month,
                    day: startDate.day,
                  )
                : null,
            completedAt: endDate != null
                ? FuzzyDate(
                    year: endDate.year,
                    month: endDate.month,
                    day: endDate.day,
                  )
                : null,
          );
          return result != null;

        case TrackerType.mal:
          if (_malService == null) return false;
          final result = await _malService.updateUserAnimeList(
            mediaId: remoteId,
            status: status,
            score: score,
            progress: progress,
            startedAt: startDate != null
                ? FuzzyDate(
                    year: startDate.year,
                    month: startDate.month,
                    day: startDate.day,
                  )
                : null,
            completedAt: endDate != null
                ? FuzzyDate(
                    year: endDate.year,
                    month: endDate.month,
                    day: endDate.day,
                  )
                : null,
          );
          return result != null;
      }
    } catch (e, st) {
      AppLogger.e(
        'Failed to update tracker entry for $tracker:$remoteId',
        e,
        st,
      );
      return false;
    }
  }

  Future<bool> removeTrackerEntry(TrackerType tracker, int remoteId) async {
    try {
      switch (tracker) {
        case TrackerType.anilist:
          if (_anilistService == null) return false;
          return await _anilistService.deleteUserAnimeList(remoteId);

        case TrackerType.mal:
          return true;
      }
    } catch (e, st) {
      AppLogger.e(
        'Failed to remove tracker entry for $tracker:$remoteId',
        e,
        st,
      );
      return false;
    }
  }

  // ─── Local Binding Operations ─────────────────────────────────

  /// Get existing binding for a media + tracker combination.
  Future<ExternalTrackBinding?> getBinding(
    int anilistMediaId,
    TrackerType tracker,
  ) async {
    return await isar.externalTrackBindings
        .filter()
        .anilistMediaIdEqualTo(anilistMediaId)
        .trackerTypeEqualTo(tracker)
        .findFirst();
  }

  /// Get all bindings for a given media.
  Future<List<ExternalTrackBinding>> getBindingsForMedia(
    int anilistMediaId,
  ) async {
    return await isar.externalTrackBindings
        .filter()
        .anilistMediaIdEqualTo(anilistMediaId)
        .findAll();
  }

  /// Save or update a tracker binding.
  Future<void> saveBinding(ExternalTrackBinding binding) async {
    await isar.writeTxn(() async {
      await isar.externalTrackBindings.put(binding);
    });
  }

  /// Delete a tracker binding.
  Future<void> deleteBinding(int anilistMediaId, TrackerType tracker) async {
    await isar.writeTxn(() async {
      await isar.externalTrackBindings
          .filter()
          .anilistMediaIdEqualTo(anilistMediaId)
          .trackerTypeEqualTo(tracker)
          .deleteAll();
    });
  }

  // ─── ID Resolution ────────────────────────────────────────────

  /// Resolve the remote ID for a given media and tracker type.
  /// Uses the optimization logic: if the ID is already available, skip search.
  int? resolveRemoteId(UniversalMedia media, TrackerType tracker) {
    switch (tracker) {
      case TrackerType.anilist:
        // UniversalMedia.id is the AniList ID
        return int.tryParse(media.id);
      case TrackerType.mal:
        // UniversalMedia.idMal is the MAL ID
        return media.idMal != null ? int.tryParse(media.idMal!) : null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _mapMalStatusToUniversal(String malStatus) {
    switch (malStatus.toLowerCase()) {
      case 'watching':
        return 'CURRENT';
      case 'completed':
        return 'COMPLETED';
      case 'on_hold':
        return 'PAUSED';
      case 'dropped':
        return 'DROPPED';
      case 'plan_to_watch':
        return 'PLANNING';
      default:
        return 'PLANNING';
    }
  }
}
