import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';

import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view/widgets/episodes_panel.dart';
import 'package:shonenx/features/anime/view/widgets/player/controls_overlay.dart';
import 'package:shonenx/helpers/ui.dart';
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
  final String? mMangaUrl;

  const WatchScreen(
      {super.key,
      required this.mediaId,
      required this.animeName,
      required this.animeFormat,
      required this.animeCover,
      this.animeId,
      this.startAt = Duration.zero,
      this.episode = 1,
      this.episodes = const [],
      this.mMangaUrl});

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _panelAnimationController;
  late final CurvedAnimation _panelAnimation;

  Timer? _progressTimer;
  bool _hasShownResumeDialog = false;

  @override
  void initState() {
    super.initState();
    _setUpSystemUI();

    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Trigger the initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref.read(episodeDataProvider.notifier).fetchEpisodes(
            animeTitle: widget.animeName,
            animeId: widget.animeId,
            initialEpisodeIdx: widget.episode - 1,
            startAt: widget.startAt,
            force: false,
            play: true,
            mMangaUrl: widget.mMangaUrl,
            episodes: widget.episodes ?? [],
          );
      _startProgressTimer();
    });
  }

  void _startProgressTimer() {
    int ticks = 0;
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final isPlaying = ref.read(playerStateProvider).isPlaying;
      if (isPlaying) {
        ticks++;
        _saveProgress(takeScreenshot: ticks % 12 == 0);
      }
    });
  }

  Future<void> _saveProgress({bool takeScreenshot = false}) async {
    if (!ref.context.mounted && !mounted && !context.mounted) return;
    final playerState = ref.read(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);
    final episodeData = ref.read(episodeDataProvider);
    final currentEpisodeIdx = episodeData.selectedEpisodeIdx;

    if (currentEpisodeIdx == null ||
        currentEpisodeIdx < 0 ||
        currentEpisodeIdx >= episodeData.episodes.length) {
      return;
    }

    final currentEpisode = episodeData.episodes[currentEpisodeIdx];
    final position = playerState.position.inSeconds;
    final duration = playerState.duration.inSeconds;

    if (duration <= 0) return;

    String? thumbnailToSave;
    final repo = ref.read(watchProgressRepositoryProvider);

    if (takeScreenshot) {
      final screenshot = await playerNotifier.getThumbnail();
      if (screenshot != null) {
        thumbnailToSave = base64Encode(screenshot);
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

    if (widget.mediaId.isNotEmpty && mounted) {
      // Ensure we have an entry for the anime first

      var entry = repo.getProgress(widget.mediaId);
      if (entry == null && widget.mediaId.isNotEmpty) {
        entry = AnimeWatchProgressEntry(
          animeId: widget.mediaId,
          animeTitle: widget.animeName,
          animeFormat: widget.animeFormat, // Default or fetch from somewhere
          animeCover: widget.animeCover, // Need cover image
          totalEpisodes: episodeData.episodes.length,
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
    _progressTimer?.cancel();
    _saveProgress(takeScreenshot: false); // Save one last time
    _panelAnimation.dispose();
    _panelAnimationController.dispose();
    _resetSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fit = ref.watch(playerStateProvider.select((p) => p.fit));
    final playerNotifier = ref.read(playerStateProvider.notifier);

    ref.listen(playerStateProvider.select((p) => p.isPlaying), (prev, next) {
      if (prev == true && next == false) {
        _saveProgress(takeScreenshot: true);
      }
    });

    ref.listen(episodeDataProvider.select((d) => d.selectedEpisodeIdx),
        (_, __) {
      _hasShownResumeDialog = false;
    });

    ref.listen(playerStateProvider, (prev, next) async {
      if (_hasShownResumeDialog) return;
      if (next.duration != Duration.zero) {
        _hasShownResumeDialog = true;

        final episodeData = ref.read(episodeDataProvider);
        final currentIdx = episodeData.selectedEpisodeIdx;
        if (currentIdx == null) return;
        final currentEpisode = episodeData.episodes[currentIdx];

        // If this is the initial episode and we have a forced start time, skip
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

          final shouldResume = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Resume?'),
              content: Text(
                  'Resume from ${formatDuration(Duration(seconds: progress.progressInSeconds!))}?'),
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

          if (shouldResume == true) {
            playerNotifier.seek(Duration(seconds: progress.progressInSeconds!));
            playerNotifier.play();
          } else {
            playerNotifier.play();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: OrientationBuilder(
        builder: (context, orientation) {
          final videoPlayerWidget = Video(
            wakelock: true,
            controller: playerNotifier.videoController,
            fit: fit,
            filterQuality:
                kDebugMode ? FilterQuality.none : FilterQuality.medium,
            controls: (state) => CloudstreamControls(
              onEpisodesPressed: _toggleEpisodesPanel,
            ),
            subtitleViewConfiguration: SubtitleViewConfiguration(
              visible: false,
            ),
          );

          final episodesPanelWidget = _buildEpisodesPanel(context, orientation);

          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: videoPlayerWidget),
                episodesPanelWidget,
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
                  child: episodesPanelWidget,
                ),
              ],
            );
          }
        },
      )),
    );
  }

  Widget _buildEpisodesPanel(BuildContext context, Orientation orientation) {
    final animation = _panelAnimation;

    final panelContent = EpisodesPanel();

    if (orientation == Orientation.landscape) {
      final screenWidth = MediaQuery.of(context).size.width;
      final panelWidth =
          screenWidth < 800 ? screenWidth * 0.45 : screenWidth * 0.35;
      return SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        child: SizedBox(width: panelWidth, child: panelContent),
      );
    } else {
      return SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        child: panelContent,
      );
    }
  }
}
