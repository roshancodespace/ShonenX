import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final continueWatchingResolverProvider = Provider(
  (ref) => ContinueWatchingResolver(ref),
);

class ContinueWatchingResolver {
  final Ref ref;

  const ContinueWatchingResolver(this.ref);

  Future<PlayerModeOnline> resolve(WatchHistoryEntry entry) async {
    // 1. Fetch preferences (incase user manually remapped via Fix Source)
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MediaArgs.fromTitle(entry.animeTitle, type: MediaType.ANIME),
      ).future,
    );

    // 2. Determine Source and Provider ID.
    // Priority: Explicit User Preference > History Entry > Default Source
    SourceInfo? sourceInfo;
    String? providerId;

    if (prefState.hasExplicitSource && prefState.matchedMediaId != null) {
      sourceInfo = prefState.sourceInfo;
      providerId = prefState.matchedMediaId!;
    } else if (entry.sourceId != null && entry.providerId != null) {
      final availableSourcesInfo = await ref.read(
        availableAnimeSourcesProvider.future,
      );
      sourceInfo =
          availableSourcesInfo.firstWhereOrNull(
            (s) => s.id == entry.sourceId && s.name == entry.sourceName,
          ) ??
          availableSourcesInfo.firstWhereOrNull((s) => s.id == entry.sourceId);
      providerId = entry.providerId!;
    }

    // If we STILL don't have a source/providerId (e.g. extremely old history), do a fresh resolution
    if (sourceInfo == null || providerId == null) {
      final matchState = await ref.read(
        matchedMediaProvider(
          MediaArgs.fromTitle(entry.animeTitle, type: MediaType.ANIME),
        ).future,
      );
      if (matchState.matchedMedia == null) {
        throw Exception('Could not resolve media source.');
      }
      sourceInfo = matchState.sourceInfo;
      providerId = matchState.matchedMedia!.id;
    }

    // 3. Fetch episodes directly using the resolved source and provider ID
    final episodesState = await ref.read(
      sourceEpisodesProvider((
        providerId: providerId,
        sourceId: sourceInfo.id,
        sourceType: sourceInfo.type,
        type: MediaType.ANIME,
      )).future,
    );

    // 4. Find the target episode
    UnifiedEpisode? targetEpisode = episodesState.episodes.firstWhereOrNull(
      (e) => e.number == entry.episodeNumber,
    );

    // 5. Determine progress (advance to next if fully watched)
    final threshold = ref.read(trackingPrefsProvider).syncThreshold;
    final isWatched =
        entry.durationInMilliseconds > 0 &&
        entry.positionInMilliseconds >=
            entry.durationInMilliseconds * threshold;
    Duration? startPosition = Duration(
      milliseconds: entry.positionInMilliseconds,
    );

    if (isWatched && targetEpisode != null) {
      final currentIndex = episodesState.episodes.indexOf(targetEpisode);
      if (currentIndex != -1 &&
          currentIndex + 1 < episodesState.episodes.length) {
        targetEpisode = episodesState.episodes[currentIndex + 1];
      }
      startPosition =
          null; // Always reset position if we watched it (either advancing or staying on same ep)
    }

    if (targetEpisode == null) {
      throw Exception('Episode not found in the selected source.');
    }

    // 6. Return PlayerMode
    return PlayerModeOnline(
      media: UnifiedMedia(
        id: entry.animeId,
        idMal: entry.animeIdMal,
        providerId: providerId,
        externalIds: entry.externalIds,
        cover: entry.cover,
        banner: entry.banner,
        episodes: entry.totalEpisodes,
        type: MediaType.ANIME,
        title: MediaTitle(english: entry.animeTitle),
      ),
      episode: targetEpisode,
      sourceInfo: sourceInfo,
      startPosition: startPosition,
    );
  }
}
