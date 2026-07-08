import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final continueWatchingResolverProvider = Provider(
  (ref) => ContinueWatchingResolver(ref),
);

class ContinueWatchingResult {
  final PlayerModeOnline mode;

  const ContinueWatchingResult({required this.mode});
}

class ContinueWatchingResolver {
  final Ref ref;

  const ContinueWatchingResolver(this.ref);

  Future<ContinueWatchingResult> resolve(WatchHistoryEntry entry) async {
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MatchArgs(mediaTitle: entry.animeTitle, type: MediaType.ANIME),
      ).future,
    );

    final availableSourcesInfo = await ref.read(
      availableAnimeSourcesProvider.future,
    );

    final sourceInfo =
        (entry.sourceId != null
            ? availableSourcesInfo.firstWhereOrNull(
                (s) => s.id == entry.sourceId,
              )
            : null) ??
        prefState.sourceInfo;

    final rawOverride = prefState.manualOverrideId ?? entry.providerId;
    final overrideId = (rawOverride != null && rawOverride != entry.animeId)
        ? rawOverride
        : null;

    UnifiedEpisode? episode;

    if (overrideId != null) {
      final args = (
        providerId: overrideId,
        sourceId: sourceInfo.id,
        type: MediaType.ANIME,
      );

      final episodesState = await ref.read(sourceEpisodesProvider(args).future);

      episode = episodesState.episodes.firstWhereOrNull(
        (e) => e.number == entry.episodeNumber,
      );
    } else {
      final episodesState = await ref.read(
        episodesListProvider(
          MatchArgs(mediaTitle: entry.animeTitle, type: MediaType.ANIME),
        ).future,
      );

      episode = episodesState.episodes.firstWhereOrNull(
        (e) => e.number == entry.episodeNumber,
      );
    }

    if (episode == null) {
      throw Exception('Episode not found.');
    }

    return ContinueWatchingResult(
      mode: PlayerModeOnline(
        media: UnifiedMedia(
          id: entry.animeId,
          idMal: entry.animeIdMal,
          cover: entry.cover,
          sourceId: null,
          sourceName: null,
          providerId: overrideId,
          type: MediaType.ANIME,
          title: MediaTitle(english: entry.animeTitle),
        ),
        episode: episode,
        sourceInfo: sourceInfo,
        startPosition: Duration(milliseconds: entry.positionInMilliseconds),
      ),
    );
  }
}
