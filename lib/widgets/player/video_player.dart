import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';

class VideoPlayer extends StatefulWidget {
  final BetterPlayerController playerController;
  const VideoPlayer({super.key, required this.playerController});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return BetterPlayer(controller: widget.playerController);
  }
}
