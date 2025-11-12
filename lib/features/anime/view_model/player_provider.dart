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
  late final Player? player;
  late final VideoController videoController;

  @override
  PlayerState build() {
    player = Player(
        configuration: const PlayerConfiguration(
      bufferSize: 60 * 1024 * 1024,
    ));
    videoController = VideoController(player!);
    ref.onDispose(() {
      player?.dispose();
    });
    _setupListners();
    return PlayerState.initial();
  }

  void _setupListners() {
    final stream = player?.stream;

    stream?.position.listen((pos) {
      if ((player?.state.duration.inSeconds ?? 0) > 0) {
        state = state.copyWith(position: pos);
      }
    });
    stream?.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });
    stream?.buffering.listen((isBuf) {
      state = state.copyWith(isBuffering: isBuf);
    });
    stream?.playing.listen((isPlay) {
      state = state.copyWith(isPlaying: isPlay);
    });
    stream?.rate.listen((rate) {
      state = state.copyWith(playbackSpeed: rate);
    });
    stream?.subtitle.listen((subtitle) {
      state = state.copyWith(subtitle: subtitle);
    });
    stream?.buffer.listen((buffer) {
      state = state.copyWith(buffer: buffer);
    });
  }

  Future<void> open(String url, Duration? startAt,
      {Map<String, String>? headers}) async {
    await player?.open(Media(url, httpHeaders: headers));
    if (startAt != null) {
      await player?.stream.duration.firstWhere((d) => d > Duration.zero);
      await player?.seek(startAt);
    }
  }

  Future<void> togglePlay() async {
    await (state.isPlaying ? player?.pause() : player?.play());
  }

  Future<void> setSpeed(double speed) async {
    await player?.setRate(speed);
  }

  void setFit(BoxFit newFit) {
    state = state.copyWith(fit: newFit);
  }

  Future<void> play() async {
    await player?.play();
  }

  Future<void> setSubtitle(SubtitleTrack track) async {
    await player?.setSubtitleTrack(track);
  }

  void pause() => player?.pause();
  void seek(Duration pos) => player?.seek(pos);
  void forward(int seconds) => player?.seek(
      Duration(seconds: (player?.state.position.inSeconds ?? 0) + seconds));
}

final playerStateProvider =
    AutoDisposeNotifierProvider<PlayerController, PlayerState>(
        () => PlayerController());
