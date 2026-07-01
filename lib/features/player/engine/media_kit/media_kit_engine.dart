import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/shared/models/video_stream.dart' as stream;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';

class MediaKitEngine implements VideoEngine {
  late final Player _player;
  late final VideoController _controller;

  MediaKitPrefs prefs;
  final Ref ref;

  bool _disposed = false;

  StreamSubscription<Duration>? _positionSubscription;

  Future<void> updatePrefs(MediaKitPrefs newPrefs) async {
    if (_disposed) return;
    prefs = newPrefs;

    final player = _player.platform;
    if (player is! NativePlayer) return;

    try {
      await player.setProperty('audio-channels', prefs.audioChannel.value);
      if (_disposed) return;
      await player.setProperty('volume-max', '200');
      if (_disposed) return;
      await _player.setVolume(prefs.boostVolume ? 140 : 100);
      if (_disposed) return;

      await player.setProperty('cache-secs', prefs.maxBuffer.inSeconds.toString());
      await player.setProperty('demuxer-readahead-secs', prefs.maxBuffer.inSeconds.toString());

      if (prefs.rawConfiguration.isNotEmpty) {
        for (final line in prefs.rawConfiguration.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.split('=');
          if (parts.length == 2) {
            await player.setProperty(parts[0].trim(), parts[1].trim());
          } else if (parts.length == 1) {
            await player.setProperty(parts[0].trim(), 'yes');
          }
        }
      }
    } catch (_) {}
  }

  final List<StreamSubscription> _subscriptions = [];

  MediaKitEngine(this.prefs, this.ref) {
    _player = Player();
    _controller = VideoController(_player);
    updatePrefs(prefs);

    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(position: pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(duration: dur);
        }
      }),
      _player.stream.buffer.listen((buf) {
        if (!_disposed) {
          ref.read(videoEngineStateProvider.notifier).updateState(buffer: buf);
        }
      }),
      _player.stream.playing.listen((playing) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isPlaying: playing);
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isBuffering: buffering);
        }
      }),
    ]);
  }

  Future<void> _waitUntilReady(Future<void> Function() onReady) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final completer = Completer<void>();
    var handled = false;

    _positionSubscription = _player.stream.position.listen((position) async {
      if (handled || position.inMilliseconds <= 0) return;
      handled = true;

      await _positionSubscription?.cancel();
      _positionSubscription = null;

      try {
        await onReady();
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  @override
  Future<void> initialize(
    stream.VideoStream stream, {
    stream.SubtitleTrack? subtitle,
    Duration? startAt,
  }) async {
    final media = Media(stream.url, httpHeaders: stream.headers);

    await _player.open(media, play: true);

    await _waitUntilReady(() async {
      if (subtitle != null) {
        await setSubtitle(subtitle);
      }
      if (startAt != null) {
        await _player.seek(startAt);
      }
    });
  }

  @override
  Widget buildVideoView() {
    return Consumer(
      builder: (context, ref, _) {
        final fit = ref.watch(videoEngineStateProvider.select((s) => s.fit));
        final subtitlePrefs = ref.watch(subtitlePrefsProvider);
        final screenWidth = MediaQuery.sizeOf(context).width;
        final responsiveFontSize = getResponsiveSubtitleSize(
          screenWidth,
          subtitlePrefs.fontSize,
        );

        return Video(
          controller: _controller,
          controls: NoVideoControls,
          fit: fit,
          subtitleViewConfiguration: SubtitleViewConfiguration(
            padding: EdgeInsets.only(bottom: subtitlePrefs.bottomPadding),
            style: getSubtitleTextStyle(subtitlePrefs, responsiveFontSize),
          ),
        );
      },
    );
  }

  @override
  Widget? buildSettingsView(BuildContext context) => MediaKitSettings();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> seekRelative(Duration offset) async {
    final currentPos = _player.state.position;
    await _player.seek(currentPos + offset);
  }

  @override
  Future<void> changeQuality(stream.VideoStream newStream) async {
    final currentPos = _player.state.position;

    await _player.open(Media(newStream.url, httpHeaders: newStream.headers));
    await _waitUntilReady(() async {
      await _player.seek(currentPos);
      await _player.play();
    });
  }

  @override
  Future<void> setSubtitle(stream.SubtitleTrack? subtitle) async {
    if (subtitle == null || subtitle.url.isEmpty) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
    } else {
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(subtitle.url, language: subtitle.language),
      );
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _positionSubscription?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _player.dispose();
  }

  @override
  Duration get currentPosition => _player.state.position;

  @override
  Duration get currentDuration => _player.state.duration;
}
