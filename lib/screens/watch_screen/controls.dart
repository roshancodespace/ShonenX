import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/helpers/player/gesture_handler.dart';
import 'package:shonenx/helpers/player/overlay_manager.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/widgets/player/bottom_controls.dart';
import 'package:shonenx/widgets/player/center_controls.dart';
import 'package:shonenx/widgets/player/seek_bar.dart';
import 'package:shonenx/widgets/player/selector_tile.dart';
import 'package:shonenx/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/widgets/player/top_controls.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:shonenx/widgets/ui/shonenx_icon_btn.dart';
import 'dart:io';

// Intents for keyboard shortcuts
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class SeekForwardIntent extends Intent {
  const SeekForwardIntent();
}

class SeekBackwardIntent extends Intent {
  const SeekBackwardIntent();
}

class ToggleFullscreenIntent extends Intent {
  const ToggleFullscreenIntent();
}

class CustomControls extends ConsumerStatefulWidget {
  final media_kit_video.VideoState state;
  final AnimationController panelAnimationController;

  const CustomControls({
    super.key,
    required this.state,
    required this.panelAnimationController,
  });

  @override
  ConsumerState<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends ConsumerState<CustomControls> {
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  static const _autoHideDuration = Duration(seconds: 3);
  static const _seekDuration = Duration(seconds: 10);
  bool _isFullscreen = false;
  late GestureHandler _gestureHandler;
  late OverlayManager _overlayManager;

  @override
  void initState() {
    super.initState();
    _scheduleHideControls();
    _isFullscreen = widget.state.isFullscreen();
    _overlayManager = OverlayManager();
    _gestureHandler = GestureHandler(
      resetTimer: _resetTimer,
      showOverlay: (context, {required bool isBrightness}) =>
          _overlayManager.showAdjustmentOverlay(
        context,
        isBrightness: isBrightness,
        value: isBrightness
            ? _gestureHandler.brightnessValue
            : _gestureHandler.volumeValue,
      ),
    );

    if (mounted) {
      setState(() {
        _isFullscreen = widget.state.isFullscreen();
        if (!_isFullscreen) {
          _hideControlsTimer?.cancel();
          _controlsVisible = true;
          _scheduleHideControls();
        }
      });
      _gestureHandler.initialize();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _overlayManager.dispose();
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_controlsVisible || !mounted || !_isFullscreen) return;

    _hideControlsTimer = Timer(_autoHideDuration, () {
      if (mounted && _controlsVisible) {
        setState(() => _controlsVisible = false);
        developer.log('Controls auto-hidden', name: 'CustomControls');
      }
    });
  }

  void _toggleControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _showControls() {
    if (!mounted || _controlsVisible) return;
    setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _resetTimer() {
    if (_controlsVisible && mounted) {
      _scheduleHideControls();
    }
  }

  Future<void> _handleDoubleTap(
      BuildContext context, TapDownDetails details) async {
    // Only enable on mobile
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final playerNotifier = ref.read(playerStateProvider.notifier);
    final playerState = ref.read(playerStateProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPositionX = details.globalPosition.dx;

    if (tapPositionX < screenWidth / 2) {
      await playerNotifier.seek(playerState.position - _seekDuration);
      if (context.mounted) {
        _overlayManager.showSeekIndicator(context, isForward: false);
      }
    } else {
      await playerNotifier.seek(playerState.position + _seekDuration);
      if (context.mounted) {
        _overlayManager.showSeekIndicator(context, isForward: true);
      }
    }
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);
    final playerSettings = ref.watch(playerSettingsProvider).playerSettings;
    final watchState = ref.watch(watchProvider);
    final theme = Theme.of(context);
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): PlayPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): SeekForwardIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): SeekBackwardIntent(),
        SingleActivator(LogicalKeyboardKey.keyF): ToggleFullscreenIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ToggleFullscreenIntent(),
      },
      child: Actions(
        actions: {
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) {
              _toggleControls();
              return playerNotifier.playOrPause();
            },
          ),
          SeekForwardIntent: CallbackAction<SeekForwardIntent>(
            onInvoke: (_) {
              _resetTimer();
              return playerNotifier.seek(playerState.position + _seekDuration);
            },
          ),
          SeekBackwardIntent: CallbackAction<SeekBackwardIntent>(
            onInvoke: (_) {
              _resetTimer();
              return playerNotifier.seek(playerState.position - _seekDuration);
            },
          ),
          ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
            onInvoke: (_) {
              _resetTimer();
              return widget.state.toggleFullscreen();
            },
          ),
        },
        child: Focus(
          autofocus: isDesktop,
          child: MouseRegion(
            onHover: (_) => isDesktop ? _showControls() : null,
            cursor: isDesktop && _isFullscreen && !_controlsVisible
                ? SystemMouseCursors.none
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: _toggleControls,
              onDoubleTapDown: (details) => _handleDoubleTap(context, details),
              // Only enable gestures on mobile
              onPanStart: Platform.isAndroid || Platform.isIOS
                  ? (details) => _gestureHandler.onPanStart(context, details)
                  : null,
              onPanUpdate: Platform.isAndroid || Platform.isIOS
                  ? (details) => _gestureHandler.onPanUpdate(context, details)
                  : null,
              onPanEnd: Platform.isAndroid || Platform.isIOS
                  ? (_) => _gestureHandler.onPanEnd()
                  : null,
              child: Stack(
                children: [
                  Positioned(
                    bottom: _controlsVisible ? 100 : 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SubtitleOverlay(
                        subtitleStyle: playerSettings.toSubtitleStyle(),
                        subtitle: playerState.subtitle.firstOrNull ?? '',
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AbsorbPointer(
                      absorbing: !_controlsVisible,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: TopControls(
                                    watchState: watchState,
                                    onPanelToggle: () async {
                                      _resetTimer();
                                      if (_isFullscreen) {
                                        await widget.state.exitFullscreen();
                                      }
                                      await ref
                                          .read(watchProvider.notifier)
                                          .togglePanel(
                                              widget.panelAnimationController);
                                    },
                                    onQualityTap: () => _showQualitySelector(
                                      context,
                                      ref,
                                      watchState.qualityOptions,
                                      watchState.selectedQualityIdx,
                                    ),
                                    onSubtitleTap: () => _showSubtitleSelector(
                                      context,
                                      ref,
                                      watchState.subtitles,
                                      watchState.selectedSubtitleIdx,
                                    ),
                                    onFullscreenTap: () async {
                                      _resetTimer();

                                      await widget.state.toggleFullscreen();
                                      if (!watchState.isExpanded &&
                                          !_isFullscreen) {
                                        await ref
                                            .read(watchProvider.notifier)
                                            .togglePanel(widget
                                                .panelAnimationController);
                                      }
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: CenterControls(
                                    isPlaying: playerState.isPlaying,
                                    isBuffering: playerState.isBuffering,
                                    onTap: () {
                                      _resetTimer();
                                      playerNotifier.playOrPause();
                                    },
                                    theme: theme,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if ((playerState.position.inSeconds /
                                                  playerState
                                                      .duration.inSeconds) *
                                              100.0 >=
                                          85)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ShonenXIconButton(
                                              icon: Iconsax.next5,
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        watchProvider.notifier)
                                                    .changeEpisode((watchState
                                                                .selectedEpisodeIdx ??
                                                            0) +
                                                        1);
                                              },
                                              label:
                                                  'Episode ${watchState.episodes[(watchState.selectedEpisodeIdx ?? 0) + 1].number}',
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 8),
                                      SeekBar(
                                        position: playerState.position,
                                        duration: playerState.duration,
                                        onSeek: (position) {
                                          _resetTimer();
                                          playerNotifier.seek(position);
                                        },
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 8),
                                      BottomControls(
                                        animeProvider: getAnimeProvider(ref)!,
                                        watchState: watchState,
                                        onChangeSource: _resetTimer,
                                        isPlaying: playerState.isPlaying,
                                        onPlayPause: () {
                                          _resetTimer();
                                          playerNotifier.playOrPause();
                                        },
                                        position: playerState.position,
                                        duration: playerState.duration,
                                        isBuffering: playerState.isBuffering,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQualitySelector(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> qualities, int? currentQuality) {
    if (qualities.isEmpty || !mounted) return;
    _showSelector(
      context: context,
      title: 'Quality',
      items: qualities,
      selectedItemIdx: currentQuality,
      itemBuilder: (item) => item['quality'],
      onTap: (index) async {
        await ref.read(watchProvider.notifier).changeQuality(
            qualityIdx: index,
            lastPosition: ref.read(playerStateProvider).position);
        _resetTimer();
      },
    );
  }

  void _showSubtitleSelector(BuildContext context, WidgetRef ref,
      List<Subtitle> subtitles, int? subtitleIdx) {
    if (subtitles.isEmpty || !mounted) return;
    _showSelector(
      context: context,
      title: 'Subtitles',
      items: subtitles,
      selectedItemIdx: subtitleIdx,
      showDisableOption: true,
      itemBuilder: (item) => item.lang ?? 'Unknown',
      onTap: (index) async {
        if (index == -1) {
          await ref
              .read(watchProvider.notifier)
              .updateSubtitleTrack(subtitleIdx: null);
        } else {
          await ref
              .read(watchProvider.notifier)
              .updateSubtitleTrack(subtitleIdx: index);
        }
        _resetTimer();
      },
    );
  }

  void _showSelector<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required int? selectedItemIdx,
    required String Function(T) itemBuilder,
    required Future<void> Function(int) onTap,
    bool showDisableOption = false,
  }) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final borderRadius = BorderRadius.circular(28);

    developer.log('Showing selector modal for $title', name: 'CustomControls');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (BuildContext modalContext) {
        return PopScope(
          canPop: true,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(modalContext).pop();
                          if (mounted) _resetTimer();
                        },
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (showDisableOption)
                          SelectorTile(
                            selected: selectedItemIdx == null,
                            title: "OFF",
                            onTap: () async {
                              await onTap(-1);
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                            },
                            theme: theme,
                          ),
                        ...items.asMap().entries.map((entry) {
                          return SelectorTile(
                            selected: selectedItemIdx == entry.key,
                            title: itemBuilder(items[entry.key]),
                            onTap: () async {
                              await onTap(entry.key);
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                            },
                            theme: theme,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) _resetTimer();
    });
  }
}
