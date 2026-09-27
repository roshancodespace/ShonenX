import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
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
  SourceType? sourceType,
  MediaType type,
});

class EpisodesListNotifier extends AsyncNotifier<EpisodesListState> {
  final MediaArgs arg;

  EpisodesListNotifier(this.arg);

  @override
  Future<EpisodesListState> build() async {
    final log = AppLogger.scope('EpisodesListProvider').child('fetch');
    final title = arg.mediaTitle;

    final contentPrefs = ref.watch(contentPrefsProvider);
    final metadataService = ref.watch(episodeMetadataServiceProvider);

    try {
      final matchState = await ref.watch(matchedMediaProvider(arg).future);

      if (matchState.matchedMedia == null) {
        return EpisodesListState(
          source: matchState.sourceInfo,
          episodes: const [],
        );
      }

      final sourceEpisodesState = await ref.watch(
        sourceEpisodesProvider((
          providerId: matchState.matchedMedia!.id,
          sourceId: matchState.sourceInfo.id,
          sourceType: matchState.sourceInfo.type,
          type: arg.type,
        )).future,
      );

      if (!arg.type.usesAnimeSources || sourceEpisodesState.episodes.isEmpty) {
        return sourceEpisodesState;
      }

      try {
        final enrichedEpisodes = await metadataService.enrichEpisodes(
          media: arg.toMedia(),
          sourceEpisodes: sourceEpisodesState.episodes,
          mode: contentPrefs.episodeMetadataProvider,
          titlePreference: contentPrefs.titlePreference,
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
  }

  Future<void> refreshEpisodes() async {
    final matchState = await ref.read(matchedMediaProvider(arg).future);
    if (matchState.matchedMedia != null) {
      ref
          .read(
            sourceEpisodesProvider((
              providerId: matchState.matchedMedia!.id,
              sourceId: matchState.sourceInfo.id,
              sourceType: matchState.sourceInfo.type,
              type: arg.type,
            )).notifier,
          )
          .forceRefreshFetch();
    }
  }
}

final episodesListProvider = AsyncNotifierProvider.family
    .autoDispose<EpisodesListNotifier, EpisodesListState, MediaArgs>(
      EpisodesListNotifier.new,
    );

class SourceEpisodesNotifier extends AsyncNotifier<EpisodesListState> {
  final SourceEpisodeArgs arg;
  SourceEpisodesNotifier(this.arg);

  bool _forceRefresh = false;

  @override
  Future<EpisodesListState> build() async {
    final log = AppLogger.scope('SourceEpisodesProvider').child('fetch');
    final force = _forceRefresh;
    _forceRefresh = false;

    ref.watch(sourceSettingsProvider(arg.sourceId));

    try {
      final allSources = await ref.watch(
        arg.type.availableSourcesProvider.future,
      );

      final sourceInfo = allSources
          .where(
            (s) =>
                s.id == arg.sourceId &&
                (arg.sourceType == null || s.type == arg.sourceType),
          )
          .firstOrNull;

      if (sourceInfo == null) {
        throw Exception('Source "${arg.sourceId}" not found');
      }

      List<UnifiedEpisode> episodes = [];

      if (arg.type.usesAnimeSources) {
        final animeSource = ref.watch(animeSourceProvider(sourceInfo));
        log.i('Fetching episodes directly from ${sourceInfo.name}');
        episodes = await animeSource.getEpisodes(
          arg.providerId,
          forceRefresh: force,
        );
      } else {
        final mangaSource = ref.watch(mangaSourceProvider(sourceInfo));
        log.i('Fetching chapters directly from ${sourceInfo.name}');
        final chapters = await mangaSource.getChapters(
          arg.providerId,
          forceRefresh: force,
        );
        episodes = chapters.map((c) => UnifiedEpisode.fromChapter(c)).toList();
      }

      episodes.sort((a, b) => a.number.compareTo(b.number));

      log.s(
        'Fetched ${episodes.length} episodes/chapters from ${sourceInfo.name}',
      );

      return EpisodesListState(source: sourceInfo, episodes: episodes);
    } catch (e, st) {
      log.e('Failed to fetch episodes for source ${arg.sourceId}', [e, st]);
      rethrow;
    }
  }

  void forceRefreshFetch() {
    _forceRefresh = true;
    ref.invalidateSelf();
  }
}

final sourceEpisodesProvider = AsyncNotifierProvider.family
    .autoDispose<SourceEpisodesNotifier, EpisodesListState, SourceEpisodeArgs>(
      SourceEpisodesNotifier.new,
    );
