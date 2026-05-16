import 'dart:async';
import 'dart:io';

import 'package:dartotsu_extension_bridge/Mangayomi/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shonenx/features/player/presentation/widgets/bottom_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/center_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/custom_subtitle_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/gesture_overlay.dart';
import 'package:shonenx/features/player/presentation/widgets/top_controls.dart';
import 'package:shonenx/features/player/providers/active_engine_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

class PlayerParams {
  final UnifiedMedia media;
  final UnifiedEpisode episode;
  final SourceInfo sourceInfo;
  final Duration? startPosition;

  const PlayerParams({
    required this.media,
    required this.episode,
    required this.sourceInfo,
    this.startPosition,
  });
}

class PlayerScreen extends ConsumerStatefulWidget {
  final PlayerParams params;
  final AnimeSource source;

  const PlayerScreen({super.key, required this.params, required this.source});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _showControls = false;
  bool _lockControls = false;
  Timer? _controlsTimer;

  static const _controlsAutoHideDuration = Duration(seconds: 3);

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

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(playerControllerProvider.notifier)
          .initialize(
            widget.source,
            screenshot: _screenshotController,
            media: widget.params.media,
            episode: widget.params.episode,
            startPosition: widget.params.startPosition,
          );
      _showControlsTemporarily();
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final engine = ref.watch(videoEngineProvider);

    final AniSkipArgs aniSkipArgs = AniSkipArgs(
      idMal: widget.params.media.idMal?.toInt(),
      episodeNumber: widget.params.episode.number,
      episodeLength: engine.currentDuration.inSeconds,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          controller.captureExitThumbnail();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
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
                if (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS) {
                  windowManager.isFullScreen().then((isFull) {
                    windowManager.setFullScreen(!isFull);
                  });
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // Video layer
              Center(
                child: Offstage(
                  offstage: playerState.isLoading || playerState.error != null,
                  child: Screenshot(
                    controller: _screenshotController,
                    child: engine.buildVideoView(),
                  ),
                ),
              ),
              if (playerState.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                )
              else if (playerState.error != null)
                Center(
                  child: Text(
                    playerState.error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              // Gesture layer (always present)
              Positioned.fill(
                child: PlayerGestureOverlay(
                  onToggleControls: _toggleControls,
                  onSeek: engine.seekRelative,
                  onSetSpeed: engine.setSpeed,
                ),
              ),

              // Custom Subtitle Layer
              if (playerState.activeSubtitle != null)
                const CustomSubtitleOverlay(),

              // Controls layer
              if (_lockControls)
                Center(
                  child: IconButton.filled(
                    padding: const EdgeInsets.all(15),
                    icon: const Icon(
                      Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () => setState(() => _lockControls = false),
                  ),
                )
              else ...[
                TopControls(
                  showControls: _showControls,
                  engine: engine,
                  media: widget.params.media,
                  playerState: playerState,
                  onBack: context.pop,
                ),
                CenterControls(
                  showControls: _showControls,
                  playerState: playerState,
                  controller: controller,
                  mediaTitle: widget.params.media.title.availableTitle,
                  engine: engine,
                ),
                BottomControls(
                  aniskipArgs: aniSkipArgs,
                  showControls: _showControls,
                  engine: engine,
                  playerState: playerState,
                  controller: controller,
                  theme: theme,
                  params: widget.params,
                  onToggleLockControls: () =>
                      setState(() => _lockControls = !_lockControls),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
