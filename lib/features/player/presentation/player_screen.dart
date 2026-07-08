import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/bottom_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/center_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/custom_subtitle_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/gesture_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/keyboard_shortcuts_sheet.dart';
import 'package:shonenx/features/player/presentation/widgets/player_keyboard_listener.dart';
import 'package:shonenx/features/player/presentation/widgets/top_controls.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/comments/presentation/widgets/comments_tab.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final PlayerMode mode;

  const PlayerScreen({super.key, required this.mode});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _showControls = false;
  bool _lockControls = false;
  Timer? _controlsTimer;

  bool _isFullScreen = false;
  bool _isEpisodePanelOpen = false;
  Offset? _lastHoverPosition;

  static const _controlsAutoHideDuration = Duration(seconds: 3);

  String get _mediaTitle {
    if (widget.mode is PlayerModeOnline) {
      return (widget.mode as PlayerModeOnline).media.title.availableTitle;
    }
    return (widget.mode as PlayerModeOffline).title ?? 'Local Media';
  }

  AniSkipArgs? _getAniSkipArgs(VideoEngine engine) {
    if (widget.mode is PlayerModeOnline) {
      final onlineMode = widget.mode as PlayerModeOnline;
      final idMalStr = onlineMode.media.idMal;
      if (idMalStr == null || idMalStr.isEmpty) return null;
      final malId = int.tryParse(idMalStr);
      if (malId == null) return null;
      return AniSkipArgs(
        idMal: malId,
        episodeNumber: onlineMode.episode.number,
        episodeLength: engine.currentDuration.inSeconds,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    try {
      WakelockPlus.enable();
    } catch (_) {}
    _initSystemUI();
    _initDesktopWindowState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(playerControllerProvider.notifier)
          .initialize(widget.mode, screenshot: _screenshotController);
      _showControlsTemporarily();
      if (ref.read(playerPrefsProvider).showShortcutsSheetOnStart && mounted) {
        KeyboardShortcutsSheet.show(context);
      }
    });
  }

  void _initSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initDesktopWindowState() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.isFullScreen().then((isFull) {
        if (mounted) setState(() => _isFullScreen = isFull);
      });
    }
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    _controlsTimer?.cancel();
    _disposeSystemUI();

    try {
      ref.read(videoEngineProvider).dispose();
    } catch (_) {}

    super.dispose();
  }

  void _disposeSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.isFullScreen().then((isFull) async {
        if (isFull) {
          await windowManager.setFullScreen(false);
          if (Platform.isWindows) {
            await windowManager.setTitleBarStyle(TitleBarStyle.normal);
          }
        }
      });
    }
  }

  void _showControlsTemporarily() {
    _controlsTimer?.cancel();
    if (!_showControls) setState(() => _showControls = true);
    _controlsTimer = Timer(_controlsAutoHideDuration, () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    if (_showControls) {
      _controlsTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _showControlsTemporarily();
    }
  }

  Future<void> _toggleFullScreen() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    final isFull = await windowManager.isFullScreen();
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

  void _onMouseHover(PointerHoverEvent event) {
    if (event.kind == PointerDeviceKind.touch) return;
    if (_lastHoverPosition == event.position) return;
    _lastHoverPosition = event.position;
    _showControlsTemporarily();
  }

  void _toggleEpisodePanel() {
    if (widget.mode is! PlayerModeOnline) return;
    if (_isEpisodePanelOpen) {
      Navigator.of(context).pop();
      return;
    }
    _isEpisodePanelOpen = true;
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
    ).then((_) {
      if (mounted) setState(() => _isEpisodePanelOpen = false);
    });
  }

  void _showCommentsSheet() {
    if (widget.mode is! PlayerModeOnline) return;
    final media = (widget.mode as PlayerModeOnline).media;
    final activeEpisode = ref.read(playerControllerProvider).activeEpisode;

    AppBottomSheet.show(
      context: context,
      title: 'Episode ${activeEpisode?.number ?? 1} Discussion',
      contentPadding: EdgeInsets.zero,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: CommentsTabWidget(
          media: media,
          initialEpisodeNumber: activeEpisode?.number.toInt(),
          forceEpisodeFilter: true,
        ),
      ),
    );
  }

  void _handlePop(
    bool didPop,
    VideoEngine engine,
    PlayerController controller,
  ) {
    if (!didPop) {
      try {
        engine.pause();
      } catch (_) {}
      controller.captureExitThumbnail();
      context.pop();
    }
  }

  Widget _buildVideoLayer(VideoEngine engine, PlayerState playerState) {
    return Center(
      child: Offstage(
        offstage: playerState.isLoading,
        child: Screenshot(
          controller: _screenshotController,
          child: engine.buildVideoView(),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Center(
      child: IconButton.filled(
        padding: const EdgeInsets.all(15),
        icon: const Icon(
          Icons.lock_open_rounded,
          color: Colors.white,
          size: 50,
        ),
        onPressed: () => setState(() => _lockControls = false),
      ),
    );
  }

  List<Widget> _buildControlsLayer({
    required ThemeData theme,
    required VideoEngine engine,
    required PlayerState playerState,
    required PlayerController controller,
    required AniSkipArgs? aniSkipArgs,
  }) {
    return [
      TopControls(
        showControls: _showControls,
        engine: engine,
        mode: widget.mode,
        playerState: playerState,
        controller: controller,
        onBack: context.pop,
        onComments: _showCommentsSheet,
      ),
      CenterControls(
        showControls: _showControls,
        playerState: playerState,
        controller: controller,
        mediaTitle: _mediaTitle,
        engine: engine,
      ),
      BottomControls(
        aniskipArgs: aniSkipArgs,
        showControls: _showControls,
        engine: engine,
        playerState: playerState,
        controller: controller,
        theme: theme,
        mode: widget.mode,
        isFullScreen: _isFullScreen,
        onToggleFullScreen: _toggleFullScreen,
        onShowEpisodePanel: _toggleEpisodePanel,
        onToggleLockControls: () =>
            setState(() => _lockControls = !_lockControls),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final engine = ref.watch(videoEngineProvider);
    final aniSkipArgs = _getAniSkipArgs(engine);

    ref.listen(playerControllerProvider.select((s) => s.error), (prev, next) {
      if (next != null && next != prev && mounted) {
        AppBottomSheet.show(
          context: context,
          title: 'Playback Error',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Failed to load media stream',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  next,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We recommend selecting a different video server, changing the extension source, or trying another episode.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (widget.mode is PlayerModeOnline) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _toggleEpisodePanel();
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.playlist_play_rounded),
                        label: const Text('Change Source / Episode'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) =>
          _handlePop(didPop, engine, controller),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PlayerKeyboardListener(
          engine: engine,
          controller: controller,
          onUserInteraction: () {},
          onToggleFullScreen: _toggleFullScreen,
          onToggleEpisodePanel: _toggleEpisodePanel,
          onShowShortcutsGuide: () => KeyboardShortcutsSheet.show(context),
          onExit: () {
            if (_isEpisodePanelOpen) {
              Navigator.of(context).pop();
            } else if (_isFullScreen) {
              _toggleFullScreen();
            } else {
              context.pop();
            }
          },
          child: MouseRegion(
            cursor: _showControls
                ? SystemMouseCursors.basic
                : SystemMouseCursors.none,
            onHover: _onMouseHover,
            child: Stack(
              children: [
                _buildVideoLayer(engine, playerState),
                Positioned.fill(
                  child: PlayerGestureOverlay(
                    onToggleControls: _toggleControls,
                    onRightClick: _toggleEpisodePanel,
                    onSeek: engine.seekRelative,
                    onSetSpeed: engine.setSpeed,
                  ),
                ),
                if (playerState.activeSubtitle != null)
                  const CustomSubtitleOverlay(),
                if (_lockControls)
                  _buildLockedOverlay()
                else
                  ..._buildControlsLayer(
                    theme: theme,
                    engine: engine,
                    playerState: playerState,
                    controller: controller,
                    aniSkipArgs: aniSkipArgs,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
