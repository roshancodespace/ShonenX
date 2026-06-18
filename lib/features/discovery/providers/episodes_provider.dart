import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class EpisodesListState {
  final SourceInfo source;
  final List<UnifiedEpisode> episodes;

  EpisodesListState({required this.source, required this.episodes});
}

typedef SourceEpisodeArgs = ({String providerId, String sourceId});

final episodesListProvider = FutureProvider.family<EpisodesListState, String>((
  ref,
  title,
) async {
  final log = AppLogger.scope('EpisodesListProvider').child('fetch');

  try {
    final matchState = await ref.watch(matchedMediaProvider(title).future);

    final sourcePrefs = await ref.watch(sourcePreferenceProvider(title).future);

    final animeSource = ref.watch(animeSourceProvider(sourcePrefs.sourceInfo));

    log.i('Fetching episodes for "$title"');

    if (matchState.matchedMedia == null) {
      return EpisodesListState(
        source: animeSource.sourceInfo,
        episodes: const [],
      );
    }

    final episodes = await animeSource.getEpisodes(matchState.matchedMedia!.id);

    episodes.sort((a, b) => a.number.compareTo(b.number));

    log.s('Fetched ${episodes.length} episodes');

    return EpisodesListState(
      source: animeSource.sourceInfo,
      episodes: episodes,
    );
  } catch (e, st) {
    log.e('Failed to fetch episodes for "$title"', [e, st]);

    rethrow;
  }
});

final sourceEpisodesProvider =
    FutureProvider.family<EpisodesListState, SourceEpisodeArgs>((
      ref,
      args,
    ) async {
      final log = AppLogger.scope('SourceEpisodesProvider').child('fetch');

      try {
        final allSources = await ref.watch(
          availableAnimeSourcesProvider.future,
        );

        final sourceInfo = allSources
            .where((s) => s.id == args.sourceId)
            .firstOrNull;

        if (sourceInfo == null) {
          throw Exception('Source "${args.sourceId}" not found');
        }

        final animeSource = ref.watch(animeSourceProvider(sourceInfo));

        log.i('Fetching episodes directly from ${sourceInfo.name}');

        final episodes = await animeSource.getEpisodes(args.providerId);

        episodes.sort((a, b) => a.number.compareTo(b.number));

        log.s('Fetched ${episodes.length} episodes from ${sourceInfo.name}');

        return EpisodesListState(
          source: animeSource.sourceInfo,
          episodes: episodes,
        );
      } catch (e, st) {
        log.e('Failed to fetch episodes for source ${args.sourceId}', [e, st]);

        rethrow;
      }
    });
