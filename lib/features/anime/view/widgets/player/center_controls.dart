import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const CenterControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playerNotifier = ref.read(playerStateProvider.notifier);

    final isBuffering =
        ref.watch(playerStateProvider.select((p) => p.isBuffering));
    final isPlaying = ref.watch(playerStateProvider.select((p) => p.isPlaying));
    final sourceLoading =
        ref.watch(episodeDataProvider.select((e) => e.sourceLoading));
    final episodesLoading =
        ref.watch(episodeDataProvider.select((e) => e.episodesLoading));

    return GestureDetector(
      onTap: onInteraction,
      child: Center(
        child: isBuffering
            ? _buildLoadingState(
                scheme, textTheme, sourceLoading, episodesLoading)
            : _buildPlayButton(isPlaying, () {
                onInteraction();
                playerNotifier.togglePlay();
              }),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme scheme, TextTheme textTheme,
      bool sourceLoading, bool episodesLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: scheme.primary, // themed color
          ),
        ),
        if (sourceLoading || episodesLoading) ...[
          const SizedBox(height: 12),
          Text(
            _getLoadingText(sourceLoading, episodesLoading),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayButton(bool isPlaying, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white, // keep the button white
              size: 60,
            ),
          ),
        ),
      ),
    );
  }

  String _getLoadingText(bool sourceLoading, bool episodesLoading) {
    if (sourceLoading && episodesLoading) {
      return 'Loading source and episodes...';
    } else if (sourceLoading) {
      return 'Loading source...';
    } else if (episodesLoading) {
      return 'Loading episodes...';
    } else {
      return 'Buffering...';
    }
  }
}
