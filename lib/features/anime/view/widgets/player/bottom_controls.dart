import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

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
  });

  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      onInteraction();
      action();
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
            scheme.surface.withOpacity(0.85),
            scheme.surface.withOpacity(0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(context, ref, scheme),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildButton(
                    icon: Icons.lock_outline,
                    onPressed: _wrap(onLockPressed),
                    color: scheme.onSurface,
                  ),
                  const Spacer(),
                  ..._buildQuickControls(context, ref, episodeNotifier, scheme),
                  const Spacer(),
                  _buildSkipButton(context, scheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, WidgetRef ref, ColorScheme scheme) {
    return Row(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final position = ref.watch(playerStateProvider.select((p) => p
                .position.inMilliseconds
                .clamp(0.0, p.duration.inMilliseconds)));
            return Text(
              _formatDuration(Duration(milliseconds: position.round())),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer(builder: (context, ref, child) {
            final state = ref.watch(playerStateProvider.select(
              (p) => (p.position, p.duration, p.buffer),
            ));

            final duration = state.$2.inMilliseconds.toDouble();
            final position = state.$1.inMilliseconds.toDouble();
            final buffer = state.$3.inMilliseconds.toDouble();

            return Stack(
              alignment: Alignment.center,
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
        ),
        const SizedBox(width: 12),
        Consumer(
          builder: (context, ref, child) {
            final duration = ref.watch(playerStateProvider.select((p) => p
                .duration.inMilliseconds
                .clamp(0.0, p.duration.inMilliseconds)));
            return Text(
              _formatDuration(Duration(milliseconds: duration.round())),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildQuickControls(
    BuildContext context,
    WidgetRef ref,
    dynamic episodeNotifier,
    ColorScheme scheme,
  ) {
    final controls = <Widget>[];

    if (watchEpisode(ref, (s) => s.dubSubSupport)) {
      final isSub = watchEpisode(ref, (s) => s.selectedCategory) == 'sub';
      controls.add(_buildInfoButton(
        context,
        text: isSub ? 'SUB' : 'DUB',
        onPressed: _wrap(() => episodeNotifier.toggleDubSub()),
        scheme: scheme,
      ));
    }

    if (watchEpisode(ref, (s) => s.servers).length > 1) {
      final selectedServer =
          watchEpisode(ref, (s) => s.selectedServer) ?? 'Server 1';
      controls.add(_buildInfoButton(
        context,
        text: selectedServer,
        onPressed: _wrap(onServerPressed),
        scheme: scheme,
      ));
    }

    if (watchEpisode(ref, (s) => s.sources.length) > 1) {
      final ss = watchEpisode(ref, (s) => (s.selectedSourceIdx, s.sources));
      controls.add(_buildInfoButton(
        context,
        text: ss.$2[ss.$1!].quality!,
        onPressed: _wrap(onSourcePressed),
        scheme: scheme,
      ));
    }

    if (watchEpisode(ref, (s) => s.subtitles).isNotEmpty) {
      controls.add(_buildInfoButton(
        context,
        text: 'CC',
        onPressed: _wrap(onSubtitlePressed),
        scheme: scheme,
      ));
    }

    final spacedControls = <Widget>[];
    for (int i = 0; i < controls.length; i++) {
      spacedControls.add(controls[i]);
      if (i < controls.length - 1) {
        spacedControls.add(const SizedBox(width: 16));
      }
    }
    return spacedControls;
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, ColorScheme scheme) {
    return GestureDetector(
      onTap: _wrap(onForwardPressed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.forward, color: scheme.onSurface, size: 18),
            const SizedBox(width: 4),
            Text(
              '+85s',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: scheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// Formats a Duration into hh:mm:ss or mm:ss.
String _formatDuration(Duration duration) {
  if (duration.isNegative) return '00:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
