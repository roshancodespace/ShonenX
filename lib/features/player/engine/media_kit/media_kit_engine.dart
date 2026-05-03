import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/shared/models/video_stream.dart' as stream;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/active_engine_provider.dart';

class MediaKitEngine implements VideoEngine {
  late final Player _player;
  late final VideoController _controller;

  MediaKitPrefs prefs;
  final Ref ref;

  StreamSubscription<Duration>? _positionSubscription;

  Future<void> updatePrefs(MediaKitPrefs newPrefs) async {
    prefs = newPrefs;

    final player = _player.platform;
    if (player is! NativePlayer) return;

    await player.setProperty('audio-channels', prefs.audioChannel.value);
    await player.setProperty('volume-max', '200');
    await _player.setVolume(prefs.boostVolume ? 140 : 100);
  }

  final List<StreamSubscription> _subscriptions = [];

  MediaKitEngine(this.prefs, this.ref) {
    _player = Player();
    _controller = VideoController(_player);
    updatePrefs(prefs);
    
    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        ref.read(engineStateProvider.notifier).updateState(position: pos);
      }),
      _player.stream.duration.listen((dur) {
        ref.read(engineStateProvider.notifier).updateState(duration: dur);
      }),
      _player.stream.buffer.listen((buf) {
        ref.read(engineStateProvider.notifier).updateState(buffer: buf);
      }),
      _player.stream.playing.listen((playing) {
        ref.read(engineStateProvider.notifier).updateState(isPlaying: playing);
      }),
      _player.stream.buffering.listen((buffering) {
        ref.read(engineStateProvider.notifier).updateState(isBuffering: buffering);
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
    return Video(controller: _controller, controls: NoVideoControls);
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
    if (subtitle == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    await _player.setSubtitleTrack(
      SubtitleTrack.uri(subtitle.url, title: subtitle.language),
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
  }

  @override
  Future<void> dispose() async {
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
