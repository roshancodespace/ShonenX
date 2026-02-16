import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

import 'package:shonenx/core/providers/settings/player_notifier.dart';
import 'package:iconsax/iconsax.dart';

class CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const CenterControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (isPlaying, isBuffering) = ref.watch(
      playerStateProvider.select((p) => (p.isPlaying, p.isBuffering)),
    );

    final episodeStreamState = ref.watch(
      episodeDataProvider.select((e) => e.states),
    );
    final episodesLoading = ref.watch(
      episodeListProvider.select((e) => e.isLoading),
    );

    final playerNotifier = ref.read(playerStateProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ref.watch(playerSettingsProvider).showNextPrevButtons) ...[
              _icon(
                Iconsax.previous,
                () => ref
                    .read(episodeDataProvider.notifier)
                    .changeEpisode(null, by: -1),
              ),
              const SizedBox(width: 24),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isBuffering
                  ? _LoadingState(
                      scheme: scheme,
                      textTheme: textTheme,
                      sourceLoading: episodeStreamState.contains(
                        EpisodeStreamState.SOURCE_LOADING,
                      ),
                      episodesLoading: episodesLoading,
                    )
                  : _PlayPauseButton(
                      isPlaying: isPlaying,
                      onPressed: () {
                        onInteraction();
                        playerNotifier.togglePlay();
                      },
                    ),
            ),
            if (ref.watch(playerSettingsProvider).showNextPrevButtons) ...[
              const SizedBox(width: 24),
              _icon(
                Iconsax.next,
                () => ref
                    .read(episodeDataProvider.notifier)
                    .changeEpisode(null, by: 1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final bool sourceLoading;
  final bool episodesLoading;

  const _LoadingState({
    required this.scheme,
    required this.textTheme,
    required this.sourceLoading,
    required this.episodesLoading,
  });

  @override
  Widget build(BuildContext context) {
    final text = _text();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 10),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String? _text() {
    if (sourceLoading && episodesLoading) return 'Loading source & episodes';
    if (sourceLoading) return 'Loading source';
    if (episodesLoading) return 'Loading episodes';
    return 'Buffering';
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Icon(
            isPlaying ? Iconsax.pause5 : Iconsax.play5,
            color: Colors.white,
            size: 56,
          ),
        ),
      ),
    );
  }
}
