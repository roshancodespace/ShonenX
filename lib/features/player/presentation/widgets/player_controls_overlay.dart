import 'package:flutter/material.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/bottom_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/center_controls.dart';
import 'package:shonenx/features/player/presentation/widgets/top_controls.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';

/// Main player controls overlay that describes layout/composition and state delivery.
///
/// Composes top, center, and bottom controls within a responsive scaled stack.
class PlayerControlsOverlay extends StatelessWidget {
  final bool showControls;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final PlayerMode mode;
  final String mediaTitle;
  final bool isFullScreen;
  final VoidCallback onBack;
  final VoidCallback? onComments;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onShowEpisodePanel;
  final VoidCallback onToggleLockControls;

  const PlayerControlsOverlay({
    super.key,
    required this.showControls,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.mode,
    required this.mediaTitle,
    required this.isFullScreen,
    required this.onBack,
    this.onComments,
    required this.onToggleFullScreen,
    required this.onShowEpisodePanel,
    required this.onToggleLockControls,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    double scale = 1.0;
    if (width > 1200) {
      scale = 1.2;
    } else if (width > 800) {
      scale = 1.1;
    }

    final controls = Stack(
      children: [
        TopControls(
          showControls: showControls,
          engine: engine,
          mode: mode,
          playerState: playerState,
          controller: controller,
          onBack: onBack,
          onComments: onComments,
        ),
        CenterControls(
          showControls: showControls,
          playerState: playerState,
          controller: controller,
          mediaTitle: mediaTitle,
          engine: engine,
        ),
        BottomControls(
          showControls: showControls,
          engine: engine,
          playerState: playerState,
          controller: controller,
          theme: theme,
          mode: mode,
          isFullScreen: isFullScreen,
          onToggleFullScreen: onToggleFullScreen,
          onShowEpisodePanel: onShowEpisodePanel,
          onToggleLockControls: onToggleLockControls,
        ),
      ],
    );

    if (scale == 1.0) return controls;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(width / scale, mediaQuery.size.height / scale),
            padding: mediaQuery.padding / scale,
            viewInsets: mediaQuery.viewInsets / scale,
          ),
          child: SizedBox(
            width: width / scale,
            height: mediaQuery.size.height / scale,
            child: controls,
          ),
        ),
      ),
    );
  }
}
