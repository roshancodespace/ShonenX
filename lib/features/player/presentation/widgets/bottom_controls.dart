import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/presentation/widgets/progress_bar.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class BottomControls extends ConsumerStatefulWidget {
  final bool showControls;
  final Function onToggleLockControls;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final ThemeData theme;
  final AniSkipArgs? aniskipArgs;
  final PlayerMode mode;
  final bool? isFullScreen;
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onShowEpisodePanel;

  const BottomControls({
    super.key,
    required this.showControls,
    required this.onToggleLockControls,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.theme,
    this.aniskipArgs,
    required this.mode,
    this.isFullScreen,
    this.onToggleFullScreen,
    this.onShowEpisodePanel,
  });

  @override
  ConsumerState<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends ConsumerState<BottomControls> {
  double? _dragingValue;
  bool _isFullScreen = false;
  bool _isPortrait = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.isFullScreen().then((val) {
        if (mounted) setState(() => _isFullScreen = val);
      });
    }
  }

  void _toggleFullScreen() async {
    if (widget.onToggleFullScreen != null) {
      widget.onToggleFullScreen!();
      return;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      bool isFull = await windowManager.isFullScreen();
      if (isFull) {
        await windowManager.setFullScreen(false);
        if (Platform.isWindows) {
          await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        }
        if (mounted) setState(() => _isFullScreen = false);
      } else {
        if (Platform.isWindows) {
          await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        }
        await windowManager.setFullScreen(true);
        if (mounted) setState(() => _isFullScreen = true);
      }
    }
  }

  void _toggleOrientation() {
    setState(() => _isPortrait = !_isPortrait);
    SystemChrome.setPreferredOrientations(
      _isPortrait
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final aniSkips = ref.watch(aniSkipProvider(widget.aniskipArgs));

    final isCompact = mediaQuery.size.width < 450;
    final isVeryCompact = mediaQuery.size.width < 350;

    final audioTracks = ref.watch(
      videoEngineStateProvider.select((s) => s.audioTracks),
    );
    final activeAudioTrack = ref.watch(
      videoEngineStateProvider.select((s) => s.activeAudioTrack),
    );
    final actualAudioCount = audioTracks
        .where((t) => t.id != 'auto' && t.id != 'no')
        .length;

    return AnimatedPositioned(
      duration: Durations.medium2,
      curve: Curves.fastEaseInToSlowEaseOut,
      bottom: widget.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: Durations.short4,
        opacity: widget.showControls ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: mediaQuery.padding.bottom + 12,
                top: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 10,
                      bottom: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildLeftControls(
                              audioTracks: audioTracks,
                              activeAudioTrack: activeAudioTrack,
                              actualAudioCount: actualAudioCount,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildSkipActionArea(theme: theme, aniSkips: aniSkips),
                      ],
                    ),
                  ),

                  ProgressBar(
                    aniSkips: aniSkips.value ?? [],
                    engine: widget.engine,
                    draggingValue: _dragingValue,
                    onDragStart: (value) {
                      setState(() => _dragingValue = value);
                    },
                    onChanged: (value) {
                      setState(() => _dragingValue = value);
                    },
                    onDragEnd: (value) {
                      widget.engine
                          .seekTo(Duration(seconds: value.toInt()))
                          .then((_) => setState(() => _dragingValue = null));
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        if (!isVeryCompact) _buildTimeDisplay(),

                        _buildRightControls(theme: theme, isCompact: isCompact),
                      ],
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

  Widget _buildSkipActionArea({
    required ThemeData theme,
    required AsyncValue<List<AniSkipStamp>> aniSkips,
  }) {
    return Consumer(
      builder: (context, aniRef, child) {
        final skips = aniSkips.value ?? [];
        final position = aniRef.watch(
          videoEngineStateProvider.select((s) => s.position),
        );
        final prefs = aniRef.watch(aniskipPrefsProvider);

        // ── Priority 1: AniSkip segment button ──────────────────────────
        final currentSkip = _findActiveSkip(skips, position);

        if (currentSkip != null &&
            prefs.mode(currentSkip.type) != SkipMode.off) {
          return _buildSkipSegmentButton(theme: theme, skip: currentSkip);
        }

        final playerPrefs = ref.watch(playerPrefsProvider);
        final duration = aniRef.watch(
          videoEngineStateProvider.select((s) => s.duration),
        );

        final autoNextResult = _checkAutoNext(
          position: position,
          duration: duration,
          playerPrefs: playerPrefs,
        );

        if (autoNextResult != null) {
          return _buildNextEpisodeButton(
            theme: theme,
            progress: autoNextResult,
            playerPrefs: playerPrefs,
          );
        }

        if (playerPrefs.showSkipButton && playerPrefs.skipDuration > 0) {
          return _buildQuickSkipButton(
            theme: theme,
            skipDuration: playerPrefs.skipDuration,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

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
        widget.controller.hasNextEpisode &&
        duration.inSeconds >= 60 &&
        position.inSeconds > 30 &&
        !widget.playerState.isLoading &&
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

  Widget _buildSkipSegmentButton({
    required ThemeData theme,
    required AniSkipStamp skip,
  }) {
    final label = switch (skip.type) {
      SkipType.opening => 'Skip Opening',
      SkipType.ending => 'Skip Ending',
      SkipType.mixedOpening => 'Skip Opening',
      SkipType.mixedEnding => 'Skip Ending',
      SkipType.recap => 'Skip Recap',
    };

    return _buildActionButton(
      leading: const Icon(Icons.skip_next_rounded),
      displayText: label,
      onTap: () async {
        await widget.engine.seekTo(Duration(seconds: skip.endTime.ceil()));
        if (skip.type == SkipType.ending || skip.type == SkipType.mixedEnding) {
          widget.controller.triggerEndingSkipCooldown();
        }
      },
      theme: theme,
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }

  Widget _buildNextEpisodeButton({
    required ThemeData theme,
    required double progress,
    required PlayerPrefsState playerPrefs,
  }) {
    return _buildActionButton(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          if (playerPrefs.autoNext)
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
      onTap: () async {
        await widget.controller.skipEpisode();
      },
      theme: theme,
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }

  Widget _buildQuickSkipButton({
    required ThemeData theme,
    required int skipDuration,
  }) {
    return _buildActionButton(
      leading: const Icon(Icons.skip_next_rounded),
      displayText: '+${skipDuration}s',
      onTap: () async {
        await widget.engine.seekRelative(Duration(seconds: skipDuration));
      },
      theme: theme,
      defaultAccentColor: theme.colorScheme.onSecondary,
      defaultBackgroundColor: theme.colorScheme.secondary,
    );
  }

  Widget _buildLeftControls({
    required List<AudioTrack> audioTracks,
    required AudioTrack? activeAudioTrack,
    required int actualAudioCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock controls button
        _buildActionIcon(
          Icons.lock_outline_rounded,
          () => widget.onToggleLockControls(),
        ),

        const SizedBox(width: 12),

        // Subtitle picker
        if (widget.playerState.subtitles.isNotEmpty)
          _buildBottomSheetTrigger(
            context: context,
            value: widget.playerState.activeSubtitle,
            items: widget.playerState.subtitles,
            itemLabel: (s) => s.language,
            onChanged: (v) {
              widget.controller.changeSubtitle(v);
            },
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (context) {
                  return const SubtitleSettingsSheet();
                },
              );
            },
            actions: [
              IconButton.filledTonal(
                tooltip: 'Customize Subtitles',
                style: IconButton.styleFrom(
                  backgroundColor: widget.theme.colorScheme.primary,
                  foregroundColor: widget.theme.colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                onPressed: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    builder: (context) => const SubtitleSettingsSheet(),
                  );
                },
              ),
            ],
            isDisabled: widget.playerState.subtitles.isEmpty,
            withBadge: false,
            displayText: 'Subtitles',
            displayWidget: Badge(
              label: Text((widget.playerState.subtitles.length - 1).toString()),
              isLabelVisible: widget.playerState.subtitles.isNotEmpty,
              backgroundColor: widget.theme.colorScheme.primary,
              textColor: widget.theme.colorScheme.onPrimary,
              child:
                  widget.playerState.subtitles.isEmpty ||
                      widget.playerState.activeSubtitle == null
                  ? Icon(
                      Icons.subtitles_off_outlined,
                      color: widget.playerState.subtitles.isEmpty
                          ? Colors.white54
                          : Colors.white,
                    )
                  : const Icon(Icons.subtitles_outlined),
            ),
          ),

        // Audio track picker
        if (actualAudioCount > 0) ...[
          const SizedBox(width: 12),
          _buildBottomSheetTrigger<AudioTrack>(
            context: context,
            value: activeAudioTrack,
            items: audioTracks,
            itemLabel: (s) => s.label,
            onChanged: (v) {
              widget.controller.changeAudioTrack(v);
            },
            withBadge: false,
            displayText: 'Audio',
            displayWidget: Badge(
              label: Text(actualAudioCount.toString()),
              isLabelVisible: actualAudioCount > 0,
              backgroundColor: widget.theme.colorScheme.primary,
              textColor: widget.theme.colorScheme.onPrimary,
              child: activeAudioTrack?.id == 'no'
                  ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                  : const Icon(Icons.audiotrack_outlined, color: Colors.white),
            ),
          ),
        ],

        // Episodes panel button
        if (widget.mode is PlayerModeOnline) ...[
          const SizedBox(width: 12),
          _buildActionIcon(Icons.format_list_bulleted_rounded, () {
            if (widget.onShowEpisodePanel != null) {
              widget.onShowEpisodePanel!();
            } else {
              _showEpisodePanel(context);
            }
          }),
        ],
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Consumer(
      builder: (context, ref, child) {
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
                style: widget.theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: ' / ${formatDuration(duration)}',
                style: widget.theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightControls({
    required ThemeData theme,
    required bool isCompact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubDubToggle(theme: theme),

        if (widget.playerState.servers.length > 1 && !isCompact) ...[
          _buildBottomSheetTrigger<VideoServer>(
            context: context,
            value: widget.playerState.activeServer,
            items: widget.playerState.servers,
            itemLabel: (s) => '[ ${trimText(s.id, maxLength: 30)} ] ${s.name}',
            onChanged: (v) {
              widget.controller.changeServer(v);
            },
            displayText: (() {
              final server = widget.playerState.activeServer;
              if (server == null) return 'Default';
              if (server.id.length <= 20) return server.id;
              final name = server.name;
              return name.length > 30 ? '${name.substring(0, 27)}...' : name;
            })(),
            badgeBuilder: (s) {
              if (s.type == ServerType.unknown) return null;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: s.type == ServerType.dub
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.type == ServerType.dub
                      ? 'DUB'
                      : s.type == ServerType.sub
                      ? 'SUB'
                      : '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: s.type == ServerType.dub
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondary,
                  ),
                ),
              );
            },
          ),
        ],

        if (widget.playerState.streams.length > 1 && !isCompact) ...[
          const SizedBox(width: 14),
          _buildBottomSheetTrigger<VideoStream>(
            context: context,
            value: widget.playerState.activeStream,
            items: widget.playerState.streams,
            itemLabel: (s) => s.quality,
            onChanged: (v) {
              widget.controller.changeStream(v);
            },
            displayText: widget.playerState.activeStream?.quality ?? 'Auto',
          ),
        ],

        if (Platform.isAndroid || Platform.isIOS) ...[
          const SizedBox(width: 14),
          _buildActionIcon(
            _isPortrait
                ? Icons.screen_lock_landscape_outlined
                : Icons.screen_lock_portrait_outlined,
            _toggleOrientation,
          ),
        ],

        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
          const SizedBox(width: 14),
          _buildActionIcon(
            (widget.isFullScreen ?? _isFullScreen)
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            _toggleFullScreen,
          ),
        ],
      ],
    );
  }

  Widget _buildSubDubToggle({required ThemeData theme}) {
    // Check if the source has separate sub and dub servers
    final hasServerToggle =
        widget.playerState.activeServer != null &&
        widget.playerState.servers.length > 1 &&
        widget.playerState.servers.any((e) => e.type == ServerType.sub) &&
        widget.playerState.servers.any((e) => e.type == ServerType.dub);

    bool isStreamDub(VideoStream? s) {
      if (s == null) return false;
      final q = s.quality.toLowerCase();
      return q.contains('dub') || q.contains('english');
    }

    // Check if streams have both sub and dub options in their labels
    final hasDubStream = widget.playerState.streams.any((e) => isStreamDub(e));
    final hasSubStream = widget.playerState.streams.any((e) => !isStreamDub(e));
    final hasStreamToggle =
        !hasServerToggle &&
        hasDubStream &&
        hasSubStream &&
        widget.playerState.streams.length > 1;

    if (!hasServerToggle && !hasStreamToggle) return const SizedBox.shrink();

    final isCurrentlyDub = hasServerToggle
        ? widget.playerState.activeServer?.type == ServerType.dub
        : isStreamDub(widget.playerState.activeStream);

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: _buildActionButton(
        displayText: isCurrentlyDub ? 'DUB' : 'SUB',
        onTap: () {
          if (hasServerToggle) {
            widget.controller.changeServerType();
          } else {
            widget.controller.changeStreamType();
          }
        },
        isHighlighted: true,
        highlightedAccentColor: isCurrentlyDub
            ? widget.theme.colorScheme.primary
            : widget.theme.colorScheme.secondary,
        highlightedBackgroundColor: isCurrentlyDub
            ? widget.theme.colorScheme.primary.withValues(alpha: 0.1)
            : widget.theme.colorScheme.secondary.withValues(alpha: 0.1),
        theme: widget.theme,
      ),
    );
  }

  void _showEpisodePanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Episodes',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.38,
          height: double.infinity,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currentEpisode = ref.watch(
                        playerControllerProvider.select((s) => s.activeEpisode),
                      );
                      if (currentEpisode == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return EpisodeListPanel(
                        media: (widget.mode as PlayerModeOnline).media,
                        currentEpisodeNumber: currentEpisode.number,
                        onEpisodeTap: (episode, sourceInfo) {
                          Navigator.of(context).pop();
                          ref
                              .read(playerControllerProvider.notifier)
                              .loadEpisode(episode);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildActionButton({
    required String displayText,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isHighlighted = false,
    Widget? leading,
    Color? highlightedAccentColor,
    Color? defaultAccentColor,
    Color? highlightedBackgroundColor,
    Color? defaultBackgroundColor,
  }) {
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
                child: leading,
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

  Widget _buildBottomSheetTrigger<T>({
    required BuildContext context,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T) onChanged,
    void Function()? onLongPress,
    bool? isDisabled,
    bool withBadge = true,
    String? displayText,
    Widget? displayWidget,
    bool isHighlighted = false,
    Widget? Function(T)? badgeBuilder,
    List<Widget>? actions,
  }) {
    return Badge(
      label: Text(items.length.toString()),
      isLabelVisible: withBadge && items.length > 1,
      backgroundColor: widget.theme.colorScheme.primary,
      textColor: widget.theme.colorScheme.onPrimary,
      child: InkWell(
        onTap: isDisabled == true
            ? null
            : () {
                AppBottomSheet.showSelector<T>(
                  context: context,
                  title: displayText ?? '',
                  items: items,
                  selectedValue: value,
                  itemLabel: itemLabel,
                  badgeBuilder: badgeBuilder,
                  onChanged: onChanged,
                  actions: actions,
                );
              },
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
                          text: displayText,
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
