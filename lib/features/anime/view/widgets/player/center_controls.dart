import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

class CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const CenterControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerStateProvider.notifier);
    return GestureDetector(
        onTap: onInteraction,
        child: ref.watch(playerStateProvider.select((p) => p.isBuffering))
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (ref.watch(
                      episodeDataProvider.select((e) => e.sourceLoading)))
                    Text('Source is loading'),
                  const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator()),
                  if (ref.watch(
                      episodeDataProvider.select((e) => e.episodesLoading)))
                    Text('Loading episodes')
                ],
              )
            : IconButton(
                onPressed: () {
                  onInteraction();
                  playerNotifier.togglePlay();
                },
                icon: Icon(
                    ref.watch(playerStateProvider.select((p) => p.isPlaying))
                        ? Icons.pause
                        : Icons.play_arrow),
                iconSize: 80,
              ));
  }
}
