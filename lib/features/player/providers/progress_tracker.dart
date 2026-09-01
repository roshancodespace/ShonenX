import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

// Holds current media info passed to ProgressTracker on each save tick.
class ProgressContext {
  final UnifiedMedia? media;
  final UnifiedEpisode? activeEpisode;
  final VideoServer? activeServer;
  final SourceInfo? sourceInfo;

  const ProgressContext({
    this.media,
    this.activeEpisode,
    this.activeServer,
    this.sourceInfo,
  });
}

// Handles periodic watch history saves and thumbnail generation.
class ProgressTracker {
  final Ref _ref;

  Timer? _progressTimer;
  ScreenshotController? _screenshotController;

  ProgressContext Function()? _contextProvider;

  // Cache thumbnail and refresh every 2 mins to avoid heavy screenshot captures
  String? _cachedThumbnail;
  DateTime? _lastThumbnailTime;
  bool _initialCaptureDone = false;
  static const _thumbnailRefreshInterval = Duration(minutes: 2);

  ProgressTracker(this._ref);

  void setScreenshotController(ScreenshotController controller) {
    _screenshotController = controller;
  }

  // Save progress every 5 seconds using context from the provider callback.
  void start(ProgressContext Function() contextProvider) {
    _contextProvider = contextProvider;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async => await _saveCurrentProgress(),
    );
  }

  void cancel() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void resetThumbnail() {
    _cachedThumbnail = null;
    _lastThumbnailTime = null;
    _initialCaptureDone = false;
  }

  // Captures one final thumbnail and updates history before player closes.
  Future<void> captureExitThumbnail({
    required UnifiedMedia? media,
    required UnifiedEpisode? activeEpisode,
    required VideoServer? activeServer,
    required SourceInfo? sourceInfo,
  }) async {
    await _captureThumbnail();
    await _saveCurrentProgress(
      skipCapture: true,
      ctx: ProgressContext(
        media: media,
        activeEpisode: activeEpisode,
        activeServer: activeServer,
        sourceInfo: sourceInfo,
      ),
    );
  }

  Future<void> _saveCurrentProgress({
    bool skipCapture = false,
    ProgressContext? ctx,
  }) async {
    if (!_ref.mounted) {
      cancel();
      return;
    }

    // Use provided context or fetch from the controller
    final context = ctx ?? _contextProvider?.call();
    if (context == null) return;

    final media = context.media;
    final activeEpisode = context.activeEpisode;
    final activeServer = context.activeServer;
    final sourceInfo = context.sourceInfo;

    if (activeServer == null || media == null) return;
    if (_ref.read(securityPrefsProvider).incognitoMode) return;

    final engine = _ref.read(videoEngineProvider);
    final position = engine.currentPosition;
    final duration = engine.currentDuration;

    // Don't save if the player hasn't started playing yet
    if (position == Duration.zero || duration == Duration.zero) return;

    // Capture thumbnail only when enough time has elapsed
    if (!skipCapture && _shouldCaptureThumbnail) {
      await _captureThumbnail();
      _initialCaptureDone = true;
    }

    final thumbnail = _cachedThumbnail ?? '';

    // Build a watch history entry with all the metadata
    final entry = WatchHistoryEntry()
      ..episodeNumber = activeEpisode?.number ?? 1
      ..totalEpisodes = media.episodes
      ..animeId = media.id
      ..animeIdMal = media.idMal
      ..externalIds = media.externalIds
      ..animeTitle = media.title.availableTitle
      ..episodeTitle = activeEpisode?.title
      ..cover = media.cover
      ..banner = media.banner
      ..thumbnailUrl = thumbnail.isNotEmpty
          ? thumbnail
          : activeEpisode?.thumbnailUrl
      ..positionInMilliseconds = position.inMilliseconds
      ..durationInMilliseconds = duration.inMilliseconds
      ..sourceId = sourceInfo?.id ?? media.sourceId
      ..sourceName = sourceInfo?.name ?? media.sourceName
      ..providerId = media.providerId != media.id ? media.providerId : null
      ..lastUpdated = DateTime.now();

    _ref.read(watchHistoryRepositoryProvider).saveProgress(entry);

    // Also sync to tracking services (MAL, AniList, etc.)
    if (activeEpisode != null) {
      _ref
          .read(syncEngineProvider)
          .processPlayback(
            media: media,
            episodeNumber: activeEpisode.number,
            position: position,
            duration: duration,
          );
    }
  }

  bool get _shouldCaptureThumbnail {
    if (!_initialCaptureDone) return true;
    if (_lastThumbnailTime == null) return true;
    return DateTime.now().difference(_lastThumbnailTime!) >=
        _thumbnailRefreshInterval;
  }

  Future<String?> _captureThumbnail() async {
    if (_screenshotController == null) return _cachedThumbnail;
    try {
      final image = await _screenshotController!.capture(pixelRatio: 0.5);
      if (image != null) {
        _cachedThumbnail = base64Encode(image);
        _lastThumbnailTime = DateTime.now();
      }
    } catch (_) {}
    return _cachedThumbnail;
  }
}
