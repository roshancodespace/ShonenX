import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/repositories/interfaces/watch_progress_repository_interface.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

part 'watch_progress_notifier.g.dart';

@riverpod
class WatchProgressNotifier extends _$WatchProgressNotifier {
  WatchProgressRepositoryInterface? _repo;
  ScreenshotController? _screenshotController;
  int _lastSavedPos = -1;

  @override
  void build() {
    _repo = ref.read(watchProgressRepositoryProvider);
  }

  void setScreenshotController(ScreenshotController controller) {
    _screenshotController = controller;
  }

  Future<String?> captureScreenshot() async {
    if (_screenshotController == null) return null;
    try {
      final bytes = await _screenshotController!.capture(pixelRatio: 0.5);
      return bytes != null ? base64Encode(bytes) : null;
    } catch (_) {
      return null;
    }
  }

  /// Reset the internal last saved position when changing episodes
  void resetLastSavedPosition() {
    _lastSavedPos = -1;
  }

  Future<String?> saveProgress({
    required String mediaId,
    required String animeName,
    required String? animeFormat,
    required String animeCover,
    required int totalEps,
    required int epNum,
    required String? epTitle,
    String? epThumb,
    required int pos,
    required int dur,
    bool takeScreenshot = false,
  }) async {
    if (_repo == null || dur <= 0 || pos <= 0 || pos == _lastSavedPos) {
      return epThumb;
    }

    String? currentThumb = epThumb;

    try {
      if (takeScreenshot) {
        final thumb = await captureScreenshot();
        if (thumb != null) currentThumb = thumb;
      }

      final entry = _repo!.getProgress(mediaId) ??
          AnimeWatchProgressEntry(
            animeId: mediaId,
            animeTitle: animeName,
            animeFormat: animeFormat,
            animeCover: animeCover,
            totalEpisodes: totalEps,
          );

      final progress = EpisodeProgress(
        episodeNumber: epNum,
        episodeTitle: epTitle ?? 'Episode $epNum',
        episodeThumbnail: currentThumb,
        progressInSeconds: pos,
        durationInSeconds: dur,
        isCompleted: dur > 0 ? (pos / dur > 0.85) : false,
        watchedAt: DateTime.now(),
      );

      await _repo!.saveProgress(entry);
      await _repo!.updateEpisodeProgress(mediaId, progress);

      _lastSavedPos = pos;
    } catch (e) {
      AppLogger.e('WatchProgressNotifier: Save failed', e);
    }
    
    return currentThumb;
  }
}
