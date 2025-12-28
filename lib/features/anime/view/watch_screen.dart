import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view/widgets/episodes_panel.dart';
import 'package:shonenx/features/anime/view/widgets/player/controls_overlay.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/utils/formatter.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String mediaId;
  final String? animeId;
  final String animeName;
  final String animeFormat;
  final String animeCover;
  final int episode;
  final Duration startAt;
  final List<EpisodeDataModel>? episodes;

  const WatchScreen({
    super.key,
    required this.mediaId,
    required this.animeName,
    required this.animeFormat,
    required this.animeCover,
    this.animeId,
    this.startAt = Duration.zero,
    this.episode = 1,
    this.episodes = const [],
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final CurvedAnimation _panelAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();

  Timer? _progressTimer;
  bool _isPlaying = false;
  bool _resumeChecked = false;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _panelAnimation =
        CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(episodeListProvider.notifier).fetchEpisodes(
            animeTitle: widget.animeName,
            animeId: widget.animeId,
            episodes: widget.episodes ?? [],
            force: false,
          );

      await ref
          .read(episodeDataProvider.notifier)
          .loadEpisode(epIdx: widget.episode - 1, startAt: widget.startAt);

      _startProgressTimer();
    });
  }

  void _attachListeners() {
    ref.listen<bool>(
      playerStateProvider.select((p) => p.isPlaying),
      (prev, next) {
        _isPlaying = next;
        if (prev == true && next == false) {
          _saveProgress(takeScreenshot: true);
        }
      },
    );

    ref.listen<int?>(
      episodeDataProvider.select((d) => d.selectedEpisodeIdx),
      (_, __) => _resumeChecked = false,
    );

    ref.listen<PlayerState>(
      playerStateProvider,
      (_, next) => _handleResume(next),
    );
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    int ticks = 0;

    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isPlaying) return;
      ticks++;
      _saveProgress(takeScreenshot: ticks % 12 == 0);
    });
  }

  Future<void> _saveProgress({bool takeScreenshot = false}) async {
    try {
      final player = ref.read(playerStateProvider);
      final episodeData = ref.read(episodeDataProvider);
      final episodes = ref.read(episodeListProvider).episodes;
      final repo = ref.read(watchProgressRepositoryProvider);

      final idx = episodeData.selectedEpisodeIdx;
      if (idx == null || idx < 0 || idx >= episodes.length) return;

      final ep = episodes[idx];
      final pos = player.position.inSeconds;
      final dur = player.duration.inSeconds;
      if (dur <= 0) return;

      String? thumbnail;

      if (takeScreenshot) {
        try {
          final bytes = await _screenshotController.capture(pixelRatio: 1.5);
          if (bytes != null) thumbnail = base64Encode(bytes);
        } catch (_) {}
      }

      thumbnail ??= repo
          .getEpisodeProgress(widget.mediaId, ep.number ?? idx + 1)
          ?.episodeThumbnail;
      thumbnail ??= ep.thumbnail;

      final progress = EpisodeProgress(
        episodeNumber: ep.number ?? idx + 1,
        episodeTitle: ep.title ?? 'Episode ${idx + 1}',
        episodeThumbnail: thumbnail,
        progressInSeconds: pos,
        durationInSeconds: dur,
        isCompleted: pos / dur > 0.9,
        watchedAt: DateTime.now(),
      );

      var entry = repo.getProgress(widget.mediaId);
      entry ??= AnimeWatchProgressEntry(
        animeId: widget.mediaId,
        animeTitle: widget.animeName,
        animeFormat: widget.animeFormat,
        animeCover: widget.animeCover,
        totalEpisodes: episodes.length,
      );

      await repo.saveProgress(entry);
      await repo.updateEpisodeProgress(widget.mediaId, progress);
    } catch (e) {
      AppLogger.e(e);
    }
  }

  Future<void> _handleResume(PlayerState state) async {
    if (_resumeChecked || state.duration == Duration.zero) return;
    _resumeChecked = true;

    final episodeData = ref.read(episodeDataProvider);
    final idx = episodeData.selectedEpisodeIdx;
    if (idx == null) return;

    final episode = ref.read(episodeListProvider).episodes.elementAt(idx);
    final repo = ref.read(watchProgressRepositoryProvider);

    final progress = repo.getEpisodeProgress(
      widget.mediaId,
      episode.number ?? idx + 1,
    );

    if (progress == null || (progress.progressInSeconds ?? 0) < 5) return;

    final notifier = ref.read(playerStateProvider.notifier);
    notifier.pause();

    final resume = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resume?'),
        content: Text(
          'Resume from ${formatDuration(Duration(seconds: progress.progressInSeconds!))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (resume == true) {
      notifier.seek(Duration(seconds: progress.progressInSeconds!));
    }
    notifier.play();
  }

  void _togglePanel() {
    _panelController.isCompleted
        ? _panelController.reverse()
        : _panelController.forward();
  }

  Future<void> _setupSystemUI() async {
    await UIHelper.enableImmersiveMode();
    await UIHelper.forceLandscape();
  }

  Future<void> _resetSystemUI() async {
    await UIHelper.exitImmersiveMode();
    await UIHelper.forcePortrait();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _resetSystemUI();
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _attachListeners();
    final fit = ref.watch(playerStateProvider.select((p) => p.fit));
    final notifier = ref.read(playerStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (_, orientation) {
          final player = Stack(
            fit: StackFit.expand,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Video(
                  controller: notifier.videoController,
                  fit: fit,
                  wakelock: true,
                  filterQuality:
                      kDebugMode ? FilterQuality.none : FilterQuality.medium,
                  controls: NoVideoControls,
                ),
              ),
              CloudstreamControls(onEpisodesPressed: _togglePanel),
            ],
          );

          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: player),
                SizeTransition(
                  sizeFactor: _panelAnimation,
                  axis: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: EpisodesPanel(panelAnimation: _panelController),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: player),
              Expanded(
                child: SizeTransition(
                  sizeFactor: _panelAnimation,
                  axis: Axis.vertical,
                  child: EpisodesPanel(panelAnimation: _panelController),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
