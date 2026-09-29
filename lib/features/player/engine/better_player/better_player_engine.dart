import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:shonenx/features/player/providers/better_player_prefs_provider.dart';

class BetterPlayerEngine implements VideoEngine {
  static final _log = AppLogger.scope('BetterPlayerEngine');

  BetterPlayerController? _controller;
  BetterPlayerPrefsState _prefs;

  VideoStream? _currentStream;
  SubtitleTrack? _currentSubtitle;

  @override
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  @override
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  @override
  final ValueNotifier<Duration> bufferNotifier = ValueNotifier(Duration.zero);
  @override
  final ValueNotifier<PlayerStatus> statusNotifier = ValueNotifier(
    PlayerStatus.idle,
  );
  @override
  final ValueNotifier<List<SubtitleTrack>> subtitleTracksNotifier =
      ValueNotifier([]);
  @override
  final ValueNotifier<List<AudioTrack>> audioTracksNotifier = ValueNotifier([]);
  @override
  final ValueNotifier<SubtitleTrack?> activeSubtitleNotifier = ValueNotifier(
    null,
  );
  @override
  final ValueNotifier<AudioTrack?> activeAudioNotifier = ValueNotifier(null);

  BetterPlayerEngine(this._prefs);

  Future<void> updatePrefs(BetterPlayerPrefsState prefs) async {
    final needsRefresh =
        _prefs.enableCache != prefs.enableCache ||
        _prefs.maxCacheSizeMb != prefs.maxCacheSizeMb ||
        _prefs.useAsmsSubtitles != prefs.useAsmsSubtitles ||
        _prefs.useAsmsAudioTracks != prefs.useAsmsAudioTracks;
    _prefs = prefs;

    if (needsRefresh) {
      await refresh();
    }
  }

  Future<BetterPlayerVideoFormat> detectVideoFormat(
    String url, {
    Map<String, String>? headers,
  }) async {
    final cleanPath = url.split('?').first.split('#').first.toLowerCase();

    if (cleanPath.endsWith('.mpd')) {
      return BetterPlayerVideoFormat.dash;
    } else if (cleanPath.endsWith('.m3u8') || cleanPath.endsWith('.m3u')) {
      return BetterPlayerVideoFormat.hls;
    } else if (cleanPath.endsWith('.ism') || cleanPath.endsWith('.isml')) {
      return BetterPlayerVideoFormat.ss;
    }

    if (_detectDataSourceType(url) == BetterPlayerDataSourceType.network) {
      try {
        final response = await HTTP().head(url, headers: headers);
        final contentType = response.headers?['content-type']?.toLowerCase();

        if (contentType != null) {
          if (contentType.contains('mpegurl') ||
              contentType.contains('x-mpegurl')) {
            return BetterPlayerVideoFormat.hls;
          } else if (contentType.contains('dash+xml')) {
            return BetterPlayerVideoFormat.dash;
          } else if (contentType.contains('vnd.ms-sstr+xml')) {
            return BetterPlayerVideoFormat.ss;
          }
        }
      } catch (_) {
        // Fallback or ignore
      }
    }

    return BetterPlayerVideoFormat.other;
  }

  BetterPlayerDataSourceType _detectDataSourceType(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return BetterPlayerDataSourceType.network;
      } else if (uri.scheme == 'file') {
        return BetterPlayerDataSourceType.file;
      }
    }
    if (url.startsWith('/')) {
      return BetterPlayerDataSourceType.file;
    }
    return BetterPlayerDataSourceType.network;
  }

  @override
  Future<void> initialize(
    VideoStream stream, {
    SubtitleTrack? subtitle,
    Duration? startAt,
  }) async {
    _currentStream = stream;
    _currentSubtitle = subtitle;
    statusNotifier.value = PlayerStatus.loading;

    _log.i('Initializing player with URL: ${stream.url}');
    _controller?.removeEventsListener(_listener);
    _controller?.dispose();

    final headers = <String, String>{...?stream.headers};

    List<BetterPlayerSubtitlesSource> subtitles = [];
    if (subtitle != null &&
        subtitle.url.isNotEmpty &&
        !subtitle.url.startsWith('internal:')) {
      subtitles.add(
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          urls: [subtitle.url],
          selectedByDefault: true,
        ),
      );
    }

    final dataSourceType = _detectDataSourceType(stream.url);
    final videoFormat = await detectVideoFormat(stream.url, headers: headers);

    final dataSource = BetterPlayerDataSource(
      dataSourceType,
      stream.url,
      videoFormat: videoFormat,
      headers: headers,
      subtitles: subtitles,
      useAsmsSubtitles: _prefs.useAsmsSubtitles,
      useAsmsAudioTracks: _prefs.useAsmsAudioTracks,
      cacheConfiguration: _prefs.enableCache
          ? BetterPlayerCacheConfiguration(
              useCache: true,
              maxCacheSize: _prefs.maxCacheSizeMb * 1024 * 1024,
              maxCacheFileSize: _prefs.maxCacheSizeMb * 1024 * 1024,
            )
          : const BetterPlayerCacheConfiguration(useCache: false),
    );

    final config = BetterPlayerConfiguration(
      autoPlay: true,
      startAt: startAt,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
      ),
      fit: BoxFit.contain,
    );

    _controller = BetterPlayerController(config);
    _controller?.setupDataSource(dataSource);
    _controller?.addEventsListener(_listener);
  }

  void _listener(BetterPlayerEvent event) {
    if (_controller == null) return;

    final value = _controller!.videoPlayerController?.value;
    if (value == null) return;

    final buffered = value.buffered;
    final bufferDuration = buffered.isNotEmpty
        ? buffered.last.end
        : Duration.zero;

    List<AudioTrack>? parsedAudioTracks;
    final availableTracks = _controller!.betterPlayerAsmsAudioTracks;
    if (availableTracks != null && availableTracks.isNotEmpty) {
      parsedAudioTracks = [AudioTrack.auto];
      parsedAudioTracks.addAll(
        availableTracks.map((t) {
          return AudioTrack(
            id: t.id?.toString() ?? t.label ?? t.language ?? 'unknown',
            label: t.label ?? t.language ?? 'Unknown Track',
            language: t.language,
          );
        }),
      );
    }

    AudioTrack? parsedActiveAudioTrack;
    final activeAsms = _controller!.betterPlayerAsmsAudioTrack;
    if (activeAsms != null) {
      parsedActiveAudioTrack = AudioTrack(
        id:
            activeAsms.id?.toString() ??
            activeAsms.label ??
            activeAsms.language ??
            'unknown',
        label: activeAsms.label ?? activeAsms.language ?? 'Unknown Track',
        language: activeAsms.language,
      );
    }

    positionNotifier.value = value.position;
    durationNotifier.value = value.duration ?? Duration.zero;
    bufferNotifier.value = bufferDuration;

    if (value.hasError) {
      statusNotifier.value = PlayerStatus.error;
    } else if (value.isBuffering || !value.initialized) {
      statusNotifier.value = PlayerStatus.buffering;
    } else if (value.isPlaying) {
      statusNotifier.value = PlayerStatus.playing;
    } else {
      statusNotifier.value = PlayerStatus.paused;
    }

    if (parsedAudioTracks != null) {
      audioTracksNotifier.value = parsedAudioTracks;
    }
    activeAudioNotifier.value = parsedActiveAudioTrack;
  }

  @override
  Future<void> refresh() async {
    if (_currentStream == null) return;
    _log.i('Refreshing BetterPlayerEngine');

    final currentPos = currentPosition;
    await initialize(
      _currentStream!,
      subtitle: _currentSubtitle,
      startAt: currentPos,
    );
  }

  @override
  Widget buildVideoView({BoxFit fit = BoxFit.contain}) {
    if (_controller == null ||
        _controller!.videoPlayerController == null ||
        !_controller!.videoPlayerController!.value.initialized) {
      return const ColoredBox(color: Colors.black);
    }

    // Apply fit
    _controller!.setOverriddenFit(fit);

    return ColoredBox(
      color: Colors.black,
      child: BetterPlayer(controller: _controller!),
    );
  }

  @override
  Future<void> play() async {
    return _controller?.play();
  }

  @override
  Future<void> pause() async {
    return _controller?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> seekRelative(Duration offset) async {
    final current =
        _controller?.videoPlayerController?.value.position ?? Duration.zero;
    await seekTo(current + offset);
  }

  @override
  Future<void> changeQuality(VideoStream newStream) async {
    _log.i('Changing quality to URL: \${newStream.url}');
    final currentPos = _controller?.videoPlayerController?.value.position;
    await initialize(newStream, startAt: currentPos);
  }

  @override
  Future<void> setSubtitle(SubtitleTrack? subtitle) async {
    if (_controller == null) return;
    if (subtitle == null || subtitle.url.isEmpty) {
      _log.d('Disabling subtitle');
      _controller?.setupSubtitleSource(
        BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
      );
      return;
    }
    if (subtitle.url.startsWith('internal:')) {
      _log.d('Internal subtitles are not supported in BetterPlayerEngine');
      return;
    }

    _log.d('Setting subtitle: \${subtitle.url}');
    _controller?.setupSubtitleSource(
      BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.network,
        urls: [subtitle.url],
        selectedByDefault: true,
      ),
    );
  }

  @override
  Future<void> setAudioTrack(AudioTrack track) async {
    if (_controller == null) return;

    final availableTracks = _controller!.betterPlayerAsmsAudioTracks;
    if (availableTracks == null || availableTracks.isEmpty) return;

    if (track == AudioTrack.auto) {
      _controller!.setAudioTrack(availableTracks.first);
      return;
    }

    final trackToSelect = availableTracks.firstWhere(
      (t) =>
          t.id?.toString() == track.id ||
          t.label == track.label ||
          t.language == track.language,
      orElse: () => availableTracks.first,
    );

    _controller!.setAudioTrack(trackToSelect);
    _log.i(
      'Set audio track to: ${trackToSelect.label ?? trackToSelect.language}',
    );
  }

  @override
  Future<void> setSpeed(double speed) async => _controller?.setSpeed(speed);

  @override
  Future<void> dispose() async {
    _log.i('Disposing engine');
    _controller?.removeEventsListener(_listener);
    _controller?.dispose();
    _controller = null;

    positionNotifier.dispose();
    durationNotifier.dispose();
    bufferNotifier.dispose();
    statusNotifier.dispose();
    subtitleTracksNotifier.dispose();
    audioTracksNotifier.dispose();
    activeSubtitleNotifier.dispose();
    activeAudioNotifier.dispose();
  }

  @override
  Duration get currentPosition =>
      _controller?.videoPlayerController?.value.position ?? Duration.zero;

  @override
  Duration get currentDuration =>
      _controller?.videoPlayerController?.value.duration ?? Duration.zero;
}
