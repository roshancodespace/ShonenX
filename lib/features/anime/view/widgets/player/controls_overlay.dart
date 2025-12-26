import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/seek_indicator.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/generic_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/settings_sheet.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class CloudstreamControls extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;

  const CloudstreamControls({super.key, this.onEpisodesPressed});

  @override
  ConsumerState<CloudstreamControls> createState() =>
      _CloudstreamControlsState();
}

class _CloudstreamControlsState extends ConsumerState<CloudstreamControls> {
  bool _isVisible = true;
  bool _isLocked = false;
  double? _draggedSliderValue;

  // Seek State
  int _cumulativeSeek = 0;
  // double _cumulativeVolume = 0;
  bool _showForwardSeek = false;
  bool _showRewindSeek = false;
  // bool _showVolumeSeek = false;

  Timer? _hideTimer;
  Timer? _seekResetTimer;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _restartHideTimer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hideTimer?.cancel();
    _seekResetTimer?.cancel();
    super.dispose();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (_isLocked || !_isVisible) return;
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _restartHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _isVisible = true;
    });
    _restartHideTimer();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isLocked) return;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isForward = details.globalPosition.dx > screenWidth / 2;

    _seekResetTimer?.cancel();

    setState(() {
      if (isForward) {
        _showForwardSeek = true;
        _showRewindSeek = false;
        _cumulativeSeek += 10;
      } else {
        _showForwardSeek = false;
        _showRewindSeek = true;
        _cumulativeSeek -= 10;
      }
    });

    final notifier = ref.read(playerStateProvider.notifier);
    isForward ? notifier.forward(10) : notifier.rewind(10);

    _seekResetTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showForwardSeek = false;
          _showRewindSeek = false;
          _cumulativeSeek = 0;
        });
      }
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isRight = details.globalPosition.dx > screenWidth / 2;
    // setState(() {
    //   _showVolumeSeek = isRight;
    // });

    if (isRight) {
      AppLogger.d(details.globalPosition.dy / screenHeight);
    } else {
      AppLogger.d(details.globalPosition.dx / screenWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerStateProvider.notifier);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            notifier.togglePlay(),
        const SingleActivator(LogicalKeyboardKey.keyK): () =>
            notifier.togglePlay(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            notifier.rewind(10),
        const SingleActivator(LogicalKeyboardKey.keyJ): () =>
            notifier.rewind(10),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            notifier.forward(10),
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            notifier.forward(10),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          final player = notifier.player;
          if (player != null) {
            player.setVolume((player.state.volume + 10).clamp(0.0, 100.0));
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          final player = notifier.player;
          if (player != null) {
            player.setVolume((player.state.volume - 10).clamp(0.0, 100.0));
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyM): () {
          final player = notifier.player;
          if (player != null) {
            player.setVolume(player.state.volume == 0 ? 100.0 : 0.0);
          }
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: GestureDetector(
          onTap: _toggleVisibility,
          onDoubleTapDown: _handleDoubleTap,
          // onVerticalDragUpdate: _handleVerticalDragUpdate,
          // onVerticalDragEnd: (details) => setState(() => _showVolumeSeek = false),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // UI Overlay
              AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AbsorbPointer(
                  absorbing: !_isVisible,
                  child: _isLocked ? _buildLockBtn() : _buildControls(),
                ),
              ),

              // Seek Indicators
              if (_showRewindSeek) _buildSeekOverlay(false),
              if (_showForwardSeek) _buildSeekOverlay(true),

              // if (_showVolumeSeek)
              //   Positioned(
              //     top: 90,
              //     right: 30,
              //     bottom: 120,
              //     child: Expanded(
              //       child: Container(
              //         width: 40,
              //         decoration: BoxDecoration(
              //           color: theme.colorScheme.onSurface,
              //           borderRadius: BorderRadius.circular(50),
              //         ),
              //       ),
              //     ),
              //   ),

              // Subtitles
              Positioned(
                left: 8,
                right: 8,
                top: _isVisible && !_isLocked ? 90 : 20,
                bottom: _isVisible && !_isLocked ? 90 : 20,
                child: const SubtitleOverlay(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekOverlay(bool isForward) {
    return Positioned.fill(
      child: Align(
        alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
        child: SeekIndicatorOverlay(
          isForward: isForward,
          seconds: _cumulativeSeek.abs(),
        ),
      ),
    );
  }

  Widget _buildLockBtn() {
    return Center(
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () => _toggleLock(), // Unlocks and resets timer
        icon: const Icon(Icons.lock_open, size: 32, color: Colors.white),
        tooltip: 'Unlock',
      ),
    );
  }

  Widget _buildControls() {
    final notifier = ref.read(playerStateProvider.notifier);

    return GestureDetector(
      onTap: _toggleVisibility,
      child: Stack(
        children: [
          Center(child: CenterControls(onInteraction: _restartHideTimer)),

          // Top Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: TopControls(
              onInteraction: _restartHideTimer,
              onEpisodesPressed: widget.onEpisodesPressed,
              onSettingsPressed: _openSettings,
              onQualityPressed: _openQualitySheet,
            ),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _isVisible ? 0 : -150,
            left: 0,
            right: 0,
            child: BottomControls(
              onInteraction: _restartHideTimer,
              sliderValue: _draggedSliderValue,
              onSliderChangeStart: (val) {
                _hideTimer?.cancel();
                setState(() => _draggedSliderValue = val);
              },
              onSliderChanged: (val) =>
                  setState(() => _draggedSliderValue = val),
              onSliderChangeEnd: (val) {
                notifier.seek(Duration(milliseconds: val.round()));
                setState(() => _draggedSliderValue = null);
                _restartHideTimer();
              },
              onForwardPressed: () => notifier.forward(85),
              onLockPressed: _toggleLock,
              onSourcePressed: _openSourceSheet,
              onSubtitlePressed: _openSubtitleSheet,
              onServerPressed: _openServerSheet,
              onEpisodePressed: widget.onEpisodesPressed,
            ),
          ),
        ],
      ),
    );
  }

  // --- Sheets Logic ---

  Future<void> _showSheet({required WidgetBuilder builder}) async {
    _hideTimer?.cancel();
    await showModalBottomSheet(
      context: context,
      builder: builder,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      isScrollControlled: true,
    );
    if (mounted) _restartHideTimer();
  }

  void _openSettings() => _showSheet(
        builder: (context) =>
            SettingsSheetContent(onDismiss: () => Navigator.pop(context)),
      );

  void _openQualitySheet() {
    final data = ref.read(episodeDataProvider);
    final notifier = ref.read(episodeDataProvider.notifier);

    _showSheet(
      builder: (context) => GenericSelectionSheet<Map<String, dynamic>>(
        title: 'Quality',
        items: data.qualityOptions,
        selectedIndex: data.selectedQualityIdx ?? -1,
        displayBuilder: (item) => item['quality'] ?? 'Unknown',
        onItemSelected: (index) {
          notifier.changeQuality(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSourceSheet() {
    final data = ref.read(episodeDataProvider);
    final notifier = ref.read(episodeDataProvider.notifier);

    _showSheet(
      builder: (context) => GenericSelectionSheet<Source>(
        title: 'Source',
        items: data.sources,
        selectedIndex: data.selectedSourceIdx ?? -1,
        displayBuilder: (item) => item.quality ?? 'Default Source',
        onItemSelected: (index) {
          notifier.changeSource(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openServerSheet() {
    final data = ref.read(episodeDataProvider);
    if (data.selectedServer == null) return;

    _showSheet(
      builder: (context) => GenericSelectionSheet<String>(
        title: 'Server',
        items: data.servers,
        selectedIndex: data.servers.indexOf(data.selectedServer!),
        displayBuilder: (item) => item,
        onItemSelected: (index) {
          ref
              .read(episodeDataProvider.notifier)
              .changeServer(data.servers.elementAt(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSubtitleSheet() {
    final data = ref.read(episodeDataProvider);

    _showSheet(
      builder: (context) => GenericSelectionSheet<Subtitle>(
        title: 'Subtitle',
        items: data.subtitles,
        selectedIndex: data.selectedSubtitleIdx ?? -1,
        displayBuilder: (item) => item.lang ?? 'Unknown',
        onItemSelected: (index) {
          ref.read(episodeDataProvider.notifier).changeSubtitle(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
