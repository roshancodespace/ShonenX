import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import 'package:shonenx/features/anime/view/widgets/player/sheets/subtitle_selection_sheet.dart';

import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/player_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/player_gesture_handler.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/seek_indicator.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/generic_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/settings_sheet.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class ControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;
  const ControlsOverlay({super.key, this.onEpisodesPressed});

  @override
  ConsumerState<ControlsOverlay> createState() => ControlsOverlayState();
}

class ControlsOverlayState extends ConsumerState<ControlsOverlay> {
  bool _visible = true;
  bool _locked = false;
  int _seekAccum = 0;
  bool _isSpeeding = false;
  double _lastSpeed = 1.0;

  Timer? _hideTimer;
  Timer? _seekResetTimer;

  @override
  void initState() {
    super.initState();
    _restartHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekResetTimer?.cancel();
    super.dispose();
  }

  void _restartHide() {
    _hideTimer?.cancel();
    if (_locked || !_visible) return;
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _toggle() {
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

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerStateProvider.notifier);

    return PlayerGestureHandler(
      onTap: _toggle,
      onDoubleTap: _onDoubleTap,
      onLongPressStart: _onLongPressStart,
      onLongPressUpdate: _onLongPressUpdate,
      onLongPressEnd: _onLongPressEnd,
      onSpacePressed: notifier.togglePlay,
      onLeftArrowPressed: () => notifier.rewind(10),
      onRightArrowPressed: () => notifier.forward(10),
      onMKeyPressed: notifier.toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AbsorbPointer(
              absorbing: !_visible,
              child: _locked ? _lockBtn() : _controls(),
            ),
          ),
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
          if (_isSpeeding) _buildSpeedScale(),
          Positioned(
            left: 8,
            right: 8,
            bottom: _visible ? 90 : 20,
            child: const SubtitleOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _lockBtn() {
    return Center(
      child: IconButton(
        onPressed: _toggleLock,
        icon: const Icon(Icons.lock_open, size: 32, color: Colors.white),
        style: IconButton.styleFrom(backgroundColor: Colors.black54),
      ),
    );
  }

  Widget _controls() {
    return PlayerControls(
      onInteraction: _restartHide,
      onEpisodesPressed: widget.onEpisodesPressed,
      onSettingsPressed: _openSettings,
      onQualityPressed: _openQuality,
      onLockPressed: _toggleLock,
      onSourcePressed: _openSource,
      onSubtitlePressed: _openSubtitle,
      onServerPressed: _openServer,
    );
  }

  Future<void> _sheet(Widget child) async {
    _hideTimer?.cancel();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      builder: (_) => child,
    );
    _restartHide();
  }

  void _openSettings() => _sheet(
        SettingsSheetContent(onDismiss: () => Navigator.pop(context)),
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
        items:
            data.servers.map((e) => '${e.id}-${e.isDub ? "Dub" : ""}').toList(),
        selectedIndex: data.servers.indexOf(data.selectedServer!),
        displayBuilder: (e) => e,
        onItemSelected: (i) {
          ref.read(episodeDataProvider.notifier).changeServer(data.servers[i]);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSubtitle() {
    _sheet(
      SubtitleSelectionSheet(
        onLocalFilePressed: _pickLocalSubtitle,
      ),
    );
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

  Widget _buildSpeedScale() {
    final speeds = [4.0, 3.0, 2.0, 1.5, 1.0, 0.5];
    final closest = speeds.reduce(
        (a, b) => (_lastSpeed - a).abs() < (_lastSpeed - b).abs() ? a : b);

    return Positioned(
      right: 40,
      top: 0,
      bottom: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Precise Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '${_lastSpeed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Scale
            Container(
              width: 50,
              height: 300,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: speeds.map((speed) {
                  final isSelected = speed == closest;
                  return AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${speed}x',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
