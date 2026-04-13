// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    hide Source;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view/widgets/download_source_selector.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/core/models/settings/experimental_model.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/shared/providers/settings/source_notifier.dart';
import 'package:shonenx/core/utils/extractors.dart' as extractor;

part 'episode_stream_provider.g.dart';

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
  final int? selectedEpisode;
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
    this.selectedEpisode,
    this.selectedSubtitleIdx = 0,
    this.selectedServer,
    this.states = const {},
    this.error,
  });

  bool get isLoading => states.isNotEmpty;

  EpisodeDataState copyWith({
    Map<String, String>? headers,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    List<Map<String, dynamic>>? qualityOptions,
    List<ServerData>? servers,
    int? selectedQualityIdx,
    int? selectedSourceIdx,
    int? selectedEpisode,
    int? selectedSubtitleIdx,
    ServerData? selectedServer,
    EpisodeStreamState? addState,
    EpisodeStreamState? removeState,
    String? error,
    bool clearError = false,
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
      selectedEpisode: selectedEpisode ?? this.selectedEpisode,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedServer: selectedServer ?? this.selectedServer,
      states: newStates,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class EpisodeData extends _$EpisodeData {
  EpisodeListState get _epList => ref.read(episodeListProvider);
  ExperimentalFeaturesModel get _exp => ref.read(experimentalProvider);
  AnimeProvider? get _provider => ref.read(selectedAnimeProvider);
  SourceNotifier get _srcNotifier => ref.read(sourceProvider.notifier);
  PlayerStateNotifier get _player => ref.read(playerStateProvider.notifier);

  @override
  EpisodeDataState build() => const EpisodeDataState();

  Future<void> loadEpisode({
    required int ep,
    bool play = true,
    Duration? startAt,
  }) async {
    if (!_isValidEp(ep)) {
      AppLogger.fail('Invalid episode requested: $ep');
      return;
    }

    AppLogger.section('Loading Episode $ep');
    state = state.copyWith(selectedEpisode: ep, clearError: true);
    await _fetchServers(ep);

    if (play) {
      Duration resumeAt = startAt ?? Duration.zero;
      if (startAt == null) {
        try {
          final repo = ref.read(watchProgressRepositoryProvider);
          final mediaId = _epList.animeId;
          if (mediaId != null) {
            final progress = repo.getEpisodeProgress(mediaId, ep);
            if (progress != null && (progress.durationInSeconds ?? 0) > 0) {
              resumeAt = Duration(seconds: progress.progressInSeconds ?? 0);
            }
          }
        } catch (_) {}
      }
      await _playCurrent(resumeAt);
    }
  }

  Future<void> changeEpisode(int? ep, {Duration? startAt, int by = 0}) async {
    final target = by != 0 ? (state.selectedEpisode ?? 1) + by : ep;
    if (target == null || !_isValidEp(target)) return;

    AppLogger.i('Changing to episode: $target');
    await loadEpisode(ep: target, play: true, startAt: startAt);
  }

  Future<void> changeServer(ServerData server) async {
    AppLogger.infoPair('Changing Server', server.name ?? server.id);
    state = state.copyWith(selectedServer: server);
    await _playCurrent(ref.read(playerStateProvider).position);
  }

  Future<void> toggleDubSub() async {
    final current = state.selectedServer;
    if (current == null) return;

    final alt = state.servers.firstWhereOrNull((s) => s.isDub != current.isDub);
    if (alt != null) {
      AppLogger.i('Toggling Dub/Sub to: ${alt.isDub ? "DUB" : "SUB"}');
      await changeServer(alt);
    } else {
      AppLogger.warning('No alternative Dub/Sub server found');
    }
  }

  Future<void> changeSource(int idx) async {
    if (idx < 0 || idx >= state.sources.length) return;
    AppLogger.infoPair('Changing Source Index', idx);
    await _loadSourceStream(
      idx,
      startAt: ref.read(playerStateProvider).position,
    );
  }

  Future<void> changeQuality(int idx) async {
    if (idx < 0 || idx >= state.qualityOptions.length) return;

    final url = state.qualityOptions[idx]['url'] as String?;
    if (url == null) return;

    AppLogger.infoPair(
      'Changing Quality',
      state.qualityOptions[idx]['quality'],
    );
    state = state.copyWith(selectedQualityIdx: idx);
    _player.open(
      url,
      ref.read(playerStateProvider).position,
      headers: state.headers,
    );
  }

  Future<void> changeSubtitle(int idx) async {
    state = state.copyWith(
      addState: EpisodeStreamState.SUBTITLE_LOADING,
      clearError: true,
    );

    if (idx <= 0 || idx >= state.subtitles.length) {
      AppLogger.d('Disabling Subtitles');
      await _player.setSubtitle(SubtitleTrack.no());
      state = state.copyWith(
        selectedSubtitleIdx: 0,
        removeState: EpisodeStreamState.SUBTITLE_LOADING,
      );
      return;
    }

    final sub = state.subtitles[idx];
    AppLogger.infoPair('Applying Subtitle', sub.lang);

    if (sub.url != null) await _player.setSubtitle(SubtitleTrack.uri(sub.url!));

    state = state.copyWith(
      selectedSubtitleIdx: idx,
      removeState: EpisodeStreamState.SUBTITLE_LOADING,
    );
  }

  Future<void> addLocalSubtitle(File file) async {
    AppLogger.i('Adding local subtitle: ${file.path}');
    final sub = Subtitle(
      url: 'file://${file.path}',
      lang: 'Local: ${file.path.split('/').last}',
    );

    state = state.copyWith(subtitles: [...state.subtitles, sub]);
    await changeSubtitle(state.subtitles.length - 1);
  }

  Future<void> downloadEpisode(BuildContext context, int epNum) async {
    if (!_isValidEp(epNum) || _epList.animeId == null) return;

    final ep = _epList.episodes.firstWhereOrNull((i) => i.number == epNum);
    if (ep == null) return;

    final link = ref.keepAlive();
    AppLogger.section('Initializing Download for Ep $epNum');

    try {
      _showLoading(context);
      final servers = await _getRawServers(ep);
      if (!context.mounted) return;
      Navigator.pop(context);

      ServerData? selected;
      if (_exp.useExtensions) {
        selected = ServerData(name: 'Extension', id: 'ext', isDub: false);
      } else {
        if (servers.isEmpty) {
          AppLogger.warning('No servers available for download');
          return _showSnack(context, "No servers found");
        }
        selected = servers.length == 1
            ? servers.first
            : await _showServerSheet(context, servers);
      }

      if (selected == null || !context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (c) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (c, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: DownloadSourceSelector(
              animeTitle: _epList.animeTitle ?? 'Unknown',
              episode: ep,
              server: selected,
              fetchSources: () => _fetchSourceData(ep, server: selected),
              scrollController: controller,
            ),
          ),
        ),
      );
    } finally {
      link.close();
    }
  }

  void reset() => state = const EpisodeDataState();

  bool _isValidEp(int ep) => _epList.episodes.any((i) => i.number == ep);

  Future<List<ServerData>> _getRawServers(EpisodeDataModel ep) async {
    if (_exp.useExtensions) {
      return (await _srcNotifier.getServers(
        _epList.animeId!,
        (ep.id ?? ep.number)!.toString(),
        ep.number.toString(),
      )).cast<ServerData>();
    }

    return (await _provider?.getSupportedServers(
          metadata: {
            'id': _epList.animeId,
            'epNumber': ep.number,
            'epId': ep.id,
          },
        ))?.flatten() ??
        [];
  }

  Future<void> _fetchServers(int epNum) async {
    state = state.copyWith(
      addState: EpisodeStreamState.SERVER_LOADING,
      clearError: true,
    );

    try {
      final ep = _epList.episodes.firstWhereOrNull((e) => e.number == epNum);
      if (ep == null) return;

      final list = await _getRawServers(ep);
      final preferDub = ref.read(playerSettingsProvider).preferDub;
      final selected =
          list.firstWhereOrNull((s) => s.isDub == preferDub) ??
          list.firstOrNull;

      state = state.copyWith(servers: list, selectedServer: selected);
      AppLogger.success(
        'Fetched ${list.length} servers (Default: ${selected?.name})',
      );
    } catch (e, stack) {
      AppLogger.e("Server fetch failed", e, stack);
    } finally {
      state = state.copyWith(removeState: EpisodeStreamState.SERVER_LOADING);
    }
  }

  Future<void> _playCurrent(Duration startAt) async {
    final epNum = state.selectedEpisode;
    if (epNum == null) return;

    state = state.copyWith(
      addState: EpisodeStreamState.SOURCE_LOADING,
      clearError: true,
    );

    final epModel = _epList.getEpisode(epNum);
    if (epModel == null) return;

    final data = await _fetchSourceData(epModel, server: state.selectedServer);

    if (data == null || data.sources.isEmpty) {
      AppLogger.fail('No extractable sources found');
      state = state.copyWith(
        removeState: EpisodeStreamState.SOURCE_LOADING,
        error: 'No sources found',
      );
      return;
    }

    state = state.copyWith(
      sources: data.sources,
      subtitles: [
        Subtitle(lang: 'None'),
        ...data.tracks,
      ],
      headers: data.headers?.cast<String, String>(),
    );

    AppLogger.success(
      'Extracted ${data.sources.length} sources and ${data.tracks.length} subtitles',
    );
    await _loadSourceStream(0, startAt: startAt);

    state = state.copyWith(removeState: EpisodeStreamState.SOURCE_LOADING);
  }

  Future<void> _loadSourceStream(
    int sourceIdx, {
    required Duration startAt,
  }) async {
    if (sourceIdx < 0 || sourceIdx >= state.sources.length) return;

    final src = state.sources[sourceIdx];
    state = state.copyWith(addState: EpisodeStreamState.QUALITY_LOADING);

    final qualities = await _getQualities(src, state.headers);
    if (qualities.isEmpty) {
      state = state.copyWith(removeState: EpisodeStreamState.QUALITY_LOADING);
      return;
    }

    final prefQuality = ref.read(playerSettingsProvider).defaultQuality;
    int qIdx = qualities.indexWhere(
      (q) => (q['quality'] as String).contains(prefQuality),
    );
    if (qIdx == -1) qIdx = 0;

    AppLogger.d('Opening stream: ${qualities[qIdx]['quality']}');
    _player.open(
      qualities[qIdx]['url'] as String,
      startAt,
      headers: state.headers,
    );

    if (startAt > Duration.zero) {
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (ref.read(playerStateProvider).duration > Duration.zero) {
          _player.seek(startAt);
          timer.cancel();
        } else if (timer.tick >= 25) {
          timer.cancel();
        }
      });
    }

    final engIdx = state.subtitles.indexWhere(
      (s) => s.lang?.toLowerCase().contains('eng') ?? false,
    );
    if (engIdx != -1) changeSubtitle(engIdx);

    state = state.copyWith(
      qualityOptions: qualities,
      selectedSourceIdx: sourceIdx,
      selectedQualityIdx: qIdx,
      removeState: EpisodeStreamState.QUALITY_LOADING,
    );
  }

  Future<BaseSourcesModel?> _fetchSourceData(
    EpisodeDataModel ep, {
    ServerData? server,
  }) async {
    AppLogger.d('Fetching source data via ${server?.name ?? "Extension"}');
    if (_exp.useExtensions && ep.url != null) {
      final res = await _srcNotifier.getSources(
        DEpisode(episodeNumber: ep.number.toString(), url: ep.url),
      );
      return BaseSourcesModel(
        sources: res
            .map(
              (s) => Source(
                url: s?.url,
                isM3U8: s?.url.contains('.m3u8') ?? false,
                quality: "${s?.title}-${s?.quality ?? ''}",
                isDub: s?.url.toLowerCase().contains('dub') ?? false,
              ),
            )
            .toList(),
        tracks:
            res.firstOrNull?.subtitles
                ?.map((e) => Subtitle(url: e.file, lang: e.label))
                .toList() ??
            [],
      );
    }

    return _provider?.getSources(
      _epList.animeId ?? '',
      ep.id ?? '',
      server?.id,
      server?.isDub == true ? 'dub' : 'sub',
    );
  }

  Future<List<Map<String, dynamic>>> _getQualities(
    Source src,
    Map<String, String>? headers,
  ) async {
    if (src.url == null) return [];
    if (!src.isM3U8)
      return [
        {'quality': src.quality ?? 'Default', 'url': src.url},
      ];

    try {
      AppLogger.d('Extracting M3U8 qualities...');
      return await extractor.extractQualities(src.url!, headers ?? {}, true);
    } catch (e, stack) {
      AppLogger.e(
        'Quality extraction failed, falling back to default',
        e,
        stack,
      );
      return [
        {'quality': src.quality ?? 'Default', 'url': src.url},
      ];
    }
  }

  void _showLoading(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  void _showSnack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<ServerData?> _showServerSheet(
    BuildContext context,
    List<ServerData> servers,
  ) {
    return showModalBottomSheet<ServerData>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Server',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: servers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = servers[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.id ?? 'unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: s.name?.isNotEmpty == true
                          ? Text(s.name!)
                          : null,
                      trailing: Badge(
                        label: Text(s.isDub ? 'DUB' : 'SUB'),
                        backgroundColor: s.isDub
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                      onTap: () => Navigator.pop(context, s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
