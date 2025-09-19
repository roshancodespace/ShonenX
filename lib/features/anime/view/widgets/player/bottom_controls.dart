import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

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

  T watchTheme<T>(
    WidgetRef ref,
    T Function(EpisodeDataState s) selector,
  ) {
    return ref.watch(episodeDataProvider.select(selector));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState =
        ref.watch(playerStateProvider.select((p) => (p.position, p.duration)));
    final episodeNotifier = ref.read(episodeDataProvider.notifier);

    final positionMs = playerState.$1.inMilliseconds.toDouble();
    final durationMs = playerState.$2.inMilliseconds.toDouble();
    final displayedValue = (sliderValue ?? positionMs).clamp(0.0, durationMs);

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onInteraction,
      child: Column(
        children: [
          // Forward button row
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(0.9),
                      Colors.deepOrangeAccent.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _wrap(onForwardPressed),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Iconsax.forward, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '+85s',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar row with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    _formatDuration(
                        Duration(milliseconds: displayedValue.round())),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: displayedValue,
                    max: durationMs > 0 ? durationMs : 1.0,
                    onChanged: onSliderChanged,
                    onChangeStart: onSliderChangeStart,
                    onChangeEnd: onSliderChangeEnd,
                    activeColor: colorScheme.primary,
                    inactiveColor: Colors.white24,
                    thumbColor: colorScheme.primaryContainer,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _formatDuration(playerState.$2),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Control buttons row with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  style: ButtonStyle(
                    foregroundColor:
                        WidgetStatePropertyAll(colorScheme.onSurface),
                  ),
                  onPressed: _wrap(onLockPressed),
                  label: const Text('Lock'),
                  icon: const Icon(Iconsax.lock),
                ),
                if (watchTheme(ref, (s) => s.dubSubSupport))
                  TextButton.icon(
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStatePropertyAll(colorScheme.onSurface),
                    ),
                    onPressed: _wrap(() => episodeNotifier.toggleDubSub()),
                    label: Text(
                        watchTheme(ref, (s) => s.selectedCategory) == 'sub'
                            ? 'Sub'
                            : 'Dub'),
                    icon: const Icon(Iconsax.text_block),
                  ),
                if (watchTheme(ref, (s) => s.servers).length > 1)
                  TextButton.icon(
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStatePropertyAll(colorScheme.onSurface),
                    ),
                    onPressed: _wrap(onServerPressed),
                    label: Text(
                        watchTheme(ref, (s) => s.selectedServer) ?? 'Server'),
                    icon: const Icon(Iconsax.cloud),
                  ),
                if (watchTheme(ref, (s) => s.sources).length > 1)
                  TextButton.icon(
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStatePropertyAll(colorScheme.onSurface),
                    ),
                    onPressed: watchTheme(ref, (s) => s.sources).length > 1
                        ? _wrap(onSourcePressed)
                        : null,
                    label: const Text('Source'),
                    icon: const Icon(Iconsax.hierarchy_2),
                  ),
                if (watchTheme(ref, (s) => s.subtitles).isNotEmpty)
                  TextButton.icon(
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStatePropertyAll(colorScheme.onSurface),
                    ),
                    onPressed: watchTheme(ref, (s) => s.subtitles).isNotEmpty
                        ? _wrap(onSubtitlePressed)
                        : null,
                    label: const Text('Subtitle'),
                    icon: const Icon(Iconsax.subtitle),
                  ),
              ],
            ),
          ),
        ],
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
