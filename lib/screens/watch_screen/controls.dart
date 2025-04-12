import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/helpers/player/gesture_handler.dart';
import 'package:shonenx/helpers/player/overlay_manager.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/helpers/ui.dart';
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
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shonenx/widgets/ui/shonenx_icon_btn.dart';
import 'package:window_manager/window_manager.dart';

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
  static const _autoHideDuration = Duration(seconds: 3);
  static const _seekDuration = Duration(seconds: 10);

  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  bool _isFullscreen = false;
  late GestureHandler _gestureHandler;
  late OverlayManager _overlayManager;

  @override
  void initState() {
    super.initState();
    _overlayManager = OverlayManager();
    _gestureHandler = GestureHandler(
      resetTimer: _resetTimer,
      showOverlay: (context, {required bool isBrightness}) {
        if (!mounted) return;
        _overlayManager.showAdjustmentOverlay(
          context,
          isBrightness: isBrightness,
          value: isBrightness
              ? _gestureHandler.brightnessValue
              : _gestureHandler.volumeValue,
        );
      },
    );
    _initializeState();
  }

  Future<void> _initializeState() async {
    _isFullscreen = (!Platform.isAndroid && !Platform.isIOS)
        ? await windowManager.isFullScreen()
        : false;
    await UIHelper.forceLandscape();
    _gestureHandler.initialize();
    if (_isFullscreen) {
      _scheduleHideControls();
    } else {
      _controlsVisible = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to save ancestor references here unless accessing specific inherited widgets
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _overlayManager.dispose();
    Future.wait([
      widget.state.widget.controller.player.pause(),
      widget.state.widget.controller.player.stop(),
      widget.state.widget.controller.player.remove(0),
      UIHelper.enableAutoRotate()
    ]);
    // Avoid disposing widget.state here; let the parent widget handle it
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_controlsVisible || !mounted || !_isFullscreen) return;

    _hideControlsTimer = Timer(_autoHideDuration, () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        developer.log('Controls auto-hidden', name: 'CustomControls');
      }
    });
  }

  void _toggleControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = !_controlsVisible);
    _controlsVisible ? _scheduleHideControls() : _hideControlsTimer?.cancel();
  }

  void _showControls() {
    if (!mounted || _controlsVisible) return;
    setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _resetTimer() {
    if (mounted && _controlsVisible) {
      _scheduleHideControls();
    }
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
            onInvoke: (_) => _handlePlayPause(playerNotifier),
          ),
          SeekForwardIntent: CallbackAction<SeekForwardIntent>(
            onInvoke: (_) =>
                _handleSeek(playerState, playerNotifier, forward: true),
          ),
          SeekBackwardIntent: CallbackAction<SeekBackwardIntent>(
            onInvoke: (_) =>
                _handleSeek(playerState, playerNotifier, forward: false),
          ),
          ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
            onInvoke: (_) => _handleToggleFullscreen(),
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
              child: SafeArea(
                child: Stack(
                  children: [
                    _buildSubtitleOverlay(playerState, playerSettings),
                    _buildControlsOverlay(
                      context,
                      playerState,
                      playerNotifier,
                      watchState,
                      theme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleOverlay(
      PlayerState playerState, PlayerSettingsModel playerSettings) {
    return Positioned(
      bottom: _controlsVisible ? 100 : 0,
      left: 0,
      right: 0,
      child: Center(
        child: SubtitleOverlay(
          subtitleStyle: playerSettings.toSubtitleStyle(),
          subtitle: playerState.subtitle.firstOrNull ?? '',
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    BuildContext context,
    PlayerState playerState,
    PlayerStateNotifier playerNotifier,
    WatchState watchState,
    ThemeData theme,
  ) {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AbsorbPointer(
        absorbing: !_controlsVisible,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Stack(
            children: [
              TopControls(
                watchState: watchState,
                onPanelToggle: () => _togglePanel(),
                onQualityTap: () =>
                    _showQualitySelector(context, ref, watchState),
                onSubtitleTap: () =>
                    _showSubtitleSelector(context, ref, watchState),
                onFullscreenTap: () async => await _handleToggleFullscreen(),
              ),
              Align(
                alignment: Alignment.center,
                child: CenterControls(
                  isPlaying: playerState.isPlaying,
                  isBuffering: playerState.isBuffering,
                  onTap: () => _handlePlayPause(playerNotifier),
                  theme: theme,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(
                    playerState, watchState, playerNotifier, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    PlayerState playerState,
    WatchState watchState,
    PlayerStateNotifier playerNotifier,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if ((playerState.position.inSeconds / playerState.duration.inSeconds) *
                100.0 >=
            85)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShonenXIconButton(
                icon: Iconsax.next5,
                onPressed: () => ref.read(watchProvider.notifier).changeEpisode(
                      (watchState.selectedEpisodeIdx ?? 0) + 1,
                    ),
                label:
                    'Episode ${watchState.episodes[(watchState.selectedEpisodeIdx ?? 0) + 1].number}',
              ),
            ],
          ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color:
                theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
          ),
          child: Column(
            children: [
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
                onPlayPause: () => _handlePlayPause(playerNotifier),
                position: playerState.position,
                duration: playerState.duration,
                isBuffering: playerState.isBuffering,
              ),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _handlePlayPause(PlayerStateNotifier playerNotifier) async {
    _resetTimer();
    await playerNotifier.playOrPause();
  }

  Future<void> _handleSeek(
      PlayerState playerState, PlayerStateNotifier playerNotifier,
      {required bool forward}) async {
    _resetTimer();
    final newPosition = forward
        ? playerState.position + _seekDuration
        : playerState.position - _seekDuration;
    await playerNotifier.seek(newPosition);
  }

  Future<void> _handleToggleFullscreen() async {
    await UIHelper.handleToggleFullscreen(
        isFullscreen: _isFullscreen,
        beforeCallback: _resetTimer,
        afterCallback: () {
          if (mounted) setState(() => _isFullscreen = !_isFullscreen);
        });
  }

  Future<void> _togglePanel() async {
    _resetTimer();
    if (_isFullscreen) {
      await widget.state.exitFullscreen();
      if (mounted) setState(() => _isFullscreen = false);
    }
    await ref
        .read(watchProvider.notifier)
        .togglePanel(widget.panelAnimationController);
  }

  void _showQualitySelector(
      BuildContext context, WidgetRef ref, WatchState watchState) {
    if (watchState.qualityOptions.isEmpty || !mounted) return;
    _showSelector(
      context: context,
      title: 'Quality',
      items: watchState.qualityOptions,
      selectedItemIdx: watchState.selectedQualityIdx,
      itemBuilder: (item) => item['quality'],
      onTap: (index) async {
        await ref.read(watchProvider.notifier).changeQuality(
              qualityIdx: index,
              lastPosition: ref.read(playerStateProvider).position,
            );
        _resetTimer();
      },
    );
  }

  void _showSubtitleSelector(
      BuildContext context, WidgetRef ref, WatchState watchState) {
    if (watchState.subtitles.isEmpty || !mounted) return;
    _showSelector(
      context: context,
      title: 'Subtitles',
      items: watchState.subtitles,
      selectedItemIdx: watchState.selectedSubtitleIdx,
      showDisableOption: true,
      itemBuilder: (item) => item.lang ?? 'Unknown',
      onTap: (index) async {
        await ref.read(watchProvider.notifier).updateSubtitleTrack(
              subtitleIdx: index == -1 ? null : index,
            );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (modalContext) => _buildSelectorModal(
        modalContext,
        theme,
        title,
        items,
        selectedItemIdx,
        itemBuilder,
        onTap,
        showDisableOption,
      ),
    ).whenComplete(() => _resetTimer());
  }

  Widget _buildSelectorModal<T>(
    BuildContext modalContext,
    ThemeData theme,
    String title,
    List<T> items,
    int? selectedItemIdx,
    String Function(T) itemBuilder,
    Future<void> Function(int) onTap,
    bool showDisableOption,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
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
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                  ...items.asMap().entries.map((entry) => SelectorTile(
                        selected: selectedItemIdx == entry.key,
                        title: itemBuilder(entry.value),
                        onTap: () async {
                          await onTap(entry.key);
                          if (modalContext.mounted) {
                            Navigator.of(modalContext).pop();
                          }
                        },
                        theme: theme,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
