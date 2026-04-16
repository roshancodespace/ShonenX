import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/watch/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/watch/view_model/episode_list_provider.dart';
import 'package:shonenx/features/watch/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/watch/view_model/player/player_provider.dart';
import 'package:shonenx/features/watch/view_model/watch_progress_notifier.dart';
import 'package:shonenx/features/watch/view_model/watch_sync_notifier.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/shared/providers/settings/sync_settings_notifier.dart';

part 'watch_controller.g.dart';

@riverpod
class WatchController extends _$WatchController with WidgetsBindingObserver {
  int? _lastAniSkipEpisode;
  bool _isDisposed = false;
  bool _isPlayerReady = false;

  String? _mediaId, _animeName, _animeFormat, _animeCover;
  int _pos = 0, _dur = 0, _totalEps = 0;
  int? _epNum;
  String? _epTitle, _epThumb;

  int _lastSavedPos = -1;
  int _lastScreenshotPos = -1;
  bool _trackingTriggered = false;

  @override
  void build() {
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      _isDisposed = true;
      WidgetsBinding.instance.removeObserver(this);
      _triggerSave();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _triggerSave();
    }
  }

  void setScreenshotController(ScreenshotController controller) {
    ref
        .read(watchProgressProvider.notifier)
        .setScreenshotController(controller);
  }

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

    _isPlayerReady = false;
    _epNum = initialEpisode;

    await ref
        .read(episodeDataProvider.notifier)
        .loadEpisode(ep: initialEpisode);
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

      if (!_isPlayerReady) {
        if (_dur == 0 || next.position.inSeconds == 0) return;
        _isPlayerReady = true;

        try {
          final repo = ref.read(watchProgressRepositoryProvider);
          final progress = repo.getEpisodeProgress(mediaId, _epNum ?? 1);
          if (progress != null && (progress.progressInSeconds ?? 0) > 0) {
            final targetSeconds = progress.progressInSeconds!;
            if (targetSeconds < _dur - 10) {
              ref
                  .read(playerStateProvider.notifier)
                  .seek(Duration(seconds: targetSeconds));
            }
          }
        } catch (_) {}
      }

      if (_dur > 120) _checkAniSkip(mediaId, animeName, next.duration);
      _checkAutoSkip(next.position);

      final syncPercentage = ref.read(syncSettingsProvider).syncPercentage;
      if (!_trackingTriggered &&
          _dur > 0 &&
          (_pos / _dur * 100) >= syncPercentage) {
        _trackingTriggered = true;
        if ((_epNum ?? 0) > 0) {
          ref
              .read(watchSyncProvider.notifier)
              .handleTrackingUpdate(mediaId: mediaId, episodeNum: _epNum!);
        }
      }

      _handlePeriodicSave();
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
        _trackingTriggered = false;
        _isPlayerReady = false;
        ref.read(watchProgressProvider.notifier).resetLastSavedPosition();

        try {
          final epInfo = episodes.firstWhere((e) => e.number == next);
          _epTitle = epInfo.title;
          _epThumb = epInfo.thumbnail;
        } catch (_) {}
      }
    });
  }

  Future<void> _handlePeriodicSave() async {
    if (_lastSavedPos == -1) _lastSavedPos = _pos;
    if (_lastScreenshotPos == -1) _lastScreenshotPos = _pos;

    if ((_pos - _lastSavedPos).abs() >= 5) {
      _lastSavedPos = _pos;
      final bool captureScreenshot = (_pos - _lastScreenshotPos).abs() >= 15;

      if (captureScreenshot) _lastScreenshotPos = _pos;
      _triggerSave(takeScreenshot: captureScreenshot);
    }
  }

  Future<void> _triggerSave({bool takeScreenshot = false}) async {
    if (_mediaId == null || _epNum == null) return;

    final newThumb = await ref
        .read(watchProgressProvider.notifier)
        .saveProgress(
          mediaId: _mediaId!,
          animeName: _animeName!,
          animeFormat: _animeFormat,
          animeCover: _animeCover!,
          totalEps: _totalEps,
          epNum: _epNum!,
          epTitle: _epTitle,
          epThumb: _epThumb,
          pos: _pos,
          dur: _dur,
          takeScreenshot: takeScreenshot,
        );

    if (newThumb != null) _epThumb = newThumb;
  }

  Future<void> saveProgressManual({bool takeScreenshot = false}) async {
    if (_isDisposed) return;
    await _triggerSave(takeScreenshot: takeScreenshot);
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
}
