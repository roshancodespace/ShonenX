import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';

export 'bottom_controls.dart';
export 'center_controls.dart';
export 'player_controls_overlay.dart';
export 'progress_bar.dart';
export 'top_controls.dart';

// ============================================================================
// BASE PLAYER BUTTONS
// ============================================================================

/// Reusable icon button for player overlay controls with touch feedback.
class PlayerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color color;
  final String? tooltip;

  const PlayerIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.padding = const EdgeInsets.all(4.0),
    this.color = Colors.white,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: padding,
        child: Icon(icon, color: color, size: size),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Reusable action pill/button for player overlay controls (skip, dub/sub, etc.).
class PlayerActionButton extends StatelessWidget {
  final String displayText;
  final VoidCallback onTap;
  final bool isHighlighted;
  final Widget? leading;
  final Color? highlightedAccentColor;
  final Color? defaultAccentColor;
  final Color? highlightedBackgroundColor;
  final Color? defaultBackgroundColor;

  const PlayerActionButton({
    super.key,
    required this.displayText,
    required this.onTap,
    this.isHighlighted = false,
    this.leading,
    this.highlightedAccentColor,
    this.defaultAccentColor,
    this.highlightedBackgroundColor,
    this.defaultBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = isHighlighted
        ? (highlightedAccentColor ?? theme.colorScheme.onPrimaryContainer)
        : (defaultAccentColor ?? Colors.white70);

    final backgroundColor = isHighlighted
        ? (highlightedBackgroundColor ?? theme.colorScheme.primaryContainer)
        : (defaultBackgroundColor ?? Colors.transparent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: isHighlighted
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme(
                data: IconThemeData(size: 16, color: foregroundColor),
                child: leading!,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              displayText,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable trigger button that launches a bottom sheet selector with badge count.
class PlayerBottomSheetTrigger<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;
  final VoidCallback? onLongPress;
  final bool? isDisabled;
  final bool withBadge;
  final String? displayText;
  final Widget? displayWidget;
  final bool isHighlighted;
  final String? Function(T)? subtitleBuilder;
  final Widget? Function(T)? badgeBuilder;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const PlayerBottomSheetTrigger({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.onLongPress,
    this.isDisabled,
    this.withBadge = true,
    this.displayText,
    this.displayWidget,
    this.isHighlighted = false,
    this.badgeBuilder,
    this.subtitleBuilder,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Badge(
      label: Text(items.length.toString()),
      isLabelVisible: withBadge && items.length > 1,
      backgroundColor: theme.colorScheme.primary,
      textColor: theme.colorScheme.onPrimary,
      child: InkWell(
        onTap: isDisabled == true
            ? null
            : (onTap ??
                  () {
                    AppBottomSheet.showSelector<T>(
                      context: context,
                      title: displayText ?? '',
                      items: items,
                      selectedValue: value,
                      itemLabel: itemLabel,
                      badgeBuilder: badgeBuilder,
                      subtitleBuilder: subtitleBuilder,
                      onChanged: onChanged,
                      actions: actions,
                    );
                  }),
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          padding: isHighlighted
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : EdgeInsets.zero,
          decoration: isHighlighted
              ? BoxDecoration(
                  color: const Color(0xFF343040),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child:
              displayWidget ??
              (displayText != null
                  ? Padding(
                      padding: isHighlighted
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 10,
                            ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: MarqueeText(
                          text: displayText!,
                          style: TextStyle(
                            color: isHighlighted
                                ? const Color(0xFFBCAAE0)
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

// ============================================================================
// SEEK & SKIP CONTROLS
// ============================================================================

/// AniSkip segment button (e.g. Skip Opening, Skip Ending, Skip Recap).
class PlayerSkipSegmentButton extends StatelessWidget {
  final AniSkipStamp skip;
  final VideoEngine engine;
  final PlayerController controller;

  const PlayerSkipSegmentButton({
    super.key,
    required this.skip,
    required this.engine,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (skip.type) {
      SkipType.opening => 'Skip Opening',
      SkipType.ending => 'Skip Ending',
      SkipType.mixedOpening => 'Skip Opening',
      SkipType.mixedEnding => 'Skip Ending',
      SkipType.recap => 'Skip Recap',
    };

    return PlayerActionButton(
      leading: const Icon(Icons.skip_next_rounded),
      displayText: label,
      onTap: () async {
        await engine.seekTo(Duration(seconds: skip.endTime.ceil()));
        if (skip.type == SkipType.ending || skip.type == SkipType.mixedEnding) {
          controller.triggerEndingSkipCooldown();
        }
      },
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }
}

/// Next episode button with auto-next circular progress indicator countdown.
class PlayerNextEpisodeButton extends StatelessWidget {
  final double progress;
  final bool autoNext;
  final VoidCallback onTap;

  const PlayerNextEpisodeButton({
    super.key,
    required this.progress,
    required this.autoNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlayerActionButton(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          if (autoNext)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          const Icon(Icons.skip_next_rounded, size: 18),
        ],
      ),
      displayText: 'Next Episode',
      onTap: onTap,
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }
}

/// Quick skip button (+duration seconds).
class PlayerQuickSkipButton extends StatelessWidget {
  final int skipDuration;
  final VoidCallback onTap;

  const PlayerQuickSkipButton({
    super.key,
    required this.skipDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlayerActionButton(
      leading: const Icon(Icons.skip_next_rounded),
      displayText: '+$skipDuration s',
      onTap: onTap,
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }
}

/// Smart container handling active AniSkip, auto-next countdown, or quick-skip button.
class PlayerSkipActionArea extends ConsumerWidget {
  final AsyncValue<List<AniSkipStamp>> aniSkips;
  final VideoEngine engine;
  final PlayerController controller;
  final PlayerState playerState;

  const PlayerSkipActionArea({
    super.key,
    required this.aniSkips,
    required this.engine,
    required this.controller,
    required this.playerState,
  });

  AniSkipStamp? _findActiveSkip(List<AniSkipStamp> skips, Duration position) {
    final seconds = position.inSeconds;
    for (final skip in skips) {
      if (seconds >= skip.startTime && seconds < skip.endTime) {
        return skip;
      }
    }
    return null;
  }

  double? _checkAutoNext({
    required Duration position,
    required Duration duration,
    required PlayerPrefsState playerPrefs,
  }) {
    final remaining = duration.inSeconds - position.inSeconds;

    final isNearEnd =
        controller.hasNextEpisode &&
        duration.inSeconds >= 60 &&
        position.inSeconds > 30 &&
        !playerState.isLoading &&
        (remaining <= playerPrefs.nextEpisodeThreshold ||
            position.inSeconds >= duration.inSeconds);

    if (!isNearEnd) return null;

    final progress = playerPrefs.nextEpisodeThreshold > 0
        ? ((playerPrefs.nextEpisodeThreshold - remaining) /
                  playerPrefs.nextEpisodeThreshold)
              .clamp(0.0, 1.0)
        : 1.0;

    return progress;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skips = aniSkips.value ?? [];
    final position = ref.watch(
      videoEngineStateProvider.select((s) => s.position),
    );
    final prefs = ref.watch(aniskipPrefsProvider);

    // ── Priority 1: AniSkip segment button ──────────────────────────
    final currentSkip = _findActiveSkip(skips, position);

    if (currentSkip != null && prefs.mode(currentSkip.type) != SkipMode.off) {
      return PlayerSkipSegmentButton(
        skip: currentSkip,
        engine: engine,
        controller: controller,
      );
    }

    final playerPrefs = ref.watch(playerPrefsProvider);
    final duration = ref.watch(
      videoEngineStateProvider.select((s) => s.duration),
    );

    final autoNextResult = _checkAutoNext(
      position: position,
      duration: duration,
      playerPrefs: playerPrefs,
    );

    if (autoNextResult != null) {
      return PlayerNextEpisodeButton(
        progress: autoNextResult,
        autoNext: playerPrefs.autoNext,
        onTap: () async {
          await controller.skipEpisode();
        },
      );
    }

    if (playerPrefs.showSkipButton && playerPrefs.skipDuration > 0) {
      return PlayerQuickSkipButton(
        skipDuration: playerPrefs.skipDuration,
        onTap: () async {
          await engine.seekRelative(
            Duration(seconds: playerPrefs.skipDuration),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================================
// PLAYBACK & NAVIGATION CONTROLS
// ============================================================================

/// Large centered play/pause button with animated icon rotation and fade transitions.
class PlayerPlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onToggle;

  const PlayerPlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.4,
          ),
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        ),
        onPressed: onToggle,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == ValueKey(isPlaying);
            final rotation = Tween<double>(
              begin: isIncoming ? -0.25 : 0.25,
              end: 0.0,
            ).animate(animation);

            return RotationTransition(
              turns: rotation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            size: 80,
          ),
        ),
      ),
    );
  }
}

/// Episode navigation skip button (previous or next episode).
class PlayerEpisodeNavButton extends StatelessWidget {
  final bool isNext;
  final bool isEnabled;
  final VoidCallback? onTap;

  const PlayerEpisodeNavButton({
    super.key,
    required this.isNext,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isEnabled ? onTap : null,
      icon: Icon(
        isNext ? Icons.skip_next_outlined : Icons.skip_previous_outlined,
        size: 60,
      ),
      color: isEnabled ? Colors.white : Colors.grey,
    );
  }
}

// ============================================================================
// QUALITY & SOURCE CONTROLS
// ============================================================================

/// Quality dropdown button displayed on the top controls bar.
class PlayerQualityButton extends StatelessWidget {
  final String qualityText;
  final VoidCallback onTap;

  const PlayerQualityButton({
    super.key,
    required this.qualityText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              qualityText.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// SUB / DUB toggle button displayed on the bottom controls bar.
class PlayerSubDubToggle extends StatelessWidget {
  final PlayerState playerState;
  final PlayerController controller;

  const PlayerSubDubToggle({
    super.key,
    required this.playerState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if the source has separate sub and dub servers
    final hasServerToggle =
        playerState.activeServer != null &&
        playerState.servers.length > 1 &&
        playerState.servers.any((e) => e.type == ServerType.sub) &&
        playerState.servers.any((e) => e.type == ServerType.dub);

    bool isStreamDub(VideoStream? s) {
      if (s == null) return false;
      final q = s.quality.toLowerCase();
      return q.contains('dub') || q.contains('english');
    }

    // Check if streams have both sub and dub options in their labels
    final hasDubStream = playerState.streams.any((e) => isStreamDub(e));
    final hasSubStream = playerState.streams.any((e) => !isStreamDub(e));
    final hasStreamToggle =
        !hasServerToggle &&
        hasDubStream &&
        hasSubStream &&
        playerState.streams.length > 1;

    if (!hasServerToggle && !hasStreamToggle) return const SizedBox.shrink();

    final isCurrentlyDub = hasServerToggle
        ? playerState.activeServer?.type == ServerType.dub
        : isStreamDub(playerState.activeStream);

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: PlayerActionButton(
        displayText: isCurrentlyDub ? 'DUB' : 'SUB',
        onTap: () {
          if (hasServerToggle) {
            controller.changeServerType();
          } else {
            controller.changeStreamType();
          }
        },
        isHighlighted: true,
        highlightedAccentColor: isCurrentlyDub
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        highlightedBackgroundColor: isCurrentlyDub
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.secondary.withValues(alpha: 0.1),
      ),
    );
  }
}

// ============================================================================
// DISPLAY & UTILITY CONTROLS
// ============================================================================

/// Position and duration playback time indicator.
class PlayerTimeDisplay extends ConsumerWidget {
  const PlayerTimeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final position = ref.watch(
      videoEngineStateProvider.select((s) => s.position),
    );
    final duration = ref.watch(
      videoEngineStateProvider.select((s) => s.duration),
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatDuration(position),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: ' / ${formatDuration(duration)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
