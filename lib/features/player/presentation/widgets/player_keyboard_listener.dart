import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';

class PlayerKeyboardListener extends ConsumerStatefulWidget {
  final Widget child;
  final VideoEngine engine;
  final PlayerController controller;
  final VoidCallback onUserInteraction;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onToggleEpisodePanel;
  final VoidCallback onShowShortcutsGuide;
  final VoidCallback? onExit;

  const PlayerKeyboardListener({
    super.key,
    required this.child,
    required this.engine,
    required this.controller,
    required this.onUserInteraction,
    required this.onToggleFullScreen,
    required this.onToggleEpisodePanel,
    required this.onShowShortcutsGuide,
    this.onExit,
  });

  @override
  ConsumerState<PlayerKeyboardListener> createState() =>
      _PlayerKeyboardListenerState();
}

class _PlayerKeyboardListenerState
    extends ConsumerState<PlayerKeyboardListener> {
  double _currentPlaybackSpeed = 1.0;

  Future<void> _adjustVolume(double delta) async {
    try {
      final current = await VolumeController.instance.getVolume();
      final newVal = (current + delta).clamp(0.0, 1.0);
      VolumeController.instance.setVolume(newVal);
    } catch (_) {}
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isPlaying = ref.read(videoEngineStateProvider).isPlaying;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      if (event is KeyDownEvent) {
        isPlaying ? widget.engine.pause() : widget.engine.play();
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyL) {
      widget.engine.seekRelative(const Duration(seconds: 10));
      widget.onUserInteraction();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyJ) {
      widget.engine.seekRelative(const Duration(seconds: -10));
      widget.onUserInteraction();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _adjustVolume(0.05);
      widget.onUserInteraction();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _adjustVolume(-0.05);
      widget.onUserInteraction();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyF ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) {
        widget.onToggleFullScreen();
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyN ||
        key == LogicalKeyboardKey.pageDown) {
      if (event is KeyDownEvent) {
        widget.controller.skipEpisode(forward: true);
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyP ||
        key == LogicalKeyboardKey.pageUp) {
      if (event is KeyDownEvent) {
        widget.controller.skipEpisode(forward: false);
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyE) {
      if (event is KeyDownEvent) {
        widget.onToggleEpisodePanel();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyS) {
      if (event is KeyDownEvent) {
        ref.read(videoEngineStateProvider.notifier).cycleFit();
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.bracketRight) {
      if (event is KeyDownEvent) {
        _currentPlaybackSpeed = (_currentPlaybackSpeed + 0.25).clamp(0.25, 3.0);
        widget.engine.setSpeed(_currentPlaybackSpeed);
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.bracketLeft) {
      if (event is KeyDownEvent) {
        _currentPlaybackSpeed = (_currentPlaybackSpeed - 0.25).clamp(0.25, 3.0);
        widget.engine.setSpeed(_currentPlaybackSpeed);
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.backspace) {
      if (event is KeyDownEvent) {
        _currentPlaybackSpeed = 1.0;
        widget.engine.setSpeed(1.0);
        widget.onUserInteraction();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.question ||
        key == LogicalKeyboardKey.slash ||
        key == LogicalKeyboardKey.f1) {
      if (event is KeyDownEvent) {
        widget.onShowShortcutsGuide();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        if (widget.onExit != null) {
          widget.onExit!();
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
