import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/myanimelist/services/mal_service_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/main.dart';

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
    required int initialEpisodeIndex,
    required Duration startAt,
    required String mediaId,
    required String animeFormat,
    required String animeCover,
  }) async {
    // 1. Fetch Episodes
    await ref
        .read(episodeListProvider.notifier)
        .fetchEpisodes(
          animeTitle: animeName,
          animeId: animeId,
          episodes: episodes,
          force: false,
        );

    // 2. Load Initial Episode
    await ref
        .read(episodeDataProvider.notifier)
        .loadEpisode(epIdx: initialEpisodeIndex, startAt: startAt);

    // 3. Start Progress Tracking
    _startProgressTimer(mediaId, animeName, animeFormat, animeCover);

    // 4. Attach Listeners (only once)
    if (!_playbackListenerAttached) {
      _attachPlaybackListeners(mediaId, animeName);
      _playbackListenerAttached = true;
    }
  }

  void _startProgressTimer(
    String mediaId,
    String animeName,
    String animeFormat,
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
    required String animeFormat,
    required String animeCover,
    bool takeScreenshot = false,
  }) async {
    try {
      final player = ref.read(playerStateProvider);
      final episodeData = ref.read(episodeDataProvider);
      final episodes = ref.read(episodeListProvider).episodes;
      final repo = ref.read(watchProgressRepositoryProvider);

      final idx = episodeData.selectedEpisodeIdx;
      if (idx == null || idx < 0 || idx >= episodes.length) {
        return;
      }

      final ep = episodes[idx];
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
          .getEpisodeProgress(mediaId, ep.number ?? idx + 1)
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
    ref.listen(episodeDataProvider.select((p) => p.selectedEpisodeIdx), (
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
    final currentIndex = ref.read(episodeDataProvider).selectedEpisodeIdx;

    if (currentIndex == null ||
        currentIndex < 0 ||
        currentIndex >= episodes.length) {
      return;
    }

    AppLogger.d(
      'Checking AniSkip for episode ${episodes[currentIndex].number}',
    );

    final settings = ref.read(playerSettingsProvider);
    if (!settings.enableAniSkip) {
      ref.read(aniSkipProvider.notifier).clear();
      return;
    }

    final ep = episodes[currentIndex];
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

  Future<void> _handleTrackingUpdate(String mediaId, int episodeIdx) async {
    // Delay to ensure user is actually watching
    await Future.delayed(const Duration(seconds: 5));

    try {
      final _ = state;
    } catch (_) {
      return;
    }

    final episodes = ref.read(episodeListProvider).episodes;
    if (episodeIdx < 0 || episodeIdx >= episodes.length) {
      return;
    }

    final ep = episodes[episodeIdx];
    final episodeNum = ep.number?.toInt() ?? (episodeIdx + 1);

    final askToUpdate =
        sharedPrefs.getBool('tracking_ask_update_on_start') ?? false;

    if (!askToUpdate) {
      updateTracking(mediaId: mediaId, episodeNum: episodeNum);
    }
  }

  Future<void> updateTracking({
    required String mediaId,
    required int episodeNum,
  }) async {
    try {
      final auth = ref.read(authProvider);
      final syncAnilist = sharedPrefs.getBool('tracking_sync_anilist') ?? true;
      final syncMal = sharedPrefs.getBool('tracking_sync_mal') ?? true;

      final canSyncAnilist = auth.isAniListAuthenticated && syncAnilist;
      final canSyncMal = auth.isMalAuthenticated && syncMal;

      if (!canSyncAnilist && !canSyncMal) {
        // Fallback to local
        final repo = ref.read(watchProgressRepositoryProvider);
        final entry = repo.getProgress(mediaId);

        // Try to construct UniversalMedia from local progress if needed
        final media = UniversalMedia(
          id: mediaId,
          title: UniversalTitle(english: entry?.animeTitle ?? 'Unknown'),
          coverImage: UniversalCoverImage(large: entry?.animeCover),
          status: 'UNKNOWN', // Placeholder
          format: entry?.animeFormat,
          episodes: entry?.totalEpisodes,
        );

        // Fetch existing local entry to preserve score/notes
        final localEntry = await ref
            .read(localTrackerProvider.notifier)
            .getEntry(mediaId);

        await ref
            .read(localTrackerProvider.notifier)
            .saveEntry(
              media,
              status: 'CURRENT',
              progress: episodeNum,
              score: localEntry?.score ?? 0.0,
              repeat: localEntry?.repeat ?? 0,
              notes: localEntry?.notes ?? '',
              isPrivate: localEntry?.isPrivate ?? false,
              startedAt: localEntry != null
                  ? null
                  : DateTime.now(), // Set start only if new
            );
        return;
      }

      final List<Future> tasks = [];

      if (canSyncAnilist) {
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

      if (canSyncMal) {
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

      await Future.wait(tasks);
    } catch (e) {
      AppLogger.e('Failed to update tracking', e);
    }
  }
}
