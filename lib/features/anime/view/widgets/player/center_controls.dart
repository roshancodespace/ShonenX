import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

class CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const CenterControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);
    return GestureDetector(
      onTap: onInteraction,
      child: playerState.isBuffering
          ? const SizedBox(
              width: 80, height: 80, child: CircularProgressIndicator())
          : IconButton(
              onPressed: () {
                onInteraction();
                playerNotifier.togglePlay();
              },
              icon:
                  Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 80,
            ),
    );
  }
}
