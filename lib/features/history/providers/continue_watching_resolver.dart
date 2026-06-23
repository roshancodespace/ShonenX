import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

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

    final sourceInfo = prefState.sourceInfo;

    UnifiedEpisode? episode;

    if (prefState.manualOverrideId != null) {
      final args = (
        providerId: prefState.manualOverrideId!,
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
