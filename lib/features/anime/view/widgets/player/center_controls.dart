import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';

class CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const CenterControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

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
    final settings = ref.watch(playerSettingsProvider);

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (settings.showNextPrevButtons) ...[
            _ShadowIconButton(
              icon: Icons.skip_previous_rounded,
              size: 56,
              onTap: () {
                onInteraction();
                ref
                    .read(episodeDataProvider.notifier)
                    .changeEpisode(null, by: -1);
              },
            ),
            const SizedBox(width: 48),
          ],

          // Core Center Action (Buffer or Play/Pause)
          SizedBox(
            width: 80,
            height: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isBuffering
                  ? _BorderlessLoading(
                      key: const ValueKey('loading'),
                      scheme: scheme,
                      sourceLoading: episodeStreamState.contains(
                        EpisodeStreamState.SOURCE_LOADING,
                      ),
                      episodesLoading: episodesLoading,
                    )
                  : _ShadowIconButton(
                      key: ValueKey(isPlaying ? 'pause' : 'play'),
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 80,
                      onTap: () {
                        onInteraction();
                        playerNotifier.togglePlay();
                      },
                    ),
            ),
          ),

          if (settings.showNextPrevButtons) ...[
            const SizedBox(width: 48),
            _ShadowIconButton(
              icon: Icons.skip_next_rounded,
              size: 56,
              onTap: () {
                onInteraction();
                ref
                    .read(episodeDataProvider.notifier)
                    .changeEpisode(null, by: 1);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// --- Borderless Premium Components ---

class _ShadowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ShadowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        icon,
        color: Colors.white,
        size: size,
        shadows: const [
          Shadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
          Shadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _BorderlessLoading extends StatelessWidget {
  final ColorScheme scheme;
  final bool sourceLoading;
  final bool episodesLoading;

  const _BorderlessLoading({
    super.key,
    required this.scheme,
    required this.sourceLoading,
    required this.episodesLoading,
  });

  @override
  Widget build(BuildContext context) {
    final text = _text();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: scheme.primary,
            strokeCap: StrokeCap.round,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _text() {
    if (sourceLoading && episodesLoading) return 'Fetching...';
    if (sourceLoading) return 'Source...';
    if (episodesLoading) return 'Episodes...';
    return null;
  }
}
