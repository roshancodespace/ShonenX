import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/player_controls.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';

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
    if (widget.playerState.error != null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    final media = widget.controller.media;
    final episodes = media != null
        ? ref.watch(
                episodesListProvider(
                  MediaArgs.fromMedia(media),
                ).select((s) => s.value?.episodes),
              ) ??
              []
        : [];
    final isFirst = episodes.isEmpty
        ? !widget.controller.hasPrevEpisode
        : widget.playerState.activeEpisode?.number == episodes.first.number;
    final isLast = episodes.isEmpty
        ? !widget.controller.hasNextEpisode
        : widget.playerState.activeEpisode?.number == episodes.last.number;

    final isBuffering =
        ref.watch(videoEngineStateProvider.select((s) => s.isBuffering)) ||
        widget.playerState.isLoading;
    final isPlaying = ref.watch(
      videoEngineStateProvider.select((s) => s.isPlaying),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isBuffering)
          Center(
            child: CircularProgressIndicator(
              constraints: const BoxConstraints(minHeight: 80, minWidth: 80),
              strokeWidth: 5,
              color: theme.colorScheme.primary,
            ),
          ),
        IgnorePointer(
          ignoring: !widget.showControls || isBuffering,
          child: AnimatedOpacity(
            curve: Curves.easeInOut,
            opacity: (widget.showControls && !isBuffering) ? 1 : 0,
            duration: Durations.medium2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlayerEpisodeNavButton(
                    isNext: false,
                    isEnabled: !isFirst,
                    onTap: () => widget.controller.skipEpisode(forward: false),
                  ),
                  PlayerPlayPauseButton(
                    isPlaying: isPlaying,
                    onToggle: isPlaying
                        ? widget.engine.pause
                        : widget.engine.play,
                  ),
                  PlayerEpisodeNavButton(
                    isNext: true,
                    isEnabled: !isLast,
                    onTap: () => widget.controller.skipEpisode(forward: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
