import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final continueWatchingResolverProvider = Provider(
  (ref) => ContinueWatchingResolver(ref),
);

class ContinueWatchingResolver {
  final Ref ref;

  const ContinueWatchingResolver(this.ref);

  Future<PlayerModeOnline> resolve(WatchHistoryEntry entry) async {
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MediaArgs(mediaTitle: entry.animeTitle, type: MediaType.ANIME),
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

    final rawOverride = prefState.matchedMediaId ?? entry.providerId;
    final overrideId = (rawOverride != null && rawOverride != entry.animeId)
        ? rawOverride
        : null;

    final episodesFuture = overrideId != null
        ? ref.read(
            sourceEpisodesProvider((
              providerId: overrideId,
              sourceId: sourceInfo.id,
              type: MediaType.ANIME,
            )).future,
          )
        : ref.read(
            episodesListProvider(
              MediaArgs(mediaTitle: entry.animeTitle, type: MediaType.ANIME),
            ).future,
          );

    final episodesState = await episodesFuture;
    final episode = episodesState.episodes.firstWhereOrNull(
      (e) => e.number == entry.episodeNumber,
    );

    if (episode == null) {
      throw Exception('Episode not found.');
    }

    return PlayerModeOnline(
      media: UnifiedMedia(
        id: entry.animeId,
        idMal: entry.animeIdMal,
        externalIds: entry.externalIds,
        cover: entry.cover,
        banner: entry.banner,
        sourceId: entry.sourceId,
        sourceName: entry.sourceName,
        providerId: overrideId ?? entry.providerId,
        episodes: entry.totalEpisodes,
        type: MediaType.ANIME,
        title: MediaTitle(english: entry.animeTitle),
      ),
      episode: episode,
      sourceInfo: sourceInfo,
      startPosition: Duration(milliseconds: entry.positionInMilliseconds),
    );
  }
}
