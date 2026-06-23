import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class CenterControls extends ConsumerStatefulWidget {
  final bool showControls;
  final PlayerState playerState;
  final PlayerController controller;
  final String mediaTitle;
  final VideoEngine engine;

  const CenterControls({
    super.key,
    required this.showControls,
    required this.playerState,
    required this.controller,
    required this.mediaTitle,
    required this.engine,
  });

  @override
  ConsumerState<CenterControls> createState() => _CenterControlsState();
}

class _CenterControlsState extends ConsumerState<CenterControls> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final episodes =
        ref.watch(
          episodesListProvider(
            MatchArgs(mediaTitle: widget.mediaTitle, type: MediaType.ANIME),
          ).select((s) => s.value?.episodes),
        ) ??
        [];
    final isFirst = episodes.isEmpty
        ? true
        : widget.playerState.activeEpisode?.number == episodes.first.number;
    final isLast = episodes.isEmpty
        ? true
        : widget.playerState.activeEpisode?.number == episodes.last.number;

    return IgnorePointer(
      ignoring: !widget.showControls,
      child: AnimatedOpacity(
        curve: Curves.easeInOut,
        opacity: widget.showControls ? 1 : 0,
        duration: Durations.medium2,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: isFirst
                    ? null
                    : () => widget.controller.skipEpisode(forward: false),
                icon: const Icon(Icons.skip_previous_outlined, size: 60),
                color: isFirst ? Colors.grey : Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer(
                  builder: (context, ref, child) {
                    final isPlaying = ref.watch(
                      videoEngineStateProvider.select((s) => s.isPlaying),
                    );
                    final isBuffering = ref.watch(
                      videoEngineStateProvider.select((s) => s.isBuffering),
                    );

                    if (isBuffering) {
                      return const CircularProgressIndicator(
                        constraints: BoxConstraints(
                          minHeight: 80,
                          minWidth: 80,
                        ),
                        strokeWidth: 5,
                      );
                    }

                    return IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                      onPressed: isPlaying
                          ? widget.engine.pause
                          : widget.engine.play,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) {
                          final isIncoming = child.key == ValueKey(isPlaying);

                          final rotation = Tween<double>(
                            begin: isIncoming ? -0.25 : 0.25,
                            end: 0.0,
                          ).animate(animation);

                          return RotationTransition(
                            turns: rotation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: isLast
                    ? null
                    : () => widget.controller.skipEpisode(forward: true),
                icon: const Icon(Icons.skip_next_outlined, size: 60),
                color: isLast ? Colors.grey : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
