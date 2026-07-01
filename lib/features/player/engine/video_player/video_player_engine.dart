import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/mdk_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/presentation/widgets/video_player/video_player_settings.dart';
import 'package:fvp/fvp.dart';

class VideoPlayerEngine implements VideoEngine {
  VideoPlayerController? _controller;
  final Ref ref;

  static final HTTP _http = HTTP();

  VideoPlayerEngine(this.ref);

  @override
  Future<void> initialize(
    VideoStream stream, {
    SubtitleTrack? subtitle,
    Duration? startAt,
  }) async {
    ref
        .read(videoEngineStateProvider.notifier)
        .updateState(isBuffering: true, isPlaying: false);

    _controller?.removeListener(_listener);
    await _controller?.dispose();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(stream.url),
      httpHeaders: stream.headers ?? {},
      formatHint: await _http.isHLS(stream.url, headers: stream.headers)
          ? VideoFormat.hls
          : null,
    );
    _controller?.addListener(_listener);

    await _controller?.initialize();

    try {
      final mdkPrefs = ref.read(mdkPrefsProvider);
      if (mdkPrefs.decoderPriority != 'Auto') {
        _controller?.setVideoDecoders([mdkPrefs.decoderPriority]);
      }
      _controller?.setBufferRange(
        min: 1000,
        max: mdkPrefs.bufferCapacityMs,
        drop: mdkPrefs.dropFrames,
      );
      if (mdkPrefs.rawConfiguration.isNotEmpty) {
        for (final line in mdkPrefs.rawConfiguration.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.split('=');
          if (parts.length == 2) {
            _controller?.setProperty(parts[0].trim(), parts[1].trim());
          }
        }
      }
    } catch (_) {}

    if (subtitle != null) {
      await setSubtitle(subtitle);
    }
    if (startAt != null && startAt > Duration.zero) {
      await seekTo(startAt);
    }
    await _controller?.play();
  }

  void _listener() {
    final value = _controller?.value;
    if (value == null) return;

    final buffered = value.buffered;
    final bufferDuration = buffered.isNotEmpty
        ? buffered.last.end
        : Duration.zero;

    ref
        .read(videoEngineStateProvider.notifier)
        .updateState(
          position: value.position,
          duration: value.duration,
          buffer: bufferDuration,
          isPlaying: value.isPlaying,
          isBuffering: value.isBuffering || !value.isInitialized,
        );
  }

  @override
  Widget buildVideoView() {
    return Consumer(
      builder: (context, ref, _) {
        final fit = ref.watch(videoEngineStateProvider.select((s) => s.fit));

        if (_controller == null || !_controller!.value.isInitialized) {
          return const ColoredBox(color: Colors.black);
        }

        final size = _controller!.value.size;
        final aspectWidth = size.width > 0 ? size.width : 16.0;
        final aspectHeight = size.height > 0 ? size.height : 9.0;

        return ColoredBox(
          color: Colors.black,
          child: SizedBox.expand(
            child: FittedBox(
              fit: fit,
              child: SizedBox(
                width: aspectWidth,
                height: aspectHeight,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget? buildSettingsView(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return MdkVideoPlayerSettings(controller: _controller!);
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
    try {
      await _controller?.fastSeekTo(position);
    } catch (_) {
      await _controller?.seekTo(position);
    }
  }

  @override
  Future<void> seekRelative(Duration offset) async {
    final current = _controller?.value.position ?? Duration.zero;
    await seekTo(current + offset);
  }

  @override
  Future<void> changeQuality(VideoStream newStream) async {
    final currentPos = _controller?.value.position;
    await initialize(newStream, startAt: currentPos);
  }

  @override
  Future<void> setSubtitle(SubtitleTrack? subtitle) async {
    if (_controller == null) return;
    if (subtitle == null || subtitle.url.isEmpty) {
      _controller!.setSubtitleTracks([]);
      return;
    }
    _controller!.setExternalSubtitle(subtitle.url);
  }

  @override
  Future<void> setSpeed(double speed) async =>
      _controller?.setPlaybackSpeed(speed);

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_listener);
    await _controller?.dispose();
    _controller = null;
  }

  @override
  Duration get currentPosition => _controller?.value.position ?? Duration.zero;

  @override
  Duration get currentDuration => _controller?.value.duration ?? Duration.zero;
}
