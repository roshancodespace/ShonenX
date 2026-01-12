import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class PlayerControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onLockPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onServerPressed;

  const PlayerControls({
    super.key,
    required this.onInteraction,
    this.onEpisodesPressed,
    required this.onSettingsPressed,
    required this.onQualityPressed,
    required this.onLockPressed,
    required this.onSourcePressed,
    required this.onSubtitlePressed,
    required this.onServerPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerStateProvider.notifier);

    return RepaintBoundary(
      child: Stack(
        children: [
          Center(
              child: CenterControls(
            onInteraction: onInteraction,
          )),
          TopControls(
            onInteraction: onInteraction,
            onEpisodesPressed: onEpisodesPressed,
            onSettingsPressed: onSettingsPressed,
            onQualityPressed: onQualityPressed,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomControls(
              onInteraction: onInteraction,
              onLockPressed: onLockPressed,
              onEpisodePressed: onEpisodesPressed,
              onForwardPressed: () => notifier.forward(85),
              onSourcePressed: onSourcePressed,
              onSubtitlePressed: onSubtitlePressed,
              onServerPressed: onServerPressed,
            ),
          ),
        ],
      ),
    );
  }
}
