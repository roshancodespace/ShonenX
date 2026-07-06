import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final aniSkips = ref.watch(aniSkipProvider(widget.aniskipArgs));

    ref.listen(videoEngineStateProvider.select((s) => s.position), (
      previous,
      current,
    ) {
      if (current.inSeconds > 0) {
        widget.controller.setupAutoSkipListener(widget.aniskipArgs);
      }
    });

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
        child: Container(
          padding: EdgeInsets.only(
            bottom: mediaQuery.padding.bottom + 12,
            top: 40,
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer(
                    builder: (aniContext, aniRef, child) {
                      final skips = aniSkips.value ?? [];

                      final position = aniRef.watch(
                        videoEngineStateProvider.select((s) => s.position),
                      );

                      final prefs = aniRef.watch(aniskipPrefsProvider);

                      final currentSkip = skips
                          .cast<AniSkipStamp?>()
                          .firstWhere((skip) {
                            if (skip == null) {
                              return false;
                            }

                            final seconds = position.inSeconds;

                            return seconds >= skip.startTime &&
                                seconds <= skip.endTime;
                          }, orElse: () => null);

                      if (currentSkip != null &&
                          prefs.mode(currentSkip.type) != SkipMode.off) {
                        final label = switch (currentSkip.type) {
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
                            await widget.engine.seekTo(
                              Duration(seconds: currentSkip.endTime.ceil()),
                            );
                          },
                          theme: theme,
                          defaultAccentColor: theme.colorScheme.onSecondary,
                          defaultBackgroundColor: theme.colorScheme.secondary,
                        );
                      }

                      return _buildActionButton(
                        leading: const Icon(Icons.skip_next_rounded),
                        displayText: '+85s',
                        onTap: () async {
                          await widget.engine.seekRelative(
                            const Duration(seconds: 85),
                          );
                        },
                        theme: theme,
                        defaultAccentColor: theme.colorScheme.onSecondary,
                        defaultBackgroundColor: theme.colorScheme.secondary,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                ],
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionIcon(
                          Icons.lock_outline_rounded,
                          () => widget.onToggleLockControls(),
                        ),

                        const SizedBox(width: 12),

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
                                constraints: const BoxConstraints(
                                  maxWidth: double.infinity,
                                ),
                                builder: (context) {
                                  return const SubtitleSettingsSheet();
                                },
                              );
                            },
                            actions: [
                              IconButton.filledTonal(
                                tooltip: 'Customize Subtitles',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      widget.theme.colorScheme.primary,
                                  foregroundColor:
                                      widget.theme.colorScheme.onPrimary,
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
                                    builder: (context) =>
                                        const SubtitleSettingsSheet(),
                                  );
                                },
                              ),
                            ],
                            isDisabled: widget.playerState.subtitles.isEmpty,
                            withBadge: false,
                            displayText: 'Subtitles',
                            displayWidget: Badge(
                              label: Text(
                                (widget.playerState.subtitles.length - 1)
                                    .toString(),
                              ),
                              isLabelVisible:
                                  widget.playerState.subtitles.isNotEmpty,
                              backgroundColor: widget.theme.colorScheme.primary,
                              textColor: widget.theme.colorScheme.onPrimary,
                              child:
                                  widget.playerState.subtitles.isEmpty ||
                                      widget.playerState.activeSubtitle == null
                                  ? Icon(
                                      Icons.subtitles_off_outlined,
                                      color:
                                          widget.playerState.subtitles.isEmpty
                                          ? Colors.white54
                                          : Colors.white,
                                    )
                                  : const Icon(Icons.subtitles_outlined),
                            ),
                          ),

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
                                  ? const Icon(
                                      Icons.volume_off_outlined,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.audiotrack_outlined,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],

                        if (widget.mode is PlayerModeOnline) ...[
                          const SizedBox(width: 12),
                          _buildActionIcon(
                            Icons.format_list_bulleted_rounded,
                            () {
                              if (widget.onShowEpisodePanel != null) {
                                widget.onShowEpisodePanel!();
                              } else {
                                _showEpisodePanel(context);
                              }
                            },
                          ),
                        ],
                      ],
                    ),

                    if (!isVeryCompact)
                      Consumer(
                        builder: (context, ref, child) {
                          final position = ref.watch(
                            videoEngineStateProvider.select((s) => s.position),
                          );

                          final duration = ref.watch(
                            videoEngineStateProvider.select((s) => s.duration),
                          );

                          return Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: widget.theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.playerState.activeServer != null &&
                            widget.playerState.servers.length > 1 &&
                            widget.playerState.servers.any(
                              (e) => e.type == ServerType.sub,
                            ) &&
                            widget.playerState.servers.any(
                              (e) => e.type == ServerType.dub,
                            ))
                          _buildActionButton(
                            displayText:
                                widget.playerState.activeServer?.type ==
                                    ServerType.dub
                                ? 'DUB'
                                : 'SUB',
                            onTap: () {
                              widget.controller.changeServerType();
                            },
                            isHighlighted: true,
                            highlightedAccentColor:
                                widget.playerState.activeServer?.type ==
                                    ServerType.dub
                                ? widget.theme.colorScheme.primary
                                : widget.theme.colorScheme.secondary,
                            highlightedBackgroundColor:
                                widget.playerState.activeServer?.type ==
                                    ServerType.dub
                                ? widget.theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : widget.theme.colorScheme.secondary.withValues(
                                    alpha: 0.1,
                                  ),
                            theme: widget.theme,
                          ),

                        if (widget.playerState.servers.length > 1 &&
                            !isCompact) ...[
                          const SizedBox(width: 14),
                          _buildBottomSheetTrigger<VideoServer>(
                            context: context,
                            value: widget.playerState.activeServer,
                            items: widget.playerState.servers,
                            itemLabel: (s) =>
                                '[ ${trimText(s.id, maxLength: 30)} ] ${s.name}',
                            onChanged: (v) {
                              widget.controller.changeServer(v);
                            },
                            displayText: (() {
                              final server = widget.playerState.activeServer;

                              if (server == null) return 'Default';

                              if (server.id.length <= 20) {
                                return server.id;
                              }

                              final name = server.name;
                              return name.length > 30
                                  ? '${name.substring(0, 27)}...'
                                  : name;
                            })(),
                            badgeBuilder: (s) {
                              if (s.type == ServerType.unknown) {
                                return null;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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

                        if (widget.playerState.streams.length > 1 &&
                            !isCompact) ...[
                          const SizedBox(width: 14),
                          _buildBottomSheetTrigger<VideoStream>(
                            context: context,
                            value: widget.playerState.activeStream,
                            items: widget.playerState.streams,
                            itemLabel: (s) => s.quality,
                            onChanged: (v) {
                              widget.controller.changeStream(v);
                            },
                            displayText:
                                widget.playerState.activeStream?.quality ??
                                'Auto',
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

                        if (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS) ...[
                          const SizedBox(width: 14),
                          _buildActionIcon(
                            (widget.isFullScreen ?? _isFullScreen)
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            _toggleFullScreen,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: isHighlighted
                              ? const Color(0xFFBCAAE0)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}
