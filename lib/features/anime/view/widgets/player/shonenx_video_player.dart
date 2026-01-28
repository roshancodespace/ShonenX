import 'dart:async';
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
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
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
  // UI State
  bool _visible = true;
  bool _locked = false;
  final FocusNode _focusNode = FocusNode();

  // Seek State
  int _seekAccum = 0;
  Timer? _seekResetTimer;

  // Speed State
  bool _isSpeeding = false;
  double _lastSpeed = 1.0;

  // Visibility Timer
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _restartHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekResetTimer?.cancel();
    _focusNode.dispose();
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }

  // --- Visibility Logic ---

  void _restartHide() {
    _hideTimer?.cancel();
    if (_locked || !_visible) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _toggleVisible() {
    setState(() => _visible = !_visible);
    _visible ? _restartHide() : _hideTimer?.cancel();
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      _visible = true;
    });
    _restartHide();
  }

  // --- Gesture Callbacks ---

  void _onDoubleTap(bool forward) {
    if (_locked) return;
    final notifier = ref.read(playerStateProvider.notifier);

    _seekResetTimer?.cancel();
    setState(() {
      _seekAccum += forward ? 10 : -10;
    });

    forward ? notifier.forward(10) : notifier.rewind(10);

    _seekResetTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _seekAccum = 0);
    });
    _restartHide();
  }

  void _onLongPressStart() {
    if (_locked) return;
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
    _hideTimer?.cancel(); // Pause auto-hide
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      builder: (_) => child,
    );
    _restartHide(); // Resume auto-hide
  }

  void _openSettings() => _sheet(SettingsSheetContent(onDismiss: _restartHide));

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
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.setFullScreen(!(await windowManager.isFullScreen()));
    }
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): notifier.togglePlay,
        const SingleActivator(LogicalKeyboardKey.keyK): notifier.togglePlay,
        const SingleActivator(LogicalKeyboardKey.keyJ): () =>
            notifier.rewind(10),
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            notifier.forward(10),
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
                onTap: _toggleVisible,
                onDoubleTap: _onDoubleTap,
                onLongPressStart: _onLongPressStart,
                onLongPressUpdate: _onLongPressUpdate,
                onLongPressEnd: _onLongPressEnd,
                onEpisodesPressed: widget.onEpisodesPressed,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Controls & UI Layer (Foreground)
            ControlsOverlay(
              visible: _visible,
              locked: _locked,
              onLockPressed: _toggleLock,
              onRestartHide: _restartHide,
              onEpisodesPressed: widget.onEpisodesPressed,
              onSettingsPressed: _openSettings,
              onQualityPressed: _openQuality,
              onSourcePressed: _openSource,
              onServerPressed: _openServer,
              onSubtitlePressed: _openSubtitle,
              onFullScreenPressed: _toggleFullScreen,
            ),

            // Seek Indicator (Dynamic)
            if (_seekAccum != 0)
              Positioned.fill(
                child: Align(
                  alignment: _seekAccum > 0
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: SeekIndicatorOverlay(
                    isForward: _seekAccum > 0,
                    seconds: _seekAccum.abs(),
                  ),
                ),
              ),

            // Speed Indicator
            if (_isSpeeding) SpeedIndicatorOverlay(currentSpeed: _lastSpeed),

            // Subtitles
            Positioned(
              left: 8,
              right: 8,
              bottom: _visible ? 90 : 20,
              child: const SubtitleOverlay(),
            ),
          ],
        ),
      ),
    );
  }
}
