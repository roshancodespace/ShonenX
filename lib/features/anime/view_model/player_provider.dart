import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/core/providers/settings/player_notifier.dart';

part 'player_provider.g.dart';

@immutable
class PlayerState {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool isPlaying;
  final bool isBuffering;
  final double playbackSpeed;
  final List<String> subtitle;
  final BoxFit fit;

  const PlayerState({
    required this.position,
    required this.duration,
    required this.buffer,
    required this.isPlaying,
    required this.isBuffering,
    required this.playbackSpeed,
    required this.subtitle,
    required this.fit,
  });

  factory PlayerState.initial() => const PlayerState(
    position: Duration.zero,
    duration: Duration.zero,
    buffer: Duration.zero,
    isPlaying: false,
    isBuffering: false,
    playbackSpeed: 1.0,
    subtitle: [],
    fit: BoxFit.contain,
  );

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
}

@riverpod
class PlayerStateNotifier extends _$PlayerStateNotifier {
  late final Player _player;
  late final VideoController videoController;
  final List<StreamSubscription> _subs = [];

  Player get player => _player;

  @override
  PlayerState build() {
    final settings = ref.read(playerSettingsProvider);
    final mpvSettings = settings.mpvSettings;
    final vo = mpvSettings['vo'];

    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024,
        logLevel: MPVLogLevel.v,
        vo: vo,
      ),
    );

    // Apply MPV settings
    for (final entry in mpvSettings.entries) {
      if (entry.key == 'vo') continue;
      try {
        (_player.platform as dynamic).setProperty(entry.key, entry.value);
      } catch (_) {}
    }

    videoController = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        androidAttachSurfaceAfterVideoParameters: Platform.isAndroid
            ? true
            : null,
      ),
    );

    _attachListeners();

    ref.onDispose(_dispose);

    return PlayerState.initial();
  }

  void _attachListeners() {
    final stream = _player.stream;

    _subs.add(
      stream.position.listen((pos) {
        if (_player.state.duration > Duration.zero) {
          state = state.copyWith(position: pos);
        }
      }),
    );

    _subs.add(
      stream.duration.listen((dur) => state = state.copyWith(duration: dur)),
    );

    _subs.add(
      stream.buffer.listen((buf) => state = state.copyWith(buffer: buf)),
    );

    _subs.add(
      stream.buffering.listen(
        (buf) => state = state.copyWith(isBuffering: buf),
      ),
    );

    _subs.add(
      stream.playing.listen((play) => state = state.copyWith(isPlaying: play)),
    );

    _subs.add(
      stream.rate.listen((rate) => state = state.copyWith(playbackSpeed: rate)),
    );

    _subs.add(
      stream.subtitle.listen((subs) => state = state.copyWith(subtitle: subs)),
    );
  }

  void _dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
  }

  Future<void> open(
    String url,
    Duration? startAt, {
    Map<String, String>? headers,
  }) async {
    await _player.open(Media(url, httpHeaders: headers));

    if (startAt == null || startAt == Duration.zero) return;

    try {
      await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 10));

      await _player.seek(startAt);
    } catch (_) {}
  }

  Future<void> togglePlay() async {
    _player.state.playing ? await _player.pause() : await _player.play();
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> seek(Duration pos) => _player.seek(pos);

  void seekRelative(int seconds) {
    final p = _player.state.position + Duration(seconds: seconds);
    _player.seek(p);
  }

  void forward(int seconds) {
    final p = _player.state.position + Duration(seconds: seconds);
    _player.seek(p);
  }

  void rewind(int seconds) {
    final p = _player.state.position - Duration(seconds: seconds);
    _player.seek(p < Duration.zero ? Duration.zero : p);
  }

  Future<void> setSpeed(double speed) => _player.setRate(speed);

  void setFit(BoxFit fit) => state = state.copyWith(fit: fit);

  Future<void> setSubtitle(SubtitleTrack track) =>
      _player.setSubtitleTrack(track);

  void volumeUp() =>
      _player.setVolume((_player.state.volume + 10).clamp(0, 100));

  void volumeDown() =>
      _player.setVolume((_player.state.volume - 10).clamp(0, 100));

  void toggleMute() => _player.setVolume(_player.state.volume == 0 ? 100 : 0);
}
