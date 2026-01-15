import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class ControlsOverlay extends ConsumerWidget {
  final bool visible;
  final bool locked;
  final VoidCallback onLockPressed;
  final VoidCallback onRestartHide;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onServerPressed;
  final VoidCallback onSubtitlePressed;

  const ControlsOverlay({
    super.key,
    required this.visible,
    required this.locked,
    required this.onLockPressed,
    required this.onRestartHide,
    this.onEpisodesPressed,
    required this.onSettingsPressed,
    required this.onQualityPressed,
    required this.onSourcePressed,
    required this.onServerPressed,
    required this.onSubtitlePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !visible,
        child: locked ? _lockBtn() : _controls(ref),
      ),
    );
  }

  Widget _lockBtn() {
    return Center(
      child: IconButton(
        onPressed: onLockPressed,
        icon: const Icon(Icons.lock_open, size: 32, color: Colors.white),
        style: IconButton.styleFrom(backgroundColor: Colors.black54),
      ),
    );
  }

  Widget _controls(WidgetRef ref) {
    final notifier = ref.read(playerStateProvider.notifier);

    return RepaintBoundary(
      child: Stack(
        children: [
          Center(child: CenterControls(onInteraction: onRestartHide)),
          TopControls(
            onInteraction: onRestartHide,
            onEpisodesPressed: onEpisodesPressed,
            onSettingsPressed: onSettingsPressed,
            onQualityPressed: onQualityPressed,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomControls(
              onInteraction: onRestartHide,
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
