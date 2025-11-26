import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/seek_indicator.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/generic_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/settings_sheet.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

// --- MAIN WIDGET ---
class CloudstreamControls extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;

  const CloudstreamControls({
    super.key,
    this.onEpisodesPressed,
  });

  @override
  ConsumerState<CloudstreamControls> createState() =>
      _CloudstreamControlsState();
}

class _CloudstreamControlsState extends ConsumerState<CloudstreamControls> {
  // --- STATE VARIABLES ---
  bool _areControlsVisible = true;
  bool _isLocked = false;
  Timer? _hideControlsTimer;
  double? _draggedSliderValue;

  // Double tap seek state
  Timer? _seekResetTimer;
  int _cumulativeSeek = 0;
  bool _showForwardSeek = false;
  bool _showRewindSeek = false;

  // --- LIFECYCLE & TIMER LOGIC ---
  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _seekResetTimer?.cancel();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    if (_isLocked || !_areControlsVisible) return;

    _hideControlsTimer = Timer(const Duration(seconds: 5), _hideControls);
  }

  void _hideControls() {
    if (mounted) {
      setState(() => _areControlsVisible = false);
      _hideControlsTimer?.cancel();
    }
  }

  void _showControls() {
    if (mounted && !_areControlsVisible) {
      setState(() => _areControlsVisible = true);
      _resetHideTimer();
    }
  }

  /// Toggles the screen lock.
  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _areControlsVisible = true;
      _resetHideTimer();
    });
  }

  // Handle Double Click
  void _handleDoubleClick(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final isForward = tapX > screenWidth / 2;

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

    final playerNotifier = ref.read(playerStateProvider.notifier);
    if (isForward) {
      playerNotifier.forward(10);
    } else {
      playerNotifier.rewind(10);
    }

    _seekResetTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showForwardSeek = false;
          _showRewindSeek = false;
          _cumulativeSeek = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the provider alive to prevent state loss
    ref.watch(episodeDataProvider);

    return GestureDetector(
      onTap: _showControls,
      onDoubleTapDown: _handleDoubleClick,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _areControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AbsorbPointer(
              absorbing: !_areControlsVisible,
              child: _buildControlsUI(),
            ),
          ),

          // Rewind Indicator
          if (_showRewindSeek)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SeekIndicatorOverlay(
                  isForward: false,
                  seconds: _cumulativeSeek.abs(),
                ),
              ),
            ),

          // Forward Indicator
          if (_showForwardSeek)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SeekIndicatorOverlay(
                  isForward: true,
                  seconds: _cumulativeSeek.abs(),
                ),
              ),
            ),

          Positioned(
            left: 8,
            right: 8,
            top: _areControlsVisible && !_isLocked ? 90 : 20,
            bottom: _areControlsVisible && !_isLocked ? 90 : 20,
            child: const SubtitleOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsUI() {
    return GestureDetector(
      onTap: _hideControls,
      onDoubleTapDown: _handleDoubleClick,
      child: Container(
        color: Colors.transparent,
        child: _isLocked ? _buildLockMode() : _buildFullControls(),
      ),
    );
  }

  Widget _buildLockMode() {
    return Center(
      child: GestureDetector(
        onTap: _resetHideTimer,
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: _toggleLock,
          icon: const Icon(Icons.lock_open, size: 32, color: Colors.white),
          tooltip: 'Unlock',
        ),
      ),
    );
  }

  Widget _buildFullControls() {
    final playerNotifier = ref.read(playerStateProvider.notifier);

    return Stack(
      children: [
        /// Center Controls
        Positioned.fill(
          child: Center(
            child: CenterControls(onInteraction: _resetHideTimer),
          ),
        ),

        /// Top Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : -100, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: TopControls(
              onInteraction: _resetHideTimer,
              onEpisodesPressed: widget.onEpisodesPressed,
              onSettingsPressed: _showSettingsSheet,
              onQualityPressed: _showQualitySheet,
            ),
          ),
        ),

        // /// Bottom Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : 150, 0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: BottomControls(
              onInteraction: _resetHideTimer,
              sliderValue: _draggedSliderValue,
              onSliderChangeStart: (val) {
                _hideControlsTimer?.cancel();
                setState(() => _draggedSliderValue = val);
              },
              onForwardPressed: () => playerNotifier.forward(85),
              onSliderChanged: (val) =>
                  setState(() => _draggedSliderValue = val),
              onSliderChangeEnd: (val) {
                playerNotifier.seek(Duration(milliseconds: val.round()));
                setState(() => _draggedSliderValue = null);
                _resetHideTimer();
              },
              onLockPressed: _toggleLock,
              onSourcePressed: _showSourceSheet,
              onSubtitlePressed: _showSubtitleSheet,
              onServerPressed: _showServerSheet,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPlayerModalSheet({required WidgetBuilder builder}) async {
    _hideControlsTimer?.cancel();
    await showModalBottomSheet(
      context: context,
      builder: builder,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      isScrollControlled: true,
    );
    if (mounted) _resetHideTimer();
  }

  void _showSettingsSheet() => _showPlayerModalSheet(
        builder: (context) => SettingsSheetContent(
          onDismiss: () => Navigator.pop(context),
        ),
      );

  void _showQualitySheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => GenericSelectionSheet<Map<String, dynamic>>(
        title: 'Quality',
        items: episodeData.qualityOptions,
        selectedIndex: episodeData.selectedQualityIdx ?? -1,
        displayBuilder: (item) => item['quality'] ?? 'Unknown',
        onItemSelected: (index) {
          episodeNotifier.changeQuality(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSourceSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => GenericSelectionSheet<Source>(
        title: 'Source',
        items: episodeData.sources,
        selectedIndex: episodeData.selectedSourceIdx ?? -1,
        displayBuilder: (item) => item.quality ?? 'Default Source',
        onItemSelected: (index) {
          episodeNotifier.changeSource(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showServerSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    if (episodeData.selectedServer == null) return;
    _showPlayerModalSheet(
      builder: (context) => GenericSelectionSheet<String>(
        title: 'Server',
        items: episodeData.servers,
        selectedIndex: episodeData.servers.indexOf(episodeData.selectedServer!),
        displayBuilder: (item) => item,
        onItemSelected: (index) {
          episodeNotifier.changeServer(episodeData.servers.elementAt(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubtitleSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => GenericSelectionSheet<Subtitle>(
        title: 'Subtitle',
        items: episodeData.subtitles,
        selectedIndex: episodeData.selectedSubtitleIdx ?? -1,
        displayBuilder: (item) => item.lang ?? 'Unknown Subtitle',
        onItemSelected: (index) {
          episodeNotifier.changeSubtitle(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
