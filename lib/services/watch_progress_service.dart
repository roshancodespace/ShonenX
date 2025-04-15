import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/services/thumbnail_service.dart';

/// Service responsible for managing watch progress
class WatchProgressService {
  final AnimeWatchProgressBox _animeWatchProgressBox = AnimeWatchProgressBox();
  final ThumbnailService _thumbnailService = ThumbnailService();
  Timer? _saveProgressTimer;
  static const Duration _progressSaveInterval = Duration(seconds: 10);

  /// Initialize the service
  Future<void> initialize() async {
    await _animeWatchProgressBox.init();
  }

  /// Start the progress saving timer
  void startProgressTimer(VoidCallback saveCallback) {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer.periodic(_progressSaveInterval, (_) {
      saveCallback();
    });
  }

  /// Stop the progress saving timer
  void stopProgressTimer() {
    _saveProgressTimer?.cancel();
  }

  /// Check if progress should be saved based on current state
  bool shouldSaveProgress(WatchState watchState, PlayerState playerState) {
    final hasValidEpisode = watchState.selectedEpisodeIdx != null &&
        watchState.episodes.isNotEmpty &&
        watchState.selectedEpisodeIdx! < watchState.episodes.length;
    final hasValidDuration = playerState.duration.inSeconds >= 10;
    final hasValidPosition = playerState.position.inSeconds >= 10;
    final isPositionValid = playerState.position <= playerState.duration;

    log("Should save progress check: "
        "validEpisode=$hasValidEpisode, "
        "validDuration=$hasValidDuration, "
        "validPosition=$hasValidPosition, "
        "positionValid=$isPositionValid");

    return hasValidEpisode &&
        hasValidDuration &&
        hasValidPosition &&
        isPositionValid;
  }

  /// Save the current watch progress
  Future<void> saveProgress({
    required anilist_media.Media animeMedia,
    required WidgetRef ref,
    required Function(String) onError,
  }) async {
    final watchState = ref.read(watchProvider);
    final playerState = ref.read(playerStateProvider);
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;
    if (!shouldSaveProgress(watchState, playerState)) {
      log("Skipping progress save - conditions not met");
      return;
    }

    try {
      final episodeIdx = watchState.selectedEpisodeIdx!;
      final episode = watchState.episodes[episodeIdx];
      final progress = playerState.position;
      final duration = playerState.duration;

      if (episode.number == null) {
        log("Episode number is null, cannot save progress");
        return;
      }

      final thumbnailBase64 =
          await _thumbnailService.generateThumbnail(ref.read(playerProvider));

      log("Thumbnail generated: length=${thumbnailBase64.length}, "
          "startsWith=${thumbnailBase64.substring(0, 20)}...");

      // Validate thumbnail
      if (thumbnailBase64.isEmpty) {
        log("ERROR: Thumbnail is empty");
        onError('Thumbnail generation failed, using fallback');
      }

      final isCompleted = progress.inSeconds >=
          (duration.inSeconds * playerSettings.episodeCompletionThreshold);

      log("Saving progress for episode ${episode.number} - "
          "Progress: ${progress.inSeconds}s / ${duration.inSeconds}s, "
          "Thumbnail length: ${thumbnailBase64.length}");

      await _animeWatchProgressBox.updateEpisodeProgress(
        animeMedia: animeMedia,
        episodeNumber: episode.number!,
        episodeTitle: episode.title ?? 'Episode ${episode.number}',
        episodeThumbnail: thumbnailBase64,
        progressInSeconds: progress.inSeconds,
        durationInSeconds: duration.inSeconds,
        isCompleted: isCompleted,
      );

      log("Progress saved successfully");
    } catch (e, stackTrace) {
      log("Error saving progress: $e\n$stackTrace");
      onError('Failed to save progress: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    stopProgressTimer();
  }
}
