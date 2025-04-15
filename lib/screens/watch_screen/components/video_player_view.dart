import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/screens/watch_screen/controls.dart';

/// Main video player component
class VideoPlayerView extends StatelessWidget {
  final VideoController controller;
  final AnimationController panelAnimationController;

  const VideoPlayerView({
    super.key,
    required this.controller,
    required this.panelAnimationController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Video(
        controller: controller,
        subtitleViewConfiguration: const SubtitleViewConfiguration(visible: false),
        filterQuality: kDebugMode ? FilterQuality.low : FilterQuality.none,
        fit: BoxFit.contain,
        controls: (state) => CustomControls(
          state: state,
          panelAnimationController: panelAnimationController,
        ),
      ),
    );
  }
}
