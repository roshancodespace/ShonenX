import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/utils/formatter.dart';
import 'package:go_router/go_router.dart';

class BottomControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final double? sliderValue;
  final Function(double) onSliderChanged;
  final Function(double) onSliderChangeStart;
  final Function(double) onSliderChangeEnd;
  final VoidCallback onLockPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onServerPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback? onEpisodePressed;

  const BottomControls({
    super.key,
    required this.onInteraction,
    this.sliderValue,
    required this.onSliderChanged,
    required this.onSliderChangeStart,
    required this.onSliderChangeEnd,
    required this.onLockPressed,
    required this.onSourcePressed,
    required this.onSubtitlePressed,
    required this.onServerPressed,
    required this.onForwardPressed,
    required this.onEpisodePressed,
  });

  VoidCallback _wrap(VoidCallback? action) {
    return () {
      if (action != null) action();
      onInteraction();
    };
  }

  T watchEpisode<T>(WidgetRef ref, T Function(EpisodeDataState s) selector) {
    return ref.watch(episodeDataProvider.select(selector));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSkipButton(context, scheme),
              ],
            ),
            // Seek Bar
            _buildProgressBar(context, ref, scheme),
            const SizedBox(height: 4),

            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Play/Pause and Time
                Row(
                  children: [
                    _buildPlayPauseButton(ref, scheme),
                    const SizedBox(width: 12),
                    _buildTimeDisplay(context, ref, scheme),
                  ],
                ),

                // Right: Actions
                Row(
                  children: [
                    if (watchEpisode(ref, (s) => s.dubSubSupport))
                      _buildSettingsPill(
                        context,
                        text: watchEpisode(ref, (s) => s.selectedCategory) ==
                                'sub'
                            ? 'SUB'
                            : 'DUB',
                        onPressed: () => episodeNotifier.toggleDubSub(),
                        scheme: scheme,
                      ),
                    if (watchEpisode(ref, (s) => s.sources.length) > 1) ...[
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final sources = watchEpisode(ref, (s) => s.sources);
                        final index =
                            watchEpisode(ref, (s) => s.selectedSourceIdx) ?? 0;
                        if (index >= 0 && index < sources.length) {
                          return _buildSettingsPill(
                            context,
                            text: sources[index].quality ?? 'Auto',
                            onPressed: onSourcePressed,
                            scheme: scheme,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon:
                          (watchEpisode(ref, (s) => s.selectedSubtitleIdx != 0)
                              ? Iconsax.subtitle5
                              : Iconsax.subtitle),
                      onPressed: onSubtitlePressed,
                      onLongPress: () =>
                          context.push('/settings/player/subtitles'),
                      color: scheme.onSurface,
                      tooltip: 'Subtitles',
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Iconsax.lock,
                      onPressed: onLockPressed,
                      color: scheme.onSurface,
                      tooltip: 'Lock',
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.playlist_play_rounded,
                      onPressed: onEpisodePressed,
                      color: scheme.onSurface,
                      tooltip: 'Episode',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, WidgetRef ref, ColorScheme scheme) {
    return SizedBox(
      height: 20,
      child: Consumer(builder: (context, ref, child) {
        final state = ref.watch(playerStateProvider.select(
          (p) => (p.position, p.duration, p.buffer),
        ));

        final duration = state.$2.inMilliseconds.toDouble();
        final position = state.$1.inMilliseconds.toDouble();
        final buffer = state.$3.inMilliseconds.toDouble();

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Buffer track
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: SliderComponentShape.noThumb,
                activeTrackColor: scheme.onSurface.withOpacity(0.4),
                inactiveTrackColor: scheme.onSurface.withOpacity(0.2),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: buffer.clamp(0.0, duration),
                max: duration > 0 ? duration : 1.0,
                onChanged: null,
              ),
            ),

            // Playhead track
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: scheme.primary,
                inactiveTrackColor: Colors.transparent,
                trackShape: const RectangularSliderTrackShape(),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                  disabledThumbRadius: 8,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 16,
                ),
              ),
              child: Slider(
                value: (sliderValue ?? position).clamp(0.0, duration),
                max: duration > 0 ? duration : 1.0,
                onChanged: onSliderChanged,
                onChangeStart: onSliderChangeStart,
                onChangeEnd: onSliderChangeEnd,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTimeDisplay(
      BuildContext context, WidgetRef ref, ColorScheme scheme) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(playerStateProvider.select(
          (p) => (p.position, p.duration),
        ));
        final position = state.$1;
        final duration = state.$2;

        return Text(
          '${formatDuration(position)} / ${formatDuration(duration)}',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseButton(WidgetRef ref, ColorScheme scheme) {
    final isPlaying = ref.watch(playerStateProvider.select((p) => p.isPlaying));
    final notifier = ref.read(playerStateProvider.notifier);

    return InkWell(
      onTap: _wrap(() => notifier.togglePlay()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Iconsax.pause : Iconsax.play,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _wrap(onPressed),
        onLongPress: _wrap(onLongPress),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildSettingsPill(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required ColorScheme scheme,
  }) {
    return InkWell(
      onTap: _wrap(onPressed),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, ColorScheme scheme) {
    return InkWell(
      onTap: _wrap(onForwardPressed),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.forward, color: Colors.black, size: 16),
            const SizedBox(width: 4),
            const Text(
              '+85s',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
