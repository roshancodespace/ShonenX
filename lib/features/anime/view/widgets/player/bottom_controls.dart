import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/models/aniskip/aniskip_result.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/core/models/settings/player_model.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';
import 'package:shonenx/core/utils/formatter.dart';

class BottomControls extends ConsumerStatefulWidget {
  final VoidCallback onInteraction;
  final VoidCallback onLockPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onServerPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback? onEpisodePressed;
  final VoidCallback? onFullScreenPressed;

  const BottomControls({
    super.key,
    required this.onInteraction,
    required this.onLockPressed,
    required this.onSourcePressed,
    required this.onSubtitlePressed,
    required this.onServerPressed,
    required this.onForwardPressed,
    required this.onFullScreenPressed,
    this.onEpisodePressed,
  });

  @override
  ConsumerState<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends ConsumerState<BottomControls> {
  double? _draggedValue;

  VoidCallback _wrap(VoidCallback? cb) {
    return () {
      cb?.call();
      widget.onInteraction();
    };
  }

  T _watch<T>(WidgetRef ref, T Function(EpisodeDataState s) sel) {
    return ref.watch(episodeDataProvider.select(sel));
  }

  PlayerModel _watchSettings(WidgetRef ref) {
    return ref.watch(playerSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.5),
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
              _buildAniSkip(scheme),
              if (_watch(ref, (s) => s.sources.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _pill(
                    rounded: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    fontSize: 14,
                    text: '+85s',
                    onTap: widget.onForwardPressed,
                    color: scheme.primary,
                    textColor: Colors.black,
                    icon: Iconsax.forward,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProgressBar(context, scheme),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_watchSettings(ref).showNextPrevButtons) ...[
                    _icon(
                      Iconsax.previous,
                      () => ref
                          .read(episodeDataProvider.notifier)
                          .changeEpisode(null, by: -1),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildPlayPause(ref),
                  if (_watchSettings(ref).showNextPrevButtons) ...[
                    const SizedBox(width: 8),
                    _icon(
                      Iconsax.next,
                      () => ref
                          .read(episodeDataProvider.notifier)
                          .changeEpisode(null, by: 1),
                    ),
                  ],
                  const SizedBox(width: 16),
                  _buildTime(ref),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: [
                      if (_watch(ref, (s) => s.servers.isNotEmpty)) ...[
                        _pill(
                          fontSize: 12,
                          text: _watch(
                            ref,
                            (s) =>
                                s.selectedServer?.isDub == true ? 'DUB' : 'SUB',
                          ),
                          onTap: () => ref
                              .read(episodeDataProvider.notifier)
                              .toggleDubSub(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_watch(
                        ref,
                        (s) =>
                            s.servers.isNotEmpty &&
                            s.servers.any((e) => e.id != s.servers.first.id),
                      ))
                        _pill(
                          fontSize: 12,
                          icon: Iconsax.cloud,
                          text: _watch(
                            ref,
                            (s) =>
                                s.selectedServer?.id?.toUpperCase() ?? 'SERVER',
                          ),
                          onTap: widget.onServerPressed,
                        ),
                      if (_watch(ref, (s) => s.sources.length) > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill(
                            fontSize: 12,
                            icon: Icons.source_rounded,
                            text: _watch(ref, (s) {
                              final idx = s.selectedSourceIdx ?? 0;
                              return (idx >= 0 && idx < s.sources.length)
                                  ? s.sources[idx].quality ?? 'Auto'
                                  : 'Auto';
                            }),
                            onTap: widget.onSourcePressed,
                          ),
                        ),
                      const SizedBox(width: 4),
                      _icon(
                        _watch(ref, (s) => s.selectedSubtitleIdx != 0)
                            ? Iconsax.subtitle5
                            : Iconsax.subtitle,
                        widget.onSubtitlePressed,
                        onLong: () =>
                            context.push('/settings/player/subtitles'),
                      ),
                      _icon(Icons.lock_rounded, widget.onLockPressed),
                      _icon(
                        Icons.fullscreen_rounded,
                        widget.onFullScreenPressed,
                      ),
                      _icon(Icons.view_list_rounded, widget.onEpisodePressed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme scheme) {
    final (pos, dur, buf) = ref.watch(
      playerStateProvider.select((p) => (p.position, p.duration, p.buffer)),
    );
    final max = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final value = (_draggedValue ?? pos.inMilliseconds.toDouble()).clamp(
      0,
      max,
    );
    final buffer = buf.inMilliseconds.toDouble().clamp(0, max);

    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: box.maxWidth * (buffer / max),
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ..._buildHighlights(scheme, max, box.maxWidth),
                ],
              );
            },
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const _NoPaddingTrackShape(),
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackHeight: 4,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: value.toDouble(),
              max: max,
              onChanged: (val) {
                setState(() => _draggedValue = val);
                widget.onInteraction();
              },
              onChangeEnd: (val) {
                ref
                    .read(playerStateProvider.notifier)
                    .seek(Duration(milliseconds: val.round()));
                setState(() => _draggedValue = null);
                widget.onInteraction();
              },
            ),
          ),

          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final dx = constraints.maxWidth * (value / max);
                return IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(dx - 3, 0),
                      child: Container(
                        width: 6,
                        height: 20,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHighlights(
    ColorScheme scheme,
    double total,
    double maxWidth,
  ) {
    final skips = ref.watch(aniSkipProvider);
    final settings = ref.watch(playerSettingsProvider);

    if (!settings.enableAniSkip || skips.isEmpty || total <= 0) return [];

    return skips.map((skip) {
      if (skip.interval == null) return const SizedBox.shrink();
      final start = (skip.interval!.startTime * 1000).clamp(0, total);
      final end = (skip.interval!.endTime * 1000).clamp(0, total);
      if (end <= start) return const SizedBox.shrink();

      final left = (start / total) * maxWidth;
      final width = ((end - start) / total) * maxWidth;

      return Positioned(
        left: left,
        child: Container(
          width: width,
          height: 4,
          decoration: BoxDecoration(
            color: skip.skipType == SkipType.op
                ? Colors.greenAccent
                : Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTime(WidgetRef ref) {
    final (pos, dur) = ref.watch(
      playerStateProvider.select((p) => (p.position, p.duration)),
    );
    return Text(
      '${formatDuration(pos)} / ${formatDuration(dur)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildPlayPause(WidgetRef ref) {
    final isPlaying = ref.watch(playerStateProvider.select((p) => p.isPlaying));
    return InkWell(
      onTap: _wrap(ref.read(playerStateProvider.notifier).togglePlay),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Iconsax.pause5 : Iconsax.play5,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback? onTap, {VoidCallback? onLong}) {
    return InkWell(
      onTap: _wrap(onTap),
      onLongPress: _wrap(onLong),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _pill({
    required String text,
    required VoidCallback onTap,
    bool rounded = false,
    double fontSize = 11,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    Color? color,
    Color? textColor,
    IconData? icon,
  }) {
    return InkWell(
      onTap: _wrap(onTap),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(rounded ? 20 : 6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: fontSize * 1.4,
                color: textColor ?? Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAniSkip(ColorScheme scheme) {
    return Consumer(
      builder: (context, ref, _) {
        final skips = ref.watch(aniSkipProvider);
        final settings = ref.watch(playerSettingsProvider);
        if (!settings.enableAniSkip || skips.isEmpty) {
          return const SizedBox.shrink();
        }

        final pos = ref.watch(playerStateProvider.select((p) => p.position));
        final currentSkip = skips.firstWhere(
          (s) =>
              s.interval != null &&
              pos >= Duration(seconds: s.interval!.startTime.toInt()) &&
              pos < Duration(seconds: s.interval!.endTime.toInt()),
          orElse: () => const AniSkipResultItem(
            skipType: SkipType.unknown,
            action: '',
            episodeLength: 0,
          ),
        );

        if (currentSkip.interval == null) return const SizedBox.shrink();

        return _pill(
          rounded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          fontSize: 14,
          text: 'Skip ${currentSkip.skipType.name.toUpperCase()}',
          onTap: () {
            ref
                .read(playerStateProvider.notifier)
                .seek(
                  Duration(seconds: currentSkip.interval!.endTime.toInt() + 1),
                );
            widget.onInteraction();
          },
          color: Colors.white,
          textColor: Colors.black,
          icon: Icons.skip_next,
        );
      },
    );
  }
}

class _NoPaddingTrackShape extends RoundedRectSliderTrackShape {
  const _NoPaddingTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
