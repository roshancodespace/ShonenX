import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:screenshot/screenshot.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core/myanimelist/services/mal_service_provider.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view/widgets/episodes_panel.dart';
import 'package:shonenx/features/anime/view/widgets/player/shonenx_video_player.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
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
  int? _resumeCheckedEpisodeIndex;
  int? _lastAniSkipEpisode;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(episodeListProvider.notifier)
          .fetchEpisodes(
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
    ref.listen<bool>(playerStateProvider.select((p) => p.isPlaying), (
      prev,
      next,
    ) {
      _isPlaying = next;
      if (prev == true && next == false) {
        _saveProgress(takeScreenshot: true);
      }
    });

    ref.listen<Duration?>(playerStateProvider.select((p) => p.duration), (
      _,
      duration,
    ) {
      if (duration == null || duration.inSeconds <= 120) return;

      final episodes = ref.read(episodeListProvider).episodes;
      final currentIndex = ref.read(episodeDataProvider).selectedEpisodeIdx;

      if (currentIndex == null ||
          currentIndex < 0 ||
          currentIndex >= episodes.length)
        return;

      final settings = ref.read(playerSettingsProvider);

      if (!settings.enableAniSkip) {
        ref.read(aniSkipProvider.notifier).clear();
        return;
      }

      final ep = episodes[currentIndex];

      if (ep.number == null) return;
      if (ep.number == _lastAniSkipEpisode) return;

      _lastAniSkipEpisode = ep.number;

      ref
          .read(aniSkipProvider.notifier)
          .fetchSkipTimes(
            mediaId: widget.mediaId,
            animeTitle: widget.animeName,
            episodeNumber: ep.number!.toInt(),
            episodeLength: duration.inSeconds,
          );
    });

    // Auto-Skip Listener
    ref.listen<Duration>(playerStateProvider.select((p) => p.position), (
      _,
      pos,
    ) {
      final skips = ref.read(aniSkipProvider);
      if (skips.isEmpty) return;

      final settings = ref.read(playerSettingsProvider);
      if (!settings.enableAutoSkip) return;

      for (final skip in skips) {
        if (skip.interval == null) continue;
        final start = Duration(seconds: skip.interval!.startTime.toInt());
        final end = Duration(seconds: skip.interval!.endTime.toInt());

        if (pos >= start && pos < end) {
          ref.read(playerStateProvider.notifier).seek(end);
          break;
        }
      }
    });

    ref.listen<PlayerState>(
      playerStateProvider,
      (_, next) => _handleResume(next),
    );

    // Tracking / Sync Listener
    ref.listen<int?>(episodeDataProvider.select((p) => p.selectedEpisodeIdx), (
      prev,
      next,
    ) async {
      if (next == null || next == prev) return;

      final episodes = ref.read(episodeListProvider).episodes;
      if (next < 0 || next >= episodes.length) return;

      final ep = episodes[next];
      final episodeNum = ep.number?.toInt() ?? (next + 1);

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final settingsBox = Hive.box('settings');
      final askToUpdate = settingsBox.get(
        'tracking_ask_update_on_start',
        defaultValue: false,
      );
      final syncAnilist = settingsBox.get(
        'tracking_sync_anilist',
        defaultValue: true,
      );
      final syncMal = settingsBox.get('tracking_sync_mal', defaultValue: true);

      final auth = ref.read(authProvider);
      final canSyncAnilist = auth.isAniListAuthenticated && syncAnilist;
      final canSyncMal = auth.isMalAuthenticated && syncMal;

      if (!canSyncAnilist && !canSyncMal) return;

      if (askToUpdate) {
        // Ask user
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Tracking?'),
            content: Text(
              'Mark episode $episodeNum as watched on ${canSyncAnilist && canSyncMal ? 'AniList & MAL' : (canSyncAnilist ? 'AniList' : 'MyAnimeList')}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Update'),
              ),
            ],
          ),
        );

        if (shouldUpdate == true) {
          _updateTracking(episodeNum, anilist: canSyncAnilist, mal: canSyncMal);
        }
      } else {
        _updateTracking(episodeNum, anilist: canSyncAnilist, mal: canSyncMal);
      }
    });
  }

  Future<void> _updateTracking(
    int episodeNum, {
    bool anilist = false,
    bool mal = false,
  }) async {
    try {
      final List<Future> tasks = [];
      final List<String> updatedServices = [];

      if (anilist) {
        tasks.add(
          ref
              .read(anilistServiceProvider)
              .updateUserAnimeList(
                mediaId: int.parse(widget.mediaId),
                progress: episodeNum,
                status: 'CURRENT',
              )
              .then((_) => updatedServices.add('AniList')),
        );
      }

      if (mal) {
        tasks.add(
          ref
              .read(malServiceProvider)
              .updateUserAnimeList(
                mediaId: int.parse(widget.mediaId),
                progress: episodeNum,
                status: 'CURRENT',
              )
              .then((_) => updatedServices.add('MAL')),
        );
      }

      await Future.wait(tasks);

      if (mounted && updatedServices.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tracking updated: Episode $episodeNum (${updatedServices.join(", ")})',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 300,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to update tracking: $e');
    }
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
          final bytes = await _screenshotController.capture(pixelRatio: 1);
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
    if (state.duration == Duration.zero) return;

    final episodeData = ref.read(episodeDataProvider);
    final idx = episodeData.selectedEpisodeIdx;

    if (idx == null || idx == _resumeCheckedEpisodeIndex) return;

    // Set immediately to prevent re-entry
    _resumeCheckedEpisodeIndex = idx;

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
    // await UIHelper.forcePortrait();
    await UIHelper.enableAutoRotate();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (_, orientation) {
          final player = ShonenXVideoPlayer(
            onEpisodesPressed: _togglePanel,
            screenshotController: _screenshotController,
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
                    child: EpisodesPanel(
                      panelAnimation: _panelController,
                      mediaId: widget.mediaId,
                    ),
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
                  child: EpisodesPanel(
                    panelAnimation: _panelController,
                    mediaId: widget.mediaId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
