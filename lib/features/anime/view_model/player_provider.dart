import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerState {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool isPlaying;
  final bool isBuffering;
  final double playbackSpeed;
  final List<String> subtitle;
  final BoxFit fit;

  PlayerState({
    required this.position,
    required this.duration,
    required this.buffer,
    required this.isPlaying,
    required this.isBuffering,
    required this.playbackSpeed,
    required this.subtitle,
    required this.fit,
  });

  PlayerState copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffer,
    bool? isPlaying,
    bool? isBuffering,
    double? playbackSpeed,
    List<String>? subtitle,
    BoxFit? fit,
  }) {
    return PlayerState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      subtitle: subtitle ?? this.subtitle,
      fit: fit ?? this.fit,
    );
  }

  static PlayerState initial() => PlayerState(
        position: Duration.zero,
        duration: Duration.zero,
        buffer: Duration.zero,
        isPlaying: false,
        isBuffering: false,
        playbackSpeed: 1.0,
        subtitle: [],
        fit: BoxFit.contain,
      );
}

class PlayerController extends AutoDisposeNotifier<PlayerState> {
  late final Player player;
  late final VideoController videoController;
  final List<StreamSubscription> _subs = [];

  @override
  PlayerState build() {
    player = Player(
        configuration: const PlayerConfiguration(
      bufferSize: 32 * 1024 * 1024,
      logLevel: MPVLogLevel.v,
    ));

    videoController = VideoController(player,
        configuration: VideoControllerConfiguration(
          androidAttachSurfaceAfterVideoParameters:
              Platform.isAndroid ? true : null,
        ));
    ref.onDispose(() {
      player.dispose();
      videoController.notifier.dispose();
    });
    _setupListners();
    return PlayerState.initial();
  }

  void _setupListners() {
    final stream = player.stream;

    _subs.add(stream.position.listen((pos) {
      if (player.state.duration > Duration.zero) {
        state = state.copyWith(position: pos);
      }
    }));

    _subs.add(stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    }));

    _subs.add(stream.buffering.listen((isBuf) {
      state = state.copyWith(isBuffering: isBuf);
    }));

    _subs.add(stream.playing.listen((isPlay) {
      state = state.copyWith(isPlaying: isPlay);
    }));

    _subs.add(stream.rate.listen((rate) {
      state = state.copyWith(playbackSpeed: rate);
    }));

    _subs.add(stream.subtitle.listen((subtitle) {
      state = state.copyWith(subtitle: subtitle);
    }));

    _subs.add(stream.buffer.listen((buffer) {
      state = state.copyWith(buffer: buffer);
    }));

    ref.onDispose(() {
      for (final sub in _subs) {
        sub.cancel();
      }
    });
  }

  Future<void> open(String url, Duration? startAt,
      {Map<String, String>? headers}) async {
    await player.open(Media(url, httpHeaders: headers));
    if (startAt != null) {
      try {
        await player.stream.duration
            .firstWhere((d) => d > Duration.zero)
            .timeout(const Duration(seconds: 10));
        await player.seek(startAt);
      } catch (e) {
        // AppLogger.w("Failed to seek to start position: $e");
      }
    }
  }

  Future<void> togglePlay() async {
    if (player.state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> setSpeed(double speed) async {
    await player.setRate(speed);
  }

  void setFit(BoxFit newFit) {
    state = state.copyWith(fit: newFit);
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> setSubtitle(SubtitleTrack track) async {
    await player.setSubtitleTrack(track);
  }

  void pause() => player.pause();
  void seek(Duration pos) => player.seek(pos);
  void forward(int seconds) => player
      .seek(Duration(seconds: (player.state.position.inSeconds) + seconds));
  void rewind(int seconds) {
    final current = player.state.position;
    final target = current - Duration(seconds: seconds);
    player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void volumeUp() => player.setVolume((player.state.volume + 10).clamp(0, 100));
  void volumeDown() =>
      player.setVolume((player.state.volume - 10).clamp(0, 100));
  void toggleMute() => player.setVolume(player.state.volume == 0 ? 100 : 0);

  Future<Uint8List?> getThumbnail() async {
    return await player.platform?.screenshot(
      format: 'image/png',
    );
  }
}

final playerStateProvider =
    AutoDisposeNotifierProvider<PlayerController, PlayerState>(
        () => PlayerController());
