// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shonenx/core/network/http_client.dart';
// import 'package:shonenx/core/utils/http_x.dart';
// import 'package:shonenx/features/player/engine/video_engine.dart';
// import 'package:shonenx/shared/models/video_stream.dart';
// import 'package:video_player/video_player.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shonenx/features/player/providers/video_engine_provider.dart';

// class VideoPlayerEngine implements VideoEngine {
//   VideoPlayerController? _controller;
//   final Ref ref;

//   static final HTTP _http = HTTP();

//   VideoPlayerEngine(this.ref);

//   @override
//   Future<void> initialize(
//     VideoStream stream, {
//     SubtitleTrack? subtitle,
//     Duration? startAt,
//   }) async {
//     _controller?.removeListener(_listener);
//     _controller?.dispose();
//     _controller = VideoPlayerController.networkUrl(
//       Uri.parse(stream.url),
//       httpHeaders: stream.headers ?? {},
//       formatHint: await _http.isHLS(stream.url, headers: stream.headers)
//           ? VideoFormat.hls
//           : null,
//     );
//     _controller?.addListener(_listener);

//     await _controller?.initialize();
//     if (startAt != null) {
//       await _controller?.seekTo(startAt);
//     }
//   }

//   void _listener() {
//     final value = _controller?.value;
//     if (value == null) return;

//     final buffered = value.buffered;
//     final bufferDuration = buffered.isNotEmpty
//         ? buffered.last.end
//         : Duration.zero;

//     ref
//         .read(videoEngineStateProvider.notifier)
//         .updateState(
//           position: value.position,
//           duration: value.duration,
//           buffer: bufferDuration,
//           isPlaying: value.isPlaying,
//           isBuffering: value.isBuffering,
//         );
//   }

//   @override
//   Widget buildVideoView() {
//     return _controller == null
//         ? const Center(child: CircularProgressIndicator())
//         : VideoPlayer(_controller!);
//   }

//   @override
//   Widget? buildSettingsView(BuildContext context) {
//     return null;
//   }

//   @override
//   Future<void> play() async {
//     return _controller?.play();
//   }

//   @override
//   Future<void> pause() async {
//     return _controller?.pause();
//   }

//   @override
//   Future<void> seekTo(Duration position) async {
//     return _controller?.seekTo(position);
//   }

//   @override
//   Future<void> seekRelative(Duration offset) async {
//     final current = _controller?.value.position ?? Duration.zero;
//     return _controller?.seekTo(current + offset);
//   }

//   @override
//   Future<void> changeQuality(VideoStream newStream) async =>
//       initialize(newStream);

//   @override
//   Future<void> setSubtitle(SubtitleTrack? subtitle) async {
//     if (subtitle == null) return;
//   }

//   @override
//   Future<void> setSpeed(double speed) async =>
//       _controller?.setPlaybackSpeed(speed);

//   @override
//   Future<void> dispose() async {
//     _controller?.removeListener(_listener);
//     _controller?.dispose();
//   }

//   @override
//   Duration get currentPosition => _controller?.value.position ?? Duration.zero;

//   @override
//   Duration get currentDuration => _controller?.value.duration ?? Duration.zero;
// }
