import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/aniskip/aniskip_result.dart';
import 'package:shonenx/core/utils/formatter.dart';
import 'package:shonenx/features/anime/view_model/aniskip_notifier.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/helpers/show_subtitle_sidebar.dart';
import 'package:shonenx/shared/providers/settings/player_notifier.dart';

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
  double _dragPositionX = 0.0;

  // VoidCallback _wrap(VoidCallback? cb) {
  //   return () {
  //     cb?.call();
  //     widget.onInteraction();
  //   };
  // }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // final settings = ref.watch(playerSettingsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.black87, Colors.transparent],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildAniSkip(scheme),
                  if (ref.watch(
                    episodeDataProvider.select((s) => s.sources.isNotEmpty),
                  )) ...[
                    const SizedBox(width: 8),
                    _FlatActionBtn(
                      text: '+85s',
                      icon: Icons.fast_forward_rounded,
                      onTap: widget.onForwardPressed,
                      color: Colors.white24,
                      textColor: Colors.white,
                    ),
                  ],
                ],
              ),
            ),

            _buildEdgeScrubber(context, scheme),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeDisplay(),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FlatTextBtn(
                            text: ref.watch(
                              episodeDataProvider.select(
                                (s) => s.selectedServer?.isDub == true
                                    ? 'DUB'
                                    : 'SUB',
                              ),
                            ),
                            onTap: () => ref
                                .read(episodeDataProvider.notifier)
                                .toggleDubSub(),
                            isAccent: true,
                            scheme: scheme,
                          ),
                          _FlatTextBtn(
                            text: ref.watch(
                              episodeDataProvider.select(
                                (s) =>
                                    s.selectedServer?.id?.toUpperCase() ??
                                    'SERVER',
                              ),
                            ),
                            onTap: widget.onServerPressed,
                          ),
                          _FlatTextBtn(
                            text: ref.watch(
                              episodeDataProvider.select(
                                (s) => s.selectedSourceIdx != null
                                    ? (s.sources[s.selectedSourceIdx!].quality
                                              ?.toUpperCase() ??
                                          'SOURCE')
                                    : 'SOURCE',
                              ),
                            ),
                            onTap: widget.onSourcePressed,
                          ),
                          _ToolbarIcon(
                            icon: Icons.lock_outline_rounded,
                            onTap: widget.onLockPressed,
                          ),
                          _ToolbarIcon(
                            icon: Icons.subtitles_rounded,
                            onTap: widget.onSubtitlePressed,
                            onHold: () => showSubtitleSettings(context),
                          ),
                          _ToolbarIcon(
                            icon: Icons.view_list_rounded,
                            onTap: widget.onEpisodePressed,
                          ),
                          if (!(Platform.isAndroid || Platform.isIOS))
                            _ToolbarIcon(
                              icon: Icons.fullscreen_rounded,
                              onTap: widget.onFullScreenPressed,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeScrubber(BuildContext context, ColorScheme scheme) {
    final (pos, dur, buf) = ref.watch(
      playerStateProvider.select((p) => (p.position, p.duration, p.buffer)),
    );
    final max = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final value = (_draggedValue ?? pos.inMilliseconds.toDouble()).clamp(
      0,
      max,
    );
    final buffer = buf.inMilliseconds.toDouble().clamp(0, max);
    final isDragging = _draggedValue != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => widget.onInteraction(),
          onHorizontalDragUpdate: (details) {
            final percent = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            setState(() {
              _draggedValue = percent * max;
              _dragPositionX = details.localPosition.dx;
            });
            widget.onInteraction();
          },
          onHorizontalDragEnd: (details) {
            if (_draggedValue != null) {
              ref
                  .read(playerStateProvider.notifier)
                  .seek(Duration(milliseconds: _draggedValue!.round()));
              setState(() => _draggedValue = null);
              widget.onInteraction();
            }
          },
          onTapDown: (details) {
            final percent = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            ref
                .read(playerStateProvider.notifier)
                .seek(Duration(milliseconds: (percent * max).round()));
            widget.onInteraction();
          },
          child: SizedBox(
            height: 10,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: isDragging ? 6 : 3,
                  width: double.infinity,
                  color: Colors.white24,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      FractionallySizedBox(
                        widthFactor: buffer / max,
                        child: Container(color: Colors.white38),
                      ),
                      ..._buildHighlights(scheme, max, constraints.maxWidth),
                      FractionallySizedBox(
                        widthFactor: value / max,
                        child: Container(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
                if (isDragging)
                  Positioned(
                    left: (value / max) * constraints.maxWidth - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (isDragging)
                  Positioned(
                    left: (_dragPositionX - 25).clamp(
                      10.0,
                      constraints.maxWidth - 50.0,
                    ),
                    top: -20,
                    child: Text(
                      formatDuration(Duration(milliseconds: value.round())),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

      return Positioned(
        left: (start / total) * maxWidth,
        width: ((end - start) / total) * maxWidth,
        top: 0,
        bottom: 0,
        child: Container(
          color: skip.skipType == SkipType.op
              ? scheme.tertiary
              : scheme.secondary,
        ),
      );
    }).toList();
  }

  // Widget _buildPlayPauseButton(ColorScheme scheme) {
  //   final isPlaying = ref.watch(playerStateProvider.select((p) => p.isPlaying));
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: _wrap(ref.read(playerStateProvider.notifier).togglePlay),
  //       borderRadius: BorderRadius.circular(30),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //         child: Icon(
  //           isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
  //           color: Colors.white,
  //           size: 36,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTimeDisplay() {
    final (pos, dur) = ref.watch(
      playerStateProvider.select((p) => (p.position, p.duration)),
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formatDuration(pos),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(
            text: '  /  ',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: formatDuration(dur),
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.5,
        // tabularFigures ensures the text width doesn't jump around as seconds tick
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildAniSkip(ColorScheme scheme) {
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

    return _FlatActionBtn(
      text: 'Skip ${currentSkip.skipType.name.toUpperCase()}',
      icon: Icons.fast_forward_rounded,
      onTap: () {
        ref
            .read(playerStateProvider.notifier)
            .seek(Duration(seconds: currentSkip.interval!.endTime.toInt() + 1));
        widget.onInteraction();
      },
      color: scheme.primary,
      textColor: scheme.onPrimary,
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onHold;

  const _ToolbarIcon({required this.icon, this.onTap, this.onHold});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onHold,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _FlatTextBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isAccent;
  final ColorScheme? scheme;

  const _FlatTextBtn({
    required this.text,
    required this.onTap,
    this.isAccent = false,
    this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: isAccent
            ? scheme?.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              text,
              style: TextStyle(
                color: isAccent ? scheme?.primary : Colors.white70,
                fontSize: 12,
                fontWeight: isAccent ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatActionBtn extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _FlatActionBtn({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
