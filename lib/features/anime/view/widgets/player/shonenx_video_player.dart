import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view/widgets/player/controls_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/player_gesture_handler.dart';
import 'package:shonenx/features/anime/view/widgets/player/seek_indicator.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/generic_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/settings_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/subtitle_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/speed_indicator_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/volume_brightness_overlay.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/anime/view_model/player_ui_controller.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/helpers/ui.dart';
import 'package:window_manager/window_manager.dart';

class ShonenXVideoPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;
  final ScreenshotController? screenshotController;

  const ShonenXVideoPlayer({
    super.key,
    this.onEpisodesPressed,
    this.screenshotController,
  });

  @override
  ConsumerState<ShonenXVideoPlayer> createState() => _ShonenXVideoPlayerState();
}

class _ShonenXVideoPlayerState extends ConsumerState<ShonenXVideoPlayer> {
  final FocusNode _focusNode = FocusNode();

  // Local state for complex interactions that don't need to be global/persisted
  bool _isChangingVolume = false;
  bool _isChangingBrightness = false;
  bool _isDragLeft = false;
  bool _allowBoost = false;
  bool _isSpeeding = false;
  double _lastSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    // Restart auto-hide timer on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        ref.read(playerUIControllerProvider.notifier).restartHideTimer();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (ref.read(playerUIControllerProvider).isLocked) return;
    final w = MediaQuery.of(context).size.width;
    _isDragLeft = details.globalPosition.dx < w / 2;

    setState(() {
      if (_isDragLeft) {
        _isChangingBrightness = true;
      } else {
        _isChangingVolume = true;
      }
    });

    // Hide controls while dragging
    ref
        .read(playerUIControllerProvider.notifier)
        .toggleVisibility(override: false);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (ref.read(playerUIControllerProvider).isLocked) return;
    final delta = -details.primaryDelta! / 300;

    final controller = ref.read(playerUIControllerProvider.notifier);
    final state = ref.read(playerUIControllerProvider);

    if (_isDragLeft) {
      double newB = (state.brightness + delta).clamp(0.0, 1.0);
      controller.setBrightness(newB);
    } else {
      double maxVol = _allowBoost ? 1.25 : 1.0;
      double newV = state.volume + delta;

      if (newV > 1.0 && !_allowBoost) {
        newV = 1.0;
        if (delta > 0) _showBoostWarning();
      }

      newV = newV.clamp(0.0, maxVol);

      // Update system/player volume
      controller.setVolume(newV);

      // Update actual player gain if needed (boost)
      if (newV > 1.0) {
        final gain = (newV * 100);
        ref
            .read(playerStateProvider.notifier)
            .videoController
            .player
            .setVolume(gain);
      } else {
        ref
            .read(playerStateProvider.notifier)
            .videoController
            .player
            .setVolume(100.0);
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isChangingBrightness = false;
      _isChangingVolume = false;
    });
  }

  void _showBoostWarning() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('High Volume Warning'),
        content: const Text(
          'Boost volume above 100%? This may damage hearing or speakers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _allowBoost = true);
            },
            child: const Text('Boost'),
          ),
        ],
      ),
    );
  }

  void _onDoubleTap(bool forward) {
    if (ref.read(playerUIControllerProvider).isLocked) return;

    final notifier = ref.read(playerStateProvider.notifier);
    final settings = ref.read(playerSettingsProvider);
    final jump = settings.seekDuration;

    forward ? notifier.forward(jump) : notifier.rewind(jump);

    ref
        .read(playerUIControllerProvider.notifier)
        .showSeekIndicator(forward, jump);
  }

  void _onLongPressStart() {
    if (ref.read(playerUIControllerProvider).isLocked) return;
    ref
        .read(playerUIControllerProvider.notifier)
        .toggleVisibility(override: false);

    setState(() {
      _isSpeeding = true;
      _lastSpeed = 2.0;
    });
    ref.read(playerStateProvider.notifier).setSpeed(2.0);
  }

  void _onLongPressUpdate(double diff) {
    if (_isSpeeding) {
      double newRate = 2.0 + (diff / 50.0);
      newRate = (newRate * 4).round() / 4;
      newRate = newRate.clamp(0.25, 4.0);

      if (newRate != _lastSpeed) {
        setState(() => _lastSpeed = newRate);
        ref.read(playerStateProvider.notifier).setSpeed(newRate);
      }
    }
  }

  void _onLongPressEnd() {
    if (_isSpeeding) {
      setState(() => _isSpeeding = false);
      ref.read(playerStateProvider.notifier).setSpeed(1.0);
    }
  }

  // --- Sheet/Dialog Logic ---

  Future<void> _sheet(Widget child) async {
    final controller = ref.read(playerUIControllerProvider.notifier);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      builder: (_) => child,
    );
    controller.restartHideTimer();
  }

  void _openSettings() => _sheet(
    SettingsSheetContent(
      onDismiss: () {
        ref.read(playerUIControllerProvider.notifier).restartHideTimer();
      },
    ),
  );

  void _openQuality() {
    final data = ref.read(episodeDataProvider);
    final notifier = ref.read(episodeDataProvider.notifier);

    _sheet(
      GenericSelectionSheet<Map<String, dynamic>>(
        title: 'Quality',
        items: data.qualityOptions,
        selectedIndex: data.selectedQualityIdx ?? -1,
        displayBuilder: (e) => e['quality'],
        onItemSelected: (i) {
          notifier.changeQuality(i);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSource() {
    final data = ref.read(episodeDataProvider);
    final notifier = ref.read(episodeDataProvider.notifier);

    _sheet(
      GenericSelectionSheet<Source>(
        title: 'Source',
        items: data.sources,
        selectedIndex: data.selectedSourceIdx ?? -1,
        displayBuilder: (e) => e.quality ?? '',
        onItemSelected: (i) {
          notifier.changeSource(i);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openServer() {
    final data = ref.read(episodeDataProvider);
    if (data.selectedServer == null) return;

    _sheet(
      GenericSelectionSheet<String>(
        title: 'Server',
        items: data.servers
            .map(
              (e) =>
                  '${e.id}${e.name?.isNotEmpty == true ? ' - ${e.name}' : ''} (${e.isDub ? 'Dub' : 'Sub'})',
            )
            .toList(),
        selectedIndex: data.servers.indexOf(data.selectedServer!),
        displayBuilder: (e) => e,
        onItemSelected: (i) {
          ref.read(episodeDataProvider.notifier).changeServer(data.servers[i]);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleFullScreen() async {
    UIHelper.handleToggleFullscreen();
  }

  void _openSubtitle() {
    _sheet(SubtitleSelectionSheet(onLocalFilePressed: _pickLocalSubtitle));
  }

  Future<void> _pickLocalSubtitle() async {
    final notifier = ref.read(episodeDataProvider.notifier);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await notifier.addLocalSubtitle(file);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded: ${result.files.single.name}')),
        );
      }
    } catch (e) {
      AppLogger.e('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerStateProvider.notifier);
    final state = ref.watch(playerStateProvider);
    final uiState = ref.watch(playerUIControllerProvider);
    final uiController = ref.watch(playerUIControllerProvider.notifier);

    Widget videoView = Video(
      controller: notifier.videoController,
      fit: state.fit,
      wakelock: true,
      filterQuality: kDebugMode ? FilterQuality.none : FilterQuality.low,
      controls: NoVideoControls,
      subtitleViewConfiguration: const SubtitleViewConfiguration(
        visible: false,
      ),
    );

    if (widget.screenshotController != null) {
      videoView = Screenshot(
        controller: widget.screenshotController!,
        child: videoView,
      );
    }

    return MouseRegion(
      cursor: !uiState.isVisible
          ? SystemMouseCursors.none
          : SystemMouseCursors.click,
      onHover: (_) => uiController.toggleVisibility(override: true),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): notifier.togglePlay,
          const SingleActivator(LogicalKeyboardKey.keyK): notifier.togglePlay,
          const SingleActivator(LogicalKeyboardKey.keyL):
              uiController.toggleLock,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              notifier.rewind(10),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              notifier.forward(10),
          const SingleActivator(LogicalKeyboardKey.keyM): notifier.toggleMute,
          const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
          const SingleActivator(LogicalKeyboardKey.keyF): _toggleFullScreen,
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Layer
              videoView,

              // Gesture Layer (Background)
              Positioned.fill(
                child: PlayerGestureHandler(
                  onTap: () => uiController.toggleVisibility(),
                  onDoubleTap: _onDoubleTap,
                  onLongPressStart: _onLongPressStart,
                  onLongPressUpdate: _onLongPressUpdate,
                  onLongPressEnd: _onLongPressEnd,
                  onVerticalDragStart: _onVerticalDragStart,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  onEpisodesPressed: widget.onEpisodesPressed,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Controls & UI Layer (Foreground)
              ControlsOverlay(
                visible: uiState.isVisible,
                locked: uiState.isLocked,
                onLockPressed: uiController.toggleLock,
                onRestartHide: uiController.restartHideTimer,
                onEpisodesPressed: widget.onEpisodesPressed,
                onSettingsPressed: _openSettings,
                onQualityPressed: _openQuality,
                onSourcePressed: _openSource,
                onServerPressed: _openServer,
                onSubtitlePressed: _openSubtitle,
                onFullScreenPressed: _toggleFullScreen,
              ),

              // Seek Indicator (Dynamic)
              if (uiState.seekAmount != 0)
                Positioned.fill(
                  child: Align(
                    alignment: uiState.isSeekForward
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SeekIndicatorOverlay(
                      isForward: uiState.isSeekForward,
                      seconds: uiState.seekAmount.abs(),
                    ),
                  ),
                ),

              // Speed Indicator
              if (_isSpeeding) SpeedIndicatorOverlay(currentSpeed: _lastSpeed),

              // Volume/Brightness Overlays
              if (_isChangingBrightness)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: VolumeBrightnessOverlay(
                      isVolume: false,
                      value: uiState.brightness,
                    ),
                  ),
                ),
              if (_isChangingVolume)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: VolumeBrightnessOverlay(
                      isVolume: true,
                      value: uiState.volume,
                    ),
                  ),
                ),

              // Subtitles
              Positioned(
                left: 8,
                right: 8,
                bottom: uiState.isVisible ? 90 : 20,
                child: const SubtitleOverlay(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
