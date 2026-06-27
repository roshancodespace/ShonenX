import 'dart:async';
import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/shared/models/video_stream.dart';

class BetterPlayerEngine implements VideoEngine {
  late final BetterPlayerController _controller;
  final Ref ref;

  bool _isBuffering = false;
  Timer? _progressTimer;

  static final HTTP _http = HTTP();

  BetterPlayerEngine(this.ref) {
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        autoPlay: true,
        autoDispose: false,
        fit: BoxFit.contain,
      ),
    );
    _attachEventListener();
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final value = _controller.videoPlayerController?.value;
      if (value == null) return;

      final buffered = value.buffered;
      final bufferDuration = buffered.isNotEmpty
          ? buffered.last.end
          : Duration.zero;

      if (value.isBuffering != _isBuffering) {
        _isBuffering = value.isBuffering;
      }

      ref
          .read(videoEngineStateProvider.notifier)
          .updateState(
            position: value.position,
            duration: value.duration,
            buffer: bufferDuration,
            isBuffering: _isBuffering,
          );
    });
  }

  void _attachEventListener() {
    _controller.addEventsListener((event) {
      switch (event.betterPlayerEventType) {
        case BetterPlayerEventType.initialized:
          _isBuffering = false;
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isBuffering: false);
          _emitState();
          break;
        case BetterPlayerEventType.play:
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isPlaying: true);
          break;
        case BetterPlayerEventType.pause:
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isPlaying: false);
          break;
        case BetterPlayerEventType.bufferingStart:
          _isBuffering = true;
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isBuffering: true);
          break;
        case BetterPlayerEventType.bufferingEnd:
          _isBuffering = false;
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isBuffering: false);
          _emitState();
          break;
        case BetterPlayerEventType.finished:
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isPlaying: false);
          break;
        default:
          break;
      }
    });
  }

  void _emitState() {
    final value = _controller.videoPlayerController?.value;
    if (value == null) return;

    final buffered = value.buffered;

    ref
        .read(videoEngineStateProvider.notifier)
        .updateState(
          position: value.position,
          duration: value.duration,
          buffer: buffered.isNotEmpty ? buffered.last.end : Duration.zero,
          isPlaying: value.isPlaying,
        );
  }

  @override
  Future<void> initialize(
    VideoStream stream, {
    SubtitleTrack? subtitle,
    Duration? startAt,
  }) async {
    _isBuffering = false;

    _controller.pause();

    ref.read(videoEngineStateProvider.notifier).updateState(isBuffering: false);

    await _controller.setupDataSource(
      BetterPlayerDataSource.network(
        stream.url,
        headers: stream.headers,
        videoFormat: await _http.isHLS(stream.url, headers: stream.headers)
            ? BetterPlayerVideoFormat.hls
            : null,
        cacheConfiguration: BetterPlayerCacheConfiguration(useCache: true),
      ),
    );

    if (startAt != null && startAt > Duration.zero) {
      await _controller.seekTo(startAt);
    }

    await _controller.play();
    _emitState();
  }

  @override
  Widget buildVideoView() {
    return Consumer(
      builder: (context, ref, _) {
        final fit = ref.watch(videoEngineStateProvider.select((s) => s.fit));
        _controller.setOverriddenFit(fit);
        return BetterPlayer(controller: _controller);
      },
    );
  }

  @override
  Widget? buildSettingsView(BuildContext context) => null;

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> seekRelative(Duration offset) {
    final pos =
        _controller.videoPlayerController?.value.position ?? Duration.zero;
    return _controller.seekTo(pos + offset);
  }

  @override
  Future<void> changeQuality(VideoStream newStream) async {
    final pos = _controller.videoPlayerController?.value.position;
    final wasPlaying =
        _controller.videoPlayerController?.value.isPlaying ?? false;
    final speed = _controller.videoPlayerController?.value.speed ?? 1.0;

    await _controller.setupDataSource(
      BetterPlayerDataSource.network(newStream.url, headers: newStream.headers),
    );

    if (pos != null) await _controller.seekTo(pos);
    await _controller.setSpeed(speed);
    if (wasPlaying) await _controller.play();
    _emitState();
  }

  @override
  Future<void> setSubtitle(SubtitleTrack? subtitle) async {
    if (subtitle == null) {
      return _controller.setupSubtitleSource(
        BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
      );
    }
    return _controller.setupSubtitleSource(
      BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.network,
        urls: [subtitle.url],
        name: subtitle.language,
      ),
    );
  }

  @override
  Future<void> setSpeed(double speed) => _controller.setSpeed(speed);

  @override
  Future<void> dispose() async {
    _progressTimer?.cancel();
    try {
      _controller.pause();
      _controller.videoPlayerController?.pause();
      _controller.dispose(forceDispose: true);
    } catch (_) {}
  }

  @override
  Duration get currentPosition =>
      _controller.videoPlayerController?.value.position ?? Duration.zero;

  @override
  Duration get currentDuration =>
      _controller.videoPlayerController?.value.duration ?? Duration.zero;
}
