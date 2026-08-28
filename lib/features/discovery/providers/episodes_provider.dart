import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/episode_metadata/providers/episode_metadata_providers.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/source_settings_provider.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class EpisodesListState {
  final SourceInfo source;
  final List<UnifiedEpisode> episodes;

  EpisodesListState({required this.source, required this.episodes});
}

typedef SourceEpisodeArgs = ({
  String providerId,
  String sourceId,
  MediaType type,
});

final episodesListProvider =
    FutureProvider.family<EpisodesListState, MediaArgs>((ref, args) async {
      final log = AppLogger.scope('EpisodesListProvider').child('fetch');
      final title = args.mediaTitle;

      // Watch synchronous providers before any async gap
      final contentPrefs = ref.watch(contentPrefsProvider);
      final metadataService = ref.watch(episodeMetadataServiceProvider);

      try {
        final sourcePrefs = await ref.watch(
          mediaPreferenceProvider(args).future,
        );
        final matchState = await ref.watch(matchedMediaProvider(args).future);

        if (matchState.matchedMedia == null) {
          return EpisodesListState(
            source: sourcePrefs.sourceInfo,
            episodes: const [],
          );
        }

        final sourceEpisodesState = await ref.watch(
          sourceEpisodesProvider((
            providerId: matchState.matchedMedia!.id,
            sourceId: sourcePrefs.sourceInfo.id,
            type: args.type,
          )).future,
        );

        if (!args.type.usesAnimeSources ||
            sourceEpisodesState.episodes.isEmpty) {
          return sourceEpisodesState;
        }

        try {
          final enrichedEpisodes = await metadataService.enrichEpisodes(
            media: args.toMedia(),
            sourceEpisodes: sourceEpisodesState.episodes,
            mode: contentPrefs.episodeMetadataProvider,
          );

          return EpisodesListState(
            source: sourceEpisodesState.source,
            episodes: enrichedEpisodes,
          );
        } catch (enrichErr, enrichSt) {
          log.w('Episode enrichment failed, keeping raw source episodes', [
            enrichErr,
            enrichSt,
          ]);
          return sourceEpisodesState;
        }
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

      ref.watch(sourceSettingsProvider(args.sourceId));

      try {
        final allSources = await ref.watch(
          args.type.availableSourcesProvider.future,
        );

        final sourceInfo = allSources
            .where((s) => s.id == args.sourceId)
            .firstOrNull;

        if (sourceInfo == null) {
          throw Exception('Source "${args.sourceId}" not found');
        }

        List<UnifiedEpisode> episodes = [];

        if (args.type.usesAnimeSources) {
          final animeSource = ref.watch(animeSourceProvider(sourceInfo));
          log.i('Fetching episodes directly from ${sourceInfo.name}');
          episodes = await animeSource.getEpisodes(args.providerId);
        } else {
          final mangaSource = ref.watch(mangaSourceProvider(sourceInfo));
          log.i('Fetching chapters directly from ${sourceInfo.name}');
          final chapters = await mangaSource.getChapters(args.providerId);
          episodes = chapters
              .map((c) => UnifiedEpisode.fromChapter(c))
              .toList();
        }

        episodes.sort((a, b) => a.number.compareTo(b.number));

        log.s(
          'Fetched ${episodes.length} episodes/chapters from ${sourceInfo.name}',
        );

        return EpisodesListState(source: sourceInfo, episodes: episodes);
      } catch (e, st) {
        log.e('Failed to fetch episodes for source ${args.sourceId}', [e, st]);
        rethrow;
      }
    });
