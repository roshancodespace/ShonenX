import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/details/view_model/local_tracker_notifier.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/shared/providers/mal_service_provider.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/shared/providers/settings/sync_settings_notifier.dart';

part 'watch_controller.g.dart';

@riverpod
class WatchController extends _$WatchController with WidgetsBindingObserver {
  ScreenshotController? _screenshotController;
  int? _lastAniSkipEpisode;
  bool _isDisposed = false;

  WatchProgressRepository? _repo;
  String? _mediaId, _animeName, _animeFormat, _animeCover;
  int _pos = 0, _dur = 0, _totalEps = 0;
  int? _epNum;
  String? _epTitle, _epThumb;

  int _lastSavedPos = -1;

  Timer? _progressTimer;
  int _timerTickCount = 0;

  @override
  void build() {
    _repo = ref.read(watchProgressRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      _isDisposed = true;
      _progressTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
      _saveProgressSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveProgressSync();
    }
  }

  void setScreenshotController(ScreenshotController controller) =>
      _screenshotController = controller;

  Future<void> initialize({
    required String animeName,
    required String? animeId,
    required List<EpisodeDataModel> episodes,
    required int initialEpisode,
    required String mediaId,
    required String? animeFormat,
    required String animeCover,
  }) async {
    if (_isDisposed) return;

    _mediaId = mediaId;
    _animeName = animeName;
    _animeFormat = animeFormat;
    _animeCover = animeCover;
    _totalEps = episodes.length;

    await Future.wait([
      ref.read(episodeListProvider.notifier).fetchEpisodes(
            animeTitle: animeName,
            animeId: animeId,
            episodes: episodes,
            force: false,
          ),
      _initEpisode(animeId, initialEpisode),
    ]);

    _attachPlaybackListeners(mediaId, animeName, episodes);
    _startProgressTimer();
  }

  Future<void> _initEpisode(String? animeId, int initialEpisode) async {
    if (animeId == null || _repo == null) return;
    final progress = _repo!.getEpisodeProgress(animeId, initialEpisode);

    _epNum = initialEpisode;
    _pos = progress?.progressInSeconds ?? 0;
    _dur = progress?.durationInSeconds ?? 0;

    await ref.read(episodeDataProvider.notifier).loadEpisode(
          ep: initialEpisode,
          startAt: Duration(seconds: _pos),
        );
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _timerTickCount = 0;

    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_pos == _lastSavedPos) return;

      _timerTickCount++;

      if (_timerTickCount % 2 != 0) {
        final thumb = await _captureScreenshot();
        if (thumb != null) _epThumb = thumb;
      }

      _saveProgressSync();
    });
  }

  void _saveProgressSync() {
    if (_repo == null || _mediaId == null || _epNum == null) return;
    if (_pos == _lastSavedPos) return;

    try {
      final entry = _repo!.getProgress(_mediaId!) ??
          AnimeWatchProgressEntry(
            animeId: _mediaId!,
            animeTitle: _animeName!,
            animeFormat: _animeFormat,
            animeCover: _animeCover!,
            totalEpisodes: _totalEps,
          );

      final progress = EpisodeProgress(
        episodeNumber: _epNum!,
        episodeTitle: _epTitle ?? 'Episode $_epNum',
        episodeThumbnail: _epThumb,
        progressInSeconds: _pos,
        durationInSeconds: _dur,
        isCompleted: _dur > 0 ? (_pos / _dur > 0.85) : false,
        watchedAt: DateTime.now(),
      );

      _repo!.saveProgress(entry);
      _repo!.updateEpisodeProgress(_mediaId!, progress);

      _lastSavedPos = _pos;
      AppLogger.d("Progress Timer Saved: Ep $_epNum at $_pos seconds");
    } catch (e) {
      AppLogger.e('WatchController: Save failed', e);
    }
  }

  Future<void> saveProgressManual({bool takeScreenshot = false}) async {
    if (_isDisposed || _mediaId == null || _repo == null || _epNum == null) {
      return;
    }

    try {
      if (takeScreenshot) {
        final thumb = await _captureScreenshot();
        if (thumb != null) _epThumb = thumb;
      }
      _saveProgressSync();
    } catch (e) {
      AppLogger.e('Manual save failed', e);
    }
  }

  Future<String?> _captureScreenshot() async {
    if (_screenshotController == null) return null;
    try {
      final bytes = await _screenshotController!.capture(pixelRatio: 0.5);
      return bytes != null ? base64Encode(bytes) : null;
    } catch (_) {
      return null;
    }
  }

  void _attachPlaybackListeners(
    String mediaId,
    String animeName,
    List<EpisodeDataModel> episodes,
  ) {
    ref.listen(playerStateProvider, (prev, next) {
      _pos = next.position.inSeconds;
      _dur = next.duration.inSeconds;

      if (_dur > 120) _checkAniSkip(mediaId, animeName, next.duration);
      if (ref.read(playerSettingsProvider).enableAutoSkip) {
        _checkAutoSkip(next.position);
      }
    });

    ref.listen(episodeDataProvider.select((p) => p.selectedEpisode), (
      prev,
      next,
    ) {
      if (next != null) {
        _epNum = next;
        try {
          final epInfo = episodes.firstWhere((e) => e.number == next);
          _epTitle = epInfo.title;
          _epThumb = epInfo.thumbnail;
        } catch (_) {}
      }

      if (prev != null && prev != next) {
        saveProgressManual(takeScreenshot: true);
        _timerTickCount = 0;
      }

      if (next != null && next != prev) _handleTrackingUpdate(mediaId, next);
    });
  }

  void _checkAniSkip(String mediaId, String animeName, Duration duration) {
    if (!ref.read(playerSettingsProvider).enableAniSkip) {
      ref.read(aniSkipProvider.notifier).clear();
      return;
    }
    final epNum = _epNum;
    if (epNum == null || epNum == _lastAniSkipEpisode) return;
    _lastAniSkipEpisode = epNum;
    ref.read(aniSkipProvider.notifier).fetchSkipTimes(
          mediaId: mediaId,
          animeTitle: animeName,
          episodeNumber: epNum,
          episodeLength: duration.inSeconds,
        );
  }

  void _checkAutoSkip(Duration position) {
    final skips = ref.read(aniSkipProvider);
    for (final skip in skips) {
      if (skip.interval == null) continue;
      final start = Duration(seconds: skip.interval!.startTime.toInt());
      final end = Duration(seconds: skip.interval!.endTime.toInt());
      if (position >= start && position < end) {
        ref.read(playerStateProvider.notifier).seek(end);
        return;
      }
    }
  }

  Future<void> _handleTrackingUpdate(String mediaId, int epNum) async {
    await Future.delayed(const Duration(seconds: 5));
    if (_isDisposed) return;
    final syncNotifier = ref.read(syncSettingsProvider.notifier);
    if (syncNotifier.isManualSync ||
        ref.read(syncSettingsProvider).askBeforeSync) {
      return;
    }
    if (epNum > 0 && epNum <= _totalEps) {
      updateTracking(mediaId: mediaId, episodeNum: epNum);
    }
  }

  Future<void> updateTracking({
    required String mediaId,
    required int episodeNum,
  }) async {
    try {
      final syncNotifier = ref.read(syncSettingsProvider.notifier);
      final mediaIdInt = int.tryParse(mediaId) ?? 0;
      final List<Future> tasks = [];

      if (syncNotifier.shouldSyncAnilist) {
        tasks.add(
          ref.read(anilistServiceProvider).updateUserAnimeList(
                mediaId: mediaIdInt,
                progress: episodeNum,
                status: 'CURRENT',
              ),
        );
      }
      if (syncNotifier.shouldSyncMal) {
        tasks.add(
          ref.read(malServiceProvider).updateUserAnimeList(
                mediaId: mediaIdInt,
                progress: episodeNum,
                status: 'CURRENT',
              ),
        );
      }

      if (syncNotifier.shouldSyncLocal && _repo != null) {
        final entry = _repo!.getProgress(mediaId);
        final localEntry = await ref
            .read(localTrackerProvider.notifier)
            .getEntry(mediaId);

        tasks.add(
          ref.read(localTrackerProvider.notifier).saveEntry(
                UniversalMedia(
                  id: mediaId,
                  title: UniversalTitle(
                    english: entry?.animeTitle ?? 'Unknown',
                  ),
                  coverImage: UniversalCoverImage(large: entry?.animeCover),
                  status: 'UNKNOWN',
                  format: entry?.animeFormat,
                  episodes: entry?.totalEpisodes,
                ),
                status: 'CURRENT',
                progress: episodeNum,
                score: localEntry?.score ?? 0.0,
                repeat: localEntry?.repeat ?? 0,
                notes: localEntry?.notes ?? '',
                isPrivate: localEntry?.isPrivate ?? false,
                startedAt: DateTime.now(),
              ),
        );
      }

      if (tasks.isNotEmpty) await Future.wait(tasks);
    } catch (e) {
      AppLogger.e('Tracking update failed', e);
    }
  }
}