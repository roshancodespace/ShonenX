import 'package:flutter/widgets.dart';
import 'package:shonenx/shared/models/video_stream.dart';

abstract class VideoEngine {
  Future<void> initialize(VideoStream stream, {SubtitleTrack? subtitle, Duration? startAt});

  Widget buildVideoView();
  Widget? buildSettingsView(BuildContext context);

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> seekRelative(Duration offset);
  Future<void> changeQuality(VideoStream newStream);
  Future<void> setSubtitle(SubtitleTrack? subtitle);
  Future<void> setAudioTrack(AudioTrack track);
  Future<void> setSpeed(double speed);

  Future<void> dispose();

  Duration get currentPosition;
  Duration get currentDuration;
}
