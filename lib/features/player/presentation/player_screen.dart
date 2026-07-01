import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:window_manager/window_manager.dart';

import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/bottom_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/center_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/custom_subtitle_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/gesture_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/top_controls.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';

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
      return AniSkipArgs(
        idMal: int.parse(onlineMode.media.idMal!),
        episodeNumber: onlineMode.episode.number,
        episodeLength: engine.currentDuration.inSeconds,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initSystemUI();
    _initDesktopWindowState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(playerControllerProvider.notifier)
          .initialize(widget.mode, screenshot: _screenshotController);
      _showControlsTemporarily();
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

  KeyEventResult _handleKeyEvent(KeyEvent event, VideoEngine engine) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isPlaying = ref.read(videoEngineStateProvider).isPlaying;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      isPlaying ? engine.pause() : engine.play();
      _showControlsTemporarily();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      engine.seekRelative(const Duration(seconds: 10));
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      engine.seekRelative(const Duration(seconds: -10));
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _toggleFullScreen();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
        offstage: playerState.isLoading || playerState.error != null,
        child: Screenshot(
          controller: _screenshotController,
          child: engine.buildVideoView(),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Text(
          error,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) =>
          _handlePop(didPop, engine, controller),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleKeyEvent(event, engine),
          child: Stack(
            children: [
              _buildVideoLayer(engine, playerState),
              if (playerState.error != null)
                _buildErrorOverlay(playerState.error!),
              Positioned.fill(
                child: PlayerGestureOverlay(
                  onToggleControls: _toggleControls,
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
    );
  }
}
