import 'dart:async';
import 'dart:convert';
import 'package:workmanager/workmanager.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/local_media_repository.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/shared/providers/settings/sync_settings_notifier.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/shared/providers/tracker/media_tracker_notifier.dart';

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
  int _screenshotTick = 0;
  bool _trackingTriggered = false;

  @override
  void build() {
    _repo = ref.read(watchProgressRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      _isDisposed = true;
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

    await ref
        .read(episodeListProvider.notifier)
        .fetchEpisodes(
          animeTitle: animeName,
          animeId: animeId,
          episodes: episodes,
          force: false,
        );

    await _initEpisode(mediaId, initialEpisode);
    _attachPlaybackListeners(mediaId, animeName, episodes);
  }

  Future<void> _initEpisode(String? mediaId, int initialEpisode) async {
    if (mediaId == null) return;

    final progress = _repo!.getEpisodeProgress(mediaId, initialEpisode);
    _epNum = initialEpisode;
    _pos = progress?.progressInSeconds ?? 0;
    _dur = progress?.durationInSeconds ?? 0;
    _lastSavedPos = _pos;

    await ref
        .read(episodeDataProvider.notifier)
        .loadEpisode(
          ep: _epNum!,
          startAt: Duration(seconds: _pos),
        );
  }

  void _attachPlaybackListeners(
    String mediaId,
    String animeName,
    List<EpisodeDataModel> episodes,
  ) {
    ref.listen(playerStateProvider, (prev, next) {
      if (_isDisposed) return;

      _pos = next.position.inSeconds;
      _dur = next.duration.inSeconds;

      if (_dur > 120) _checkAniSkip(mediaId, animeName, next.duration);
      _checkAutoSkip(next.position);

      final syncPercentage = ref.read(syncSettingsProvider).syncPercentage;
      if (!_trackingTriggered &&
          _dur > 0 &&
          (_pos / _dur * 100) >= syncPercentage) {
        _trackingTriggered = true;
        if ((_epNum ?? 0) > 0) _handleTrackingUpdate(mediaId, _epNum!);
      }

      // Delta-based save: Triggers every 10 seconds of playback/seeking
      if (_dur > 0 && (_pos - _lastSavedPos).abs() >= 10) {
        _handlePeriodicSave();
      }
    });

    ref.listen(episodeDataProvider.select((p) => p.selectedEpisode), (
      prev,
      next,
    ) {
      if (prev != null && prev != next && _epNum == prev) {
        saveProgressManual(takeScreenshot: true);
      }

      if (next != null) {
        _epNum = next;
        _pos = 0;
        _dur = 0;
        _lastSavedPos = -1;
        _trackingTriggered = false;
        try {
          final epInfo = episodes.firstWhere((e) => e.number == next);
          _epTitle = epInfo.title;
          _epThumb = epInfo.thumbnail;
        } catch (_) {}
      }
    });
  }

  Future<void> _handlePeriodicSave() async {
    _screenshotTick++;
    if (_screenshotTick % 2 == 0) {
      final thumb = await _captureScreenshot();
      if (thumb != null) _epThumb = thumb;
    }
    _saveProgressSync();
  }

  void _saveProgressSync() async {
    if (_repo == null ||
        _mediaId == null ||
        _epNum == null ||
        _dur == 0 ||
        _pos == 0 ||
        _pos == _lastSavedPos) {
      return;
    }

    try {
      final entry =
          _repo!.getProgress(_mediaId!) ??
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

      await _repo!.saveProgress(entry);
      await _repo!.updateEpisodeProgress(_mediaId!, progress);

      _lastSavedPos = _pos;
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

  void _checkAniSkip(String mediaId, String animeName, Duration duration) {
    if (!ref.read(playerSettingsProvider).enableAniSkip) {
      ref.read(aniSkipProvider.notifier).clear();
      return;
    }

    final epNum = _epNum;
    if (epNum == null || epNum == _lastAniSkipEpisode) return;

    _lastAniSkipEpisode = epNum;
    ref
        .read(aniSkipProvider.notifier)
        .fetchSkipTimes(
          mediaId: mediaId,
          animeTitle: animeName,
          episodeNumber: epNum,
          episodeLength: duration.inSeconds,
        );
  }

  void _checkAutoSkip(Duration position) {
    if (!ref.read(playerSettingsProvider).enableAutoSkip) return;

    final skips = ref.read(aniSkipProvider);
    if (skips.isEmpty) return;

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
    if (_isDisposed) return;

    final syncSettings = ref.read(syncSettingsProvider);
    final syncNotifier = ref.read(syncSettingsProvider.notifier);

    if (syncNotifier.isManualSync || syncSettings.askBeforeSync) return;
    updateTracking(mediaId: mediaId, episodeNum: epNum);
  }

  Future<void> updateTracking({
    required String mediaId,
    required int episodeNum,
  }) async {
    try {
      final syncSettings = ref.read(syncSettingsProvider);
      final syncNotifier = ref.read(syncSettingsProvider.notifier);
      final repo = ref.read(localMediaRepoProvider);
      final List<Future<void>> tasks = [];

      final bindings = await repo.getBindings(mediaId);

      final activeBindings = bindings
          .where(
            (b) =>
                (b.type == TrackerType.anilist &&
                    syncNotifier.shouldSyncAnilist) ||
                (b.type == TrackerType.mal && syncNotifier.shouldSyncMal),
          )
          .toList();

      if (syncSettings.syncMode == 'background') {
        final inputData = <String, dynamic>{'progress': episodeNum};
        for (final b in activeBindings) {
          if (b.type == TrackerType.anilist) {
            inputData['anilistId'] = b.remoteId;
          }
          if (b.type == TrackerType.mal) inputData['malId'] = b.remoteId;
        }

        if (inputData.containsKey('anilistId') ||
            inputData.containsKey('malId')) {
          Workmanager().registerOneOffTask(
            "sync_tracking_${mediaId}_$episodeNum",
            "sync_tracking_task",
            inputData: inputData,
            initialDelay: Duration(
              minutes: syncSettings.backgroundIntervalMinutes,
            ),
            existingWorkPolicy: ExistingWorkPolicy.replace,
          );
        }
      } else if (activeBindings.isNotEmpty) {
        tasks.add(
          ref
              .read(mediaTrackerProvider(mediaId).notifier)
              .syncTrackers(
                bindings: activeBindings,
                status: 'CURRENT',
                progress: episodeNum,
              ),
        );
      }

      if (syncNotifier.shouldSyncLocal && _repo != null) {
        final entry = _repo!.getProgress(mediaId);
        final localEntry = await ref
            .read(mediaTrackerProvider(mediaId).notifier)
            .getLocalEntry();

        tasks.add(
          ref
              .read(mediaTrackerProvider(mediaId).notifier)
              .saveLocalEntry(
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
