import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shonenx/shared/models/video_stream.dart';

enum PlayerStatus { idle, loading, playing, paused, buffering, ended, error }

abstract class VideoEngine {
  // --- Lifecycle ---
  Future<void> initialize(
    VideoStream stream, {
    SubtitleTrack? subtitle,
    Duration? startAt,
  });
  Future<void> refresh();
  Future<void> dispose();

  // --- Commands ---
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> seekRelative(Duration offset);
  Future<void> setSubtitle(SubtitleTrack? subtitle);
  Future<void> setAudioTrack(AudioTrack track);
  Future<void> setSpeed(double speed);
  Future<void> changeQuality(VideoStream newStream);

  // --- Video View ---
  Widget buildVideoView({BoxFit fit = BoxFit.contain});

  // --- State Subscriptions ---
  // High-frequency
  ValueListenable<Duration> get positionNotifier;
  ValueListenable<Duration> get durationNotifier;
  ValueListenable<Duration> get bufferNotifier;

  // Low-frequency
  ValueListenable<PlayerStatus> get statusNotifier;
  ValueListenable<List<SubtitleTrack>> get subtitleTracksNotifier;
  ValueListenable<List<AudioTrack>> get audioTracksNotifier;
  ValueListenable<SubtitleTrack?> get activeSubtitleNotifier;
  ValueListenable<AudioTrack?> get activeAudioNotifier;

  // Synchronous getters (for immediate checks when needed)
  Duration get currentPosition;
  Duration get currentDuration;
}
