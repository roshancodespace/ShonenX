// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

enum EpisodeStreamState {
  SOURCE_LOADING,
  SUBTITLE_LOADING,
  SERVER_LOADING,
  QUALITY_LOADING,
}

@immutable
class EpisodeDataState {
  final Map<String, String>? headers;
  final List<Source> sources;
  final List<Subtitle> subtitles;
  final List<Map<String, dynamic>> qualityOptions;
  final List<ServerData> servers;

  final int? selectedQualityIdx;
  final int? selectedSourceIdx;
  final int? selectedEpisodeIdx;
  final int selectedSubtitleIdx;
  final ServerData? selectedServer;

  final List<EpisodeStreamState> states;
  final String? error;

  const EpisodeDataState({
    this.headers,
    this.sources = const [],
    this.subtitles = const [],
    this.qualityOptions = const [],
    this.servers = const [],
    this.selectedQualityIdx,
    this.selectedSourceIdx,
    this.selectedEpisodeIdx,
    this.selectedSubtitleIdx = 0,
    this.selectedServer,
    this.states = const [],
    this.error,
  });

  EpisodeDataState copyWith({
    Map<String, String>? headers,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    List<Map<String, dynamic>>? qualityOptions,
    List<ServerData>? servers,
    int? selectedQualityIdx,
    int? selectedSourceIdx,
    int? selectedEpisodeIdx,
    int? selectedSubtitleIdx,
    ServerData? selectedServer,
    List<EpisodeStreamState>? states,
    EpisodeStreamState? addState,
    EpisodeStreamState? removeState,
    String? error,
  }) {
    final updatedStates = <EpisodeStreamState>{
      ...states ?? this.states,
    };

    if (removeState != null) updatedStates.remove(removeState);
    if (addState != null) updatedStates.add(addState);

    return EpisodeDataState(
      headers: headers ?? this.headers,
      sources: sources ?? this.sources,
      subtitles: subtitles ?? this.subtitles,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      servers: servers ?? this.servers,
      selectedQualityIdx: selectedQualityIdx ?? this.selectedQualityIdx,
      selectedSourceIdx: selectedSourceIdx ?? this.selectedSourceIdx,
      selectedEpisodeIdx: selectedEpisodeIdx ?? this.selectedEpisodeIdx,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedServer: selectedServer ?? this.selectedServer,
      states: updatedStates.toList(),
      error: error,
    );
  }
}

class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  EpisodeListState get _episodeState => ref.read(episodeListProvider);
  List<EpisodeDataModel> get _episodes => _episodeState.episodes;

  ExperimentalFeaturesModel get _exp => ref.read(experimentalProvider);
  AnimeProvider? get _animeProvider => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeDataState build() => const EpisodeDataState();

  /* ───────────────────────── PUBLIC API ───────────────────────── */

  Future<void> loadEpisode({
    required int epIdx,
    bool play = true,
    Duration startAt = Duration.zero,
  }) async {
    if (!_validEpisode(epIdx)) return;
    await _setupServers(epIdx);
    if (play) {
      await changeEpisode(epIdx, startAt: startAt);
    }
  }

  Future<void> changeEpisode(int epIdx,
      {Duration startAt = Duration.zero}) async {
    if (!_validEpisode(epIdx)) return;
    state = state.copyWith(selectedEpisodeIdx: epIdx);
    await _fetchAndPlay(startAt);
  }

  Future<void> changeServer(ServerData server) async {
    state = state.copyWith(selectedServer: server);
    await _fetchAndPlay(ref.read(playerStateProvider).position);
  }

  Future<void> toggleDubSub() async {
    final current = state.selectedServer;
    if (current == null) return;

    final alt = state.servers.firstWhere(
      (s) => s.isDub != current.isDub,
      orElse: () => current,
    );

    if (alt == current) return;
    await changeServer(alt);
  }

  Future<void> changeSource(int idx) async {
    if (idx < 0 || idx >= state.sources.length) return;
    await _loadAndPlaySource(
      idx,
      startAt: ref.read(playerStateProvider).position,
    );
  }

  Future<void> changeQuality(int idx) async {
    if (idx < 0 || idx >= state.qualityOptions.length) return;
    final url = state.qualityOptions[idx]['url'] as String?;
    if (url == null) return;

    state = state.copyWith(selectedQualityIdx: idx);

    ref.read(playerStateProvider.notifier).open(
          url,
          ref.read(playerStateProvider).position,
          headers: state.headers,
        );
  }

  Future<void> changeSubtitle(int idx) async {
    state = state.copyWith(
        addState: EpisodeStreamState.SUBTITLE_LOADING, error: null);
    if (idx == 0) {
      await ref
          .read(playerStateProvider.notifier)
          .setSubtitle(SubtitleTrack.no());
      state = state.copyWith(selectedSubtitleIdx: 0);
      return;
    }

    if (idx < 0 || idx >= state.subtitles.length) return;
    final sub = state.subtitles[idx];
    if (sub.url == null) return;

    await ref
        .read(playerStateProvider.notifier)
        .setSubtitle(SubtitleTrack.uri(sub.url!));

    state = state.copyWith(
        selectedSubtitleIdx: idx,
        removeState: EpisodeStreamState.SUBTITLE_LOADING);
  }

  void reset() => state = const EpisodeDataState();

  /* ───────────────────────── INTERNAL LOGIC ───────────────────────── */

  bool _validEpisode(int idx) => idx >= 0 && idx < _episodes.length;

  Future<void> _setupServers(int epIdx) async {
    if (_exp.useMangayomiExtensions) return;

    state = state.copyWith(
        addState: EpisodeStreamState.SERVER_LOADING, error: null);

    final ep = _episodes[epIdx];
    final servers = await _animeProvider!.getSupportedServers(metadata: {
      'id': ep.id,
      'epNumber': ep.number,
      'epId': ep.id,
    });

    final flat = servers.flatten();
    state = state.copyWith(
      servers: flat,
      selectedServer: flat.firstOrNull,
      removeState: EpisodeStreamState.SERVER_LOADING,
    );
  }

  Future<void> _fetchAndPlay(Duration startAt) async {
    final epIdx = state.selectedEpisodeIdx;
    if (epIdx == null) return;

    state = state.copyWith(
        addState: EpisodeStreamState.SOURCE_LOADING, error: null);

    final data = await _getSources(epIdx);
    if (data == null || data.sources.isEmpty) {
      state = state.copyWith(
        addState: EpisodeStreamState.SOURCE_LOADING,
        error: 'No sources found',
      );
      return;
    }

    state = state.copyWith(
      sources: data.sources,
      subtitles: [Subtitle(lang: 'None'), ...data.tracks],
      headers: data.headers?.cast<String, String>(),
    );

    await _loadAndPlaySource(0, startAt: startAt);
    state = state.copyWith(removeState: EpisodeStreamState.SOURCE_LOADING);
  }

  Future<void> _loadAndPlaySource(
    int idx, {
    required Duration startAt,
  }) async {
    final source = state.sources[idx];
    final qualities = await _extractQualities(source);

    final pref = ref.read(playerSettingsProvider).defaultQuality;

    final qIdx = pref == 'Auto'
        ? 0
        : qualities.indexWhere(
            (q) => (q['quality'] as String).contains(pref),
          );

    final finalIdx = qIdx >= 0 ? qIdx : 0;
    final url = qualities[finalIdx]['url'] as String;

    ref.read(playerStateProvider.notifier).open(
          url,
          startAt,
          headers: state.headers,
        );

    final engIdx = state.subtitles.indexWhere(
      (s) => s.lang?.toLowerCase().contains('eng') ?? false,
    );

    changeSubtitle(engIdx);

    state = state.copyWith(
      qualityOptions: qualities,
      selectedSourceIdx: idx,
      selectedQualityIdx: finalIdx,
    );
  }

  Future<BaseSourcesModel?> _getSources(int epIdx) async {
    final ep = _episodes[epIdx];

    if (_exp.useMangayomiExtensions && ep.url != null) {
      final res = await _sourceNotifier.getSources(ep.url!);
      return BaseSourcesModel(
        sources: res
            .map((s) => Source(
                  url: s?.url,
                  isM3U8: s?.url.contains('.m3u8') ?? false,
                  quality: s?.quality,
                  isDub: s?.originalUrl.toLowerCase().contains('dub') ?? false,
                ))
            .toList(),
        tracks: res.firstOrNull?.subtitles
                ?.map((e) => Subtitle(
                      url: e.file,
                      lang: e.label,
                    ))
                .toList() ??
            [],
      );
    }

    return _animeProvider?.getSources(
      _episodeState.animeId ?? '',
      ep.id ?? '',
      state.selectedServer?.id,
      state.selectedServer?.isDub == true ? 'dub' : 'sub',
    );
  }

  Future<List<Map<String, dynamic>>> _extractQualities(Source source) async {
    final url = source.url;
    if (url == null) return [];

    state = state.copyWith(
      addState: EpisodeStreamState.QUALITY_LOADING,
      error: null,
    );

    try {
      if (!source.isM3U8) {
        return [
          {'quality': source.quality ?? 'Default', 'url': url}
        ];
      }

      final qualities = await extractor.extractQualities(
        url,
        state.headers ?? {},
      );

      return qualities;
    } catch (e, st) {
      state = state.copyWith(error: 'Quality extraction failed');
      AppLogger.e('Quality extraction failed', e, st);
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    } finally {
      state = state.copyWith(
        removeState: EpisodeStreamState.QUALITY_LOADING,
      );
    }
  }
}

final episodeDataProvider =
    AutoDisposeNotifierProvider<EpisodeDataNotifier, EpisodeDataState>(
        EpisodeDataNotifier.new);
