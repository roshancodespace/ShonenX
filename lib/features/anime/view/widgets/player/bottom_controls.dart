import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/core/models/aniskip/aniskip_result.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/utils/formatter.dart';

class BottomControls extends ConsumerWidget {
  final VoidCallback onInteraction;

  final double? sliderValue;
  final ValueChanged<double>? onSliderChanged;
  final ValueChanged<double>? onSliderChangeStart;
  final ValueChanged<double>? onSliderChangeEnd;

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
    this.onSliderChanged,
    this.onSliderChangeStart,
    this.onSliderChangeEnd,
    required this.onLockPressed,
    required this.onSourcePressed,
    required this.onSubtitlePressed,
    required this.onServerPressed,
    required this.onForwardPressed,
    this.onEpisodePressed,
  });

  VoidCallback _wrap(VoidCallback? cb) {
    return () {
      cb?.call();
      onInteraction();
    };
  }

  T _watch<T>(WidgetRef ref, T Function(EpisodeDataState s) sel) {
    return ref.watch(episodeDataProvider.select(sel));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final episodeNotifier = ref.read(episodeDataProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final skips = ref.watch(aniSkipProvider);
                  if (skips.isEmpty) return const SizedBox.shrink();

                  final settings = ref.watch(playerSettingsProvider);
                  if (!settings.enableAniSkip) return const SizedBox.shrink();

                  final pos =
                      ref.watch(playerStateProvider.select((p) => p.position));

                  final currentSkip = skips.firstWhere(
                    (s) {
                      if (s.interval == null) return false;
                      final start =
                          Duration(seconds: s.interval!.startTime.toInt());
                      final end =
                          Duration(seconds: s.interval!.endTime.toInt());
                      return pos >= start && pos < end;
                    },
                    orElse: () => const AniSkipResultItem(
                        skipType: SkipType.unknown,
                        action: '',
                        episodeLength: 0),
                  );

                  if (currentSkip.interval == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildAniSkipButton(scheme, currentSkip, ref),
                  );
                },
              ),
              _buildSkipButton(scheme),
            ],
          ),
          _buildProgressBar(context, ref, scheme),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBack(ref),
                  _buildPlayPause(ref),
                  _buildForward(ref),
                  const SizedBox(width: 12),
                  _buildTime(ref, scheme),
                ],
              ),
              Row(
                children: [
                  if (_watch(
                      ref,
                      (s) =>
                          s.selectedServer?.isDub != null &&
                          s.servers.any((e) => e.isDub)))
                    _pill(
                      text: _watch(ref, (s) => s.selectedServer?.isDub == true)
                          ? 'DUB'
                          : 'SUB',
                      onTap: () => episodeNotifier.toggleDubSub(),
                    ),
                  if (_watch(ref, (s) => s.sources.length) > 1) ...[
                    const SizedBox(width: 8),
                    Builder(builder: (_) {
                      final list = _watch(ref, (s) => s.sources);
                      final idx = _watch(ref, (s) => s.selectedSourceIdx) ?? 0;
                      if (idx < 0 || idx >= list.length) {
                        return const SizedBox.shrink();
                      }
                      return _pill(
                        text: list[idx].quality ?? 'Auto',
                        onTap: onSourcePressed,
                      );
                    }),
                  ],
                  const SizedBox(width: 8),
                  _icon(
                    icon: _watch(ref, (s) => s.selectedSubtitleIdx != 0)
                        ? Iconsax.subtitle5
                        : Iconsax.subtitle,
                    tooltip: 'Subtitles',
                    onTap: onSubtitlePressed,
                    onLong: () => context.push('/settings/player/subtitles'),
                  ),
                  const SizedBox(width: 8),
                  _icon(
                    icon: Iconsax.lock,
                    tooltip: 'Lock',
                    onTap: onLockPressed,
                  ),
                  const SizedBox(width: 8),
                  _icon(
                    icon: Icons.playlist_play_rounded,
                    tooltip: 'Episodes',
                    onTap: onEpisodePressed,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Iconsax.previous, color: Colors.white),
      onPressed: () =>
          ref.read(episodeDataProvider.notifier).changeEpisode(null, by: -1),
    );
  }

  Widget _buildForward(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Iconsax.next, color: Colors.white),
      onPressed: () =>
          ref.read(episodeDataProvider.notifier).changeEpisode(null, by: 1),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme scheme,
  ) {
    return SizedBox(
      height: 30,
      child: Consumer(
        builder: (_, ref, __) {
          final (pos, dur, buf) = ref.watch(
            playerStateProvider.select(
              (p) => (p.position, p.duration, p.buffer),
            ),
          );

          final max =
              dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;

          final position = pos.inMilliseconds.toDouble().clamp(0, max);
          final buffer = buf.inMilliseconds.toDouble().clamp(0, max);
          final value = (sliderValue ?? position).clamp(0, max);

          final baseTheme = SliderTheme.of(context);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // buffer slider
              SliderTheme(
                data: baseTheme.copyWith(
                  trackShape: const RectangularSliderTrackShape(),
                  trackHeight: 4,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: scheme.onSurface.withOpacity(0.4),
                  inactiveTrackColor: scheme.onSurface.withOpacity(0.2),
                ),
                child: Slider(
                  value: buffer.toDouble(),
                  max: max,
                  onChanged: null,
                ),
              ),

              // highlights
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final skips = ref.watch(aniSkipProvider);
                    final settings = ref.watch(playerSettingsProvider);

                    if (!settings.enableAniSkip || skips.isEmpty || max <= 0) {
                      return const SizedBox.shrink();
                    }

                    final total = max;
                    final maxWidth = constraints.maxWidth;

                    return Stack(
                      children: [
                        for (final skip in skips)
                          if (skip.interval != null)
                            (() {
                              final start = (skip.interval!.startTime * 1000)
                                  .clamp(0, total);
                              final end = (skip.interval!.endTime * 1000)
                                  .clamp(0, total);

                              if (end <= start) return const SizedBox.shrink();

                              final left = (start / total) * maxWidth;
                              final width = ((end - start) / total) * maxWidth;

                              Color color;
                              if (skip.skipType == SkipType.op) {
                                color = Colors.green.withOpacity(0.6);
                              } else if (skip.skipType == SkipType.ed) {
                                color = Colors.blue.withOpacity(0.6);
                              } else {
                                color = scheme.primary.withOpacity(0.5);
                              }

                              return Positioned(
                                left: left,
                                top: 13,
                                child: Container(
                                  width: width,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            })(),
                      ],
                    );
                  },
                ),
              ),

              // progress slider
              SliderTheme(
                data: baseTheme.copyWith(
                  trackShape: const RectangularSliderTrackShape(),
                  trackHeight: 4,
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: Colors.transparent,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value.toDouble(),
                  max: max,
                  onChanged: onSliderChanged,
                  onChangeStart: onSliderChangeStart,
                  onChangeEnd: onSliderChangeEnd,
                ),
              ),

              // custom rectangular thumb
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final dx = constraints.maxWidth * (value / max);

                    return IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(dx - 4, 0),
                          child: Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTime(WidgetRef ref, ColorScheme scheme) {
    final (pos, dur) = ref.watch(
      playerStateProvider.select((p) => (p.position, p.duration)),
    );

    return Text(
      '${formatDuration(pos)} / ${formatDuration(dur)}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildPlayPause(WidgetRef ref) {
    final isPlaying = ref.watch(playerStateProvider.select((p) => p.isPlaying));
    final notifier = ref.read(playerStateProvider.notifier);

    return InkWell(
      onTap: _wrap(notifier.togglePlay),
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

  Widget _icon({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    VoidCallback? onLong,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _wrap(onTap),
        onLongPress: _wrap(onLong),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _pill({required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: _wrap(onTap),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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

  Widget _buildSkipButton(ColorScheme scheme) {
    return InkWell(
      onTap: _wrap(onForwardPressed),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.forward, color: Colors.black, size: 16),
            SizedBox(width: 4),
            Text(
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

  Widget _buildAniSkipButton(
      ColorScheme scheme, AniSkipResultItem skip, WidgetRef ref) {
    String label = 'Skip';
    switch (skip.skipType) {
      case SkipType.op:
      case SkipType.ed:
        label = 'Skip ${skip.skipType.name.toUpperCase()}';
        break;
      case SkipType.recap:
        label = 'Skip Recap';
        break;
      default:
        label = 'Skip';
    }

    return InkWell(
      onTap: () {
        ref.read(playerStateProvider.notifier).seek(
              Duration(seconds: skip.interval!.endTime.toInt() + 1),
            );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.skip_next, color: Colors.black, size: 16),
          ],
        ),
      ),
    );
  }
}
