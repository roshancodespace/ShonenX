import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/shared/providers/mal_service_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/shared/providers/settings/sync_settings_notifier.dart';

import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/details/view_model/local_tracker_notifier.dart';

part 'watch_controller.g.dart';

@riverpod
class WatchController extends _$WatchController {
  Timer? _progressTimer;
  ScreenshotController? _screenshotController;
  int? _lastAniSkipEpisode;
  bool _playbackListenerAttached = false;

  @override
  void build() {
    ref.onDispose(() {
      _progressTimer?.cancel();
    });
  }

  void setScreenshotController(ScreenshotController controller) {
    _screenshotController = controller;
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
    await ref
        .read(episodeListProvider.notifier)
        .fetchEpisodes(
          animeTitle: animeName,
          animeId: animeId,
          episodes: episodes,
          force: false,
        );
    
    final startAt = (await _getEpisodeProgress(animeId!, initialEpisode))?.progressInSeconds ?? 0;

    await ref
        .read(episodeDataProvider.notifier)
        .loadEpisode(ep: initialEpisode, startAt: Duration(seconds: startAt));

    _startProgressTimer(mediaId, animeName, animeFormat, animeCover);

    if (!_playbackListenerAttached) {
      _attachPlaybackListeners(mediaId, animeName);
      _playbackListenerAttached = true;
    }
  }

  Future<EpisodeProgress?> _getEpisodeProgress(
    String animeId,
    int episodeNumber,
  ) async {
    return ref
        .read(watchProgressRepositoryProvider)
        .getEpisodeProgress(animeId, episodeNumber);
  }

  void _startProgressTimer(
    String mediaId,
    String animeName,
    String? animeFormat,
    String animeCover,
  ) {
    _progressTimer?.cancel();
    int ticks = 0;

    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final isPlaying = ref.read(playerStateProvider).isPlaying;
      if (!isPlaying) {
        return;
      }

      ticks++;
      saveProgress(
        mediaId: mediaId,
        animeName: animeName,
        animeFormat: animeFormat,
        animeCover: animeCover,
        takeScreenshot: ticks % 12 == 0,
      );
    });
  }

  Future<void> saveProgress({
    required String mediaId,
    required String animeName,
    String? animeFormat,
    required String animeCover,
    bool takeScreenshot = false,
  }) async {
    try {
      final player = ref.read(playerStateProvider);
      final episodeData = ref.read(episodeDataProvider);
      final episodes = ref.read(episodeListProvider).episodes;
      final repo = ref.read(watchProgressRepositoryProvider);

      final selectedEp = episodeData.selectedEpisode;
      if (selectedEp == null || selectedEp < 1 || selectedEp > episodes.length) {
        return;
      }

      final ep = episodes.firstWhere((i) => i.number == selectedEp);
      final pos = player.position.inSeconds;
      final dur = player.duration.inSeconds;
      if (dur <= 0) {
        return;
      }

      String? thumbnail;

      if (takeScreenshot && _screenshotController != null) {
        try {
          final bytes = await _screenshotController!.capture(pixelRatio: 1);
          if (bytes != null) thumbnail = base64Encode(bytes);
        } catch (_) {}
      }

      thumbnail ??= repo
          .getEpisodeProgress(mediaId, ep.number ?? selectedEp)
          ?.episodeThumbnail;
      thumbnail ??= ep.thumbnail;

      final progress = EpisodeProgress(
        episodeNumber: ep.number ?? selectedEp,
        episodeTitle: ep.title ?? 'Episode $selectedEp',
        episodeThumbnail: thumbnail,
        progressInSeconds: pos,
        durationInSeconds: dur,
        isCompleted: pos / dur > 0.85,
        watchedAt: DateTime.now(),
      );

      var entry = repo.getProgress(mediaId);
      entry ??= AnimeWatchProgressEntry(
        animeId: mediaId,
        animeTitle: animeName,
        animeFormat: animeFormat,
        animeCover: animeCover,
        totalEpisodes: episodes.length,
      );

      await repo.saveProgress(entry);
      await repo.updateEpisodeProgress(mediaId, progress);
    } catch (e) {
      AppLogger.e('Failed to save progress', e);
    }
  }

  void _attachPlaybackListeners(String mediaId, String animeName) {
    // AniSkip Listener
    ref.listen(playerStateProvider.select((p) => p.duration), (_, duration) {
      if (duration.inSeconds <= 120) {
        return;
      }
      _checkAniSkip(mediaId, animeName, duration);
    });

    // Auto-Skip Listener
    ref.listen(playerStateProvider.select((p) => p.position), (_, position) {
      _checkAutoSkip(position);
    });

    // Tracking Update Listener
    ref.listen(episodeDataProvider.select((p) => p.selectedEpisode), (
      prev,
      next,
    ) {
      if (next != null && next != prev) {
        _handleTrackingUpdate(mediaId, next);
      }
    });

    // Paused Listener (Save progress when paused)
    ref.listen(playerStateProvider.select((p) => p.isPlaying), (prev, next) {
      if (prev == true && next == false) {
        // pause logic
      }
    });
  }

  void _checkAniSkip(String mediaId, String animeName, Duration duration) {
    final episodes = ref.read(episodeListProvider).episodes;
    final currentEpisode = ref.read(episodeDataProvider).selectedEpisode;

    if (currentEpisode == null ||
        currentEpisode < 1 ||
        currentEpisode > episodes.length) {
      return;
    }

    AppLogger.d(
      'Checking AniSkip for episode $currentEpisode',
    );

    final settings = ref.read(playerSettingsProvider);
    if (!settings.enableAniSkip) {
      ref.read(aniSkipProvider.notifier).clear();
      return;
    }

    final ep = episodes.firstWhere((i) => i.number == currentEpisode);
    if (ep.number == null) {
      return;
    }
    if (ep.number == _lastAniSkipEpisode) {
      return;
    }

    _lastAniSkipEpisode = ep.number;

    ref
        .read(aniSkipProvider.notifier)
        .fetchSkipTimes(
          mediaId: mediaId,
          animeTitle: animeName,
          episodeNumber: ep.number!.toInt(),
          episodeLength: duration.inSeconds,
        );
  }

  void _checkAutoSkip(Duration position) {
    final skips = ref.read(aniSkipProvider);
    if (skips.isEmpty) {
      return;
    }

    final settings = ref.read(playerSettingsProvider);
    if (!settings.enableAutoSkip) {
      return;
    }

    for (final skip in skips) {
      if (skip.interval == null) {
        continue;
      }
      final start = Duration(seconds: skip.interval!.startTime.toInt());
      final end = Duration(seconds: skip.interval!.endTime.toInt());

      if (position >= start && position < end) {
        ref.read(playerStateProvider.notifier).seek(end);
        break;
      }
    }
  }

  Future<void> _handleTrackingUpdate(String mediaId, int epNum) async {
    await Future.delayed(const Duration(seconds: 5));

    try {
      final _ = state;
    } catch (_) {
      return;
    }

    final syncNotifier = ref.read(syncSettingsProvider.notifier);
    if (syncNotifier.isManualSync) return;

    final episodes = ref.read(episodeListProvider).episodes;
    if (epNum < 1 || epNum > episodes.length) return;

    final syncSettings = ref.read(syncSettingsProvider);
    if (!syncSettings.askBeforeSync) {
      updateTracking(mediaId: mediaId, episodeNum: epNum);
    }
  }

  Future<void> updateTracking({
    required String mediaId,
    required int episodeNum,
  }) async {
    try {
      final syncNotifier = ref.read(syncSettingsProvider.notifier);
      final List<Future> tasks = [];

      if (syncNotifier.shouldSyncAnilist) {
        tasks.add(
          ref
              .read(anilistServiceProvider)
              .updateUserAnimeList(
                mediaId: int.tryParse(mediaId) ?? 0,
                progress: episodeNum,
                status: 'CURRENT',
              ),
        );
      }

      if (syncNotifier.shouldSyncMal) {
        tasks.add(
          ref
              .read(malServiceProvider)
              .updateUserAnimeList(
                mediaId: int.tryParse(mediaId) ?? 0,
                progress: episodeNum,
                status: 'CURRENT',
              ),
        );
      }

      if (syncNotifier.shouldSyncLocal) {
        final repo = ref.read(watchProgressRepositoryProvider);
        final entry = repo.getProgress(mediaId);

        final media = UniversalMedia(
          id: mediaId,
          title: UniversalTitle(english: entry?.animeTitle ?? 'Unknown'),
          coverImage: UniversalCoverImage(large: entry?.animeCover),
          status: 'UNKNOWN',
          format: entry?.animeFormat,
          episodes: entry?.totalEpisodes,
        );

        final localEntry = await ref
            .read(localTrackerProvider.notifier)
            .getEntry(mediaId);

        tasks.add(
          ref
              .read(localTrackerProvider.notifier)
              .saveEntry(
                media,
                status: 'CURRENT',
                progress: episodeNum,
                score: localEntry?.score ?? 0.0,
                repeat: localEntry?.repeat ?? 0,
                notes: localEntry?.notes ?? '',
                isPrivate: localEntry?.isPrivate ?? false,
                startedAt: localEntry != null ? null : DateTime.now(),
              ),
        );
      }

      if (tasks.isEmpty) {
        AppLogger.w('No sync targets enabled, skipping tracking update');
        return;
      }

      await Future.wait(tasks);
    } catch (e) {
      AppLogger.e('Failed to update tracking', e);
    }
  }
}
