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
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
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
  late final AnimationController _panelAnimationController;
  late final CurvedAnimation _panelAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPlaying = false;

  Timer? _progressTimer;
  bool _hasShownResumeDialog = false;

  @override
  void initState() {
    super.initState();
    _setUpSystemUI();

    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Trigger the initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref.read(episodeListProvider.notifier).fetchEpisodes(
            animeTitle: widget.animeName,
            animeId: widget.animeId,
            episodes: widget.episodes ?? [],
            force: false,
          );
      await ref
          .read(episodeDataProvider.notifier)
          .loadEpisode(episodeIdx: widget.episode - 1, startAt: widget.startAt);
      _startProgressTimer();
    });
  }

  void _startProgressTimer() {
    int ticks = 0;
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (_isPlaying) {
        ticks++;
        _saveProgress(takeScreenshot: ticks % 12 == 0);
      }
    });
  }

  Future<void> _saveProgress({bool takeScreenshot = false}) async {
    if (!mounted) return;

    try {
      final playerState = ref.read(playerStateProvider);
      final episodes = ref.read(episodeListProvider).episodes;
      final episodeData = ref.read(episodeDataProvider);
      final repo = ref.read(watchProgressRepositoryProvider);

      await _performSave(
        playerState: playerState,
        episodes: episodes,
        episodeData: episodeData,
        repo: repo,
        takeScreenshot: takeScreenshot,
      );
    } catch (e) {
      AppLogger.e('Failed to save progress: $e');
    }
  }

  Future<void> _performSave({
    required PlayerState playerState,
    required List<EpisodeDataModel> episodes,
    required EpisodeDataState episodeData,
    required WatchProgressRepository repo,
    bool takeScreenshot = false,
  }) async {
    final currentEpisodeIdx = episodeData.selectedEpisodeIdx;

    if (currentEpisodeIdx == null ||
        currentEpisodeIdx < 0 ||
        currentEpisodeIdx >= episodes.length) {
      return;
    }

    final currentEpisode = episodes[currentEpisodeIdx];
    final position = playerState.position.inSeconds;
    final duration = playerState.duration.inSeconds;

    if (duration <= 0) return;

    String? thumbnailToSave;

    if (takeScreenshot && mounted) {
      AppLogger.i('Taking screenshot');
      try {
        final screenshot = await _screenshotController.capture(pixelRatio: 1.5);
        if (screenshot != null) {
          thumbnailToSave = base64Encode(screenshot);
        }
      } catch (e) {
        // Ignore screenshot errors
      }
    }

    if (thumbnailToSave == null) {
      final existingProgress = repo.getEpisodeProgress(
          widget.mediaId, currentEpisode.number ?? (currentEpisodeIdx + 1));
      thumbnailToSave = existingProgress?.episodeThumbnail;
    }

    thumbnailToSave ??= currentEpisode.thumbnail;

    final progress = EpisodeProgress(
      episodeNumber: currentEpisode.number ?? (currentEpisodeIdx + 1),
      episodeTitle: currentEpisode.title ?? 'Episode ${currentEpisodeIdx + 1}',
      episodeThumbnail: thumbnailToSave,
      progressInSeconds: position,
      durationInSeconds: duration,
      isCompleted: (position / duration) > 0.9, // Mark as completed if > 90%
      watchedAt: DateTime.now(),
    );

    if (widget.mediaId.isNotEmpty) {
      // Ensure we have an entry for the anime first
      var entry = repo.getProgress(widget.mediaId);
      if (entry == null) {
        entry = AnimeWatchProgressEntry(
          animeId: widget.mediaId,
          animeTitle: widget.animeName,
          animeFormat: widget.animeFormat,
          animeCover: widget.animeCover,
          totalEpisodes: episodes.length,
        );
        await repo.saveProgress(entry);
      }

      await repo.updateEpisodeProgress(widget.mediaId, progress);
    }
  }

  void _toggleEpisodesPanel() {
    final isPanelOpen =
        _panelAnimationController.status == AnimationStatus.completed;
    isPanelOpen
        ? _panelAnimationController.reverse()
        : _panelAnimationController.forward();
  }

  Future<void> _setUpSystemUI() async {
    await UIHelper.enableImmersiveMode();
    await UIHelper.forceLandscape();
  }

  Future<void> _resetSystemUI() async {
    await UIHelper.exitImmersiveMode();
    await UIHelper.forcePortrait();
  }

  @override
  void dispose() {
    unawaited(_resetSystemUI());
    _progressTimer?.cancel();
    Future.microtask(() {
      if (mounted) _saveProgress(takeScreenshot: false);
    });
    _panelAnimation.dispose();
    _panelAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setupListeners();
    final fit = ref.watch(playerStateProvider.select((p) => p.fit));
    final playerNotifier = ref.read(playerStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            final videoPlayerWidget = Stack(
              fit: StackFit.expand,
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: Video(
                    fill: Theme.of(context).colorScheme.surfaceContainerLowest,
                    wakelock: true,
                    controller: playerNotifier.videoController,
                    fit: fit,
                    filterQuality:
                        kDebugMode ? FilterQuality.none : FilterQuality.medium,
                    controls: NoVideoControls,
                    subtitleViewConfiguration: const SubtitleViewConfiguration(
                      visible: false,
                    ),
                  ),
                ),
                CloudstreamControls(
                  onEpisodesPressed: _toggleEpisodesPanel,
                ),
              ],
            );

            if (isLandscape) {
              return Row(
                children: [
                  Expanded(child: videoPlayerWidget),
                  _buildAnimatedPanel(context, Axis.horizontal),
                ],
              );
            } else {
              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: videoPlayerWidget,
                  ),
                  Expanded(
                    child: _buildAnimatedPanel(context, Axis.vertical),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void _setupListeners() {
    ref.listen(playerStateProvider.select((p) => p.isPlaying), (prev, next) {
      _isPlaying = next;
      if (prev == true && next == false) {
        _saveProgress(takeScreenshot: true);
      }
    });

    ref.listen(episodeDataProvider.select((d) => d.selectedEpisodeIdx),
        (_, __) {
      _hasShownResumeDialog = false;
    });

    ref.listen(playerStateProvider, (prev, next) {
      _handleResumeCheck(next);
    });
  }

  Future<void> _handleResumeCheck(PlayerState next) async {
    if (next.duration == Duration.zero || _hasShownResumeDialog) return;

    _hasShownResumeDialog = true;

    final episodeData = ref.read(episodeDataProvider);
    final currentIdx = episodeData.selectedEpisodeIdx;
    if (currentIdx == null) return;
    final currentEpisode = ref.read(episodeListProvider).episodes[currentIdx];

    // Skip if explicitly starting at a position or for the specific requested episode
    if (widget.startAt != Duration.zero &&
        (currentEpisode.number == widget.episode ||
            currentIdx == (widget.episode - 1))) {
      return;
    }

    final animeId = widget.mediaId;
    if (animeId.isEmpty) return;

    final repo = ref.read(watchProgressRepositoryProvider);
    final progress = repo.getEpisodeProgress(
        animeId, currentEpisode.number ?? (currentIdx + 1));

    if (progress != null &&
        progress.progressInSeconds != null &&
        progress.progressInSeconds! > 5) {
      final playerNotifier = ref.read(playerStateProvider.notifier);
      playerNotifier.pause();

      final shouldResume = await _showResumeDialog(progress.progressInSeconds!);

      if (shouldResume == true) {
        playerNotifier.seek(Duration(seconds: progress.progressInSeconds!));
      }
      playerNotifier.play();
    }
  }

  Future<bool?> _showResumeDialog(int seconds) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume?'),
        content:
            Text('Resume from ${formatDuration(Duration(seconds: seconds))}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );
  }

  Widget _buildAnimatedPanel(BuildContext context, Axis axis) {
    if (axis == Axis.horizontal) {
      final screenWidth = MediaQuery.of(context).size.width;
      final panelWidth =
          screenWidth < 800 ? screenWidth * 0.45 : screenWidth * 0.35;
      return SizeTransition(
        sizeFactor: _panelAnimation,
        axis: axis,
        child: SizedBox(
          width: panelWidth,
          child: EpisodesPanel(panelAnimation: _panelAnimationController),
        ),
      );
    } else {
      return SizeTransition(
        sizeFactor: _panelAnimation,
        axis: axis,
        child: EpisodesPanel(panelAnimation: _panelAnimationController),
      );
    }
  }
}
