// ignore_for_file: constant_identifier_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view/widgets/download_source_selector.dart';
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

  final Set<EpisodeStreamState> states;
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
    this.states = const {},
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
    EpisodeStreamState? addState,
    EpisodeStreamState? removeState,
    String? error,
  }) {
    final newStates = Set<EpisodeStreamState>.from(states);
    if (removeState != null) newStates.remove(removeState);
    if (addState != null) newStates.add(addState);

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
      states: newStates,
      error: error,
    );
  }
}

class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  EpisodeListState get _epState => ref.read(episodeListProvider);
  List<EpisodeDataModel> get _episodes => _epState.episodes;
  ExperimentalFeaturesModel get _exp => ref.read(experimentalProvider);
  AnimeProvider? get _animeProvider => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeDataState build() => const EpisodeDataState();

  Future<void> loadEpisode({
    required int epIdx,
    bool play = true,
    Duration startAt = Duration.zero,
  }) async {
    if (!_isValidEp(epIdx)) return;

    await _fetchServers(epIdx);

    if (play) {
      await changeEpisode(epIdx, startAt: startAt);
    }
  }

  Future<void> changeEpisode(int epIdx,
      {Duration startAt = Duration.zero}) async {
    if (!_isValidEp(epIdx)) return;

    state = state.copyWith(selectedEpisodeIdx: epIdx);
    await _playCurrentEpisode(startAt);
  }

  Future<void> changeServer(ServerData server) async {
    state = state.copyWith(selectedServer: server);
    await _playCurrentEpisode(ref.read(playerStateProvider).position);
  }

  Future<void> toggleDubSub() async {
    final current = state.selectedServer;
    if (current == null) return;

    final alt = state.servers.firstWhere(
      (s) => s.isDub != current.isDub,
      orElse: () => current,
    );

    if (alt != current) await changeServer(alt);
  }

  Future<void> changeSource(int idx) async {
    if (idx < 0 || idx >= state.sources.length) return;

    await _loadSourceStream(
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
      state = state.copyWith(
          selectedSubtitleIdx: 0,
          removeState: EpisodeStreamState.SUBTITLE_LOADING);
      return;
    }

    if (idx < 0 || idx >= state.subtitles.length) return;

    final sub = state.subtitles[idx];
    if (sub.url != null) {
      await ref
          .read(playerStateProvider.notifier)
          .setSubtitle(SubtitleTrack.uri(sub.url!));
    }

    state = state.copyWith(
      selectedSubtitleIdx: idx,
      removeState: EpisodeStreamState.SUBTITLE_LOADING,
    );
  }

  Future<void> downloadEpisode(BuildContext context, int epNumber) async {
    final epIdx = epNumber - 1;
    if (!_isValidEp(epIdx)) return;

    final ep = _episodes[epIdx];
    final animeId = _epState.animeId;

    if (animeId == null) return;

    ServerData? selectedServer;

    if (!_exp.useMangayomiExtensions && ep.url == null) {
      _showLoading(context);

      try {
        final result = await _animeProvider?.getSupportedServers(metadata: {
          'id': ep.id,
          'epNumber': ep.number,
          'epId': ep.id,
        });

        Navigator.pop(context);

        final servers = result?.flatten() ?? [];

        if (servers.length == 1) {
          selectedServer = servers.first;
        } else if (servers.length > 1) {
          selectedServer = await _showServerSelectionSheet(context, servers);
          if (selectedServer == null) return;
        }
      } catch (e) {
        Navigator.pop(context);
        _showSnack(context, "Failed to load servers: $e");
        return;
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (c, controller) => DownloadSourceSelector(
          animeTitle: _epState.animeTitle ?? 'Unknown',
          episode: ep,
          server: selectedServer,
          fetchSources: () => _fetchSourceData(ep, server: selectedServer),
          scrollController: controller,
        ),
      ),
    );
  }

  void reset() => state = const EpisodeDataState();

  // -- Internals --

  bool _isValidEp(int idx) => idx >= 0 && idx < _episodes.length;

  Future<void> _fetchServers(int epIdx) async {
    if (_exp.useMangayomiExtensions) return;

    state = state.copyWith(
        addState: EpisodeStreamState.SERVER_LOADING, error: null);

    try {
      final ep = _episodes[epIdx];
      final res = await _animeProvider?.getSupportedServers(metadata: {
        'id': ep.id,
        'epNumber': ep.number,
        'epId': ep.id,
      });

      final flat = res?.flatten() ?? [];
      state = state.copyWith(
        servers: flat,
        selectedServer: flat.firstOrNull,
      );
    } catch (e) {
      AppLogger.e("Server fetch failed", e);
    } finally {
      state = state.copyWith(removeState: EpisodeStreamState.SERVER_LOADING);
    }
  }

  Future<void> _playCurrentEpisode(Duration startAt) async {
    final epIdx = state.selectedEpisodeIdx;
    if (epIdx == null) return;

    state = state.copyWith(
        addState: EpisodeStreamState.SOURCE_LOADING, error: null);

    final data =
        await _fetchSourceData(_episodes[epIdx], server: state.selectedServer);

    if (data == null || data.sources.isEmpty) {
      state = state.copyWith(
        removeState: EpisodeStreamState.SOURCE_LOADING,
        error: 'No sources found',
      );
      return;
    }

    state = state.copyWith(
      sources: data.sources,
      subtitles: [Subtitle(lang: 'None'), ...data.tracks],
      headers: data.headers?.cast<String, String>(),
    );

    // Auto-play first source
    await _loadSourceStream(0, startAt: startAt);

    state = state.copyWith(removeState: EpisodeStreamState.SOURCE_LOADING);
  }

  /// Extracts qualities for the specific source and initializes player
  Future<void> _loadSourceStream(int sourceIdx,
      {required Duration startAt}) async {
    final source = state.sources[sourceIdx];

    // Optimistic UI update
    state = state.copyWith(addState: EpisodeStreamState.QUALITY_LOADING);

    final qualities = await _getQualitiesForSource(source, state.headers);

    // Preference Matching
    final pref = ref.read(playerSettingsProvider).defaultQuality;
    int qIdx = 0; // Default to first (usually auto/best)

    if (pref != 'Auto') {
      final match =
          qualities.indexWhere((q) => (q['quality'] as String).contains(pref));
      if (match != -1) qIdx = match;
    }

    final url = qualities[qIdx]['url'] as String;

    ref.read(playerStateProvider.notifier).open(
          url,
          startAt,
          headers: state.headers,
        );

    // Auto-select English subtitles if available
    final engSubIdx = state.subtitles.indexWhere(
      (s) => s.lang?.toLowerCase().contains('eng') ?? false,
    );
    if (engSubIdx != -1) changeSubtitle(engSubIdx);

    state = state.copyWith(
      qualityOptions: qualities,
      selectedSourceIdx: sourceIdx,
      selectedQualityIdx: qIdx,
      removeState: EpisodeStreamState.QUALITY_LOADING,
    );
  }

  /// Unified fetch logic for both Player and Downloader
  Future<BaseSourcesModel?> _fetchSourceData(EpisodeDataModel ep,
      {ServerData? server}) async {
    // 1. Mangayomi / Extension route
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

    // 2. Standard Provider route
    return _animeProvider?.getSources(
      _epState.animeId ?? '',
      ep.id ?? '',
      server?.id,
      server?.isDub == true ? 'dub' : 'sub',
    );
  }

  Future<List<Map<String, dynamic>>> _getQualitiesForSource(
      Source source, Map<String, String>? headers) async {
    final url = source.url;
    if (url == null) return [];

    if (!source.isM3U8) {
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    }

    try {
      return await extractor.extractQualities(url, headers ?? {});
    } catch (e) {
      AppLogger.e('Quality extraction failed', e);
      // Fallback to original URL if extraction fails
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    }
  }

  // -- UI Helpers --

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<ServerData?> _showServerSelectionSheet(
      BuildContext context, List<ServerData> servers) {
    return showModalBottomSheet<ServerData>(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Server",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: servers
                  .map((s) => ActionChip(
                        label: Text(
                            '${s.name ?? 'Unknown'} [ ${s.isDub ? 'DUB' : 'SUB'} ]'),
                        onPressed: () => Navigator.pop(context, s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

final episodeDataProvider =
    AutoDisposeNotifierProvider<EpisodeDataNotifier, EpisodeDataState>(
        EpisodeDataNotifier.new);
