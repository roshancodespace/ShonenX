// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

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

  // --- LIFECYCLE & TIMER LOGIC ---
  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  /// Resets the 5-second auto-hide timer. Called on any user interaction.
  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    // Don't start a timer if locked or if controls are already meant to be hidden.
    if (_isLocked || !_areControlsVisible) return;

    _hideControlsTimer = Timer(const Duration(seconds: 5), _hideControls);
  }

  /// Hides the controls immediately.
  void _hideControls() {
    if (mounted) {
      setState(() => _areControlsVisible = false);
      _hideControlsTimer?.cancel();
    }
  }

  /// Shows the controls if they are currently hidden.
  void _showControls() {
    if (mounted && !_areControlsVisible) {
      setState(() => _areControlsVisible = true);
      _resetHideTimer(); // Start the auto-hide timer after showing.
    }
  }

  /// Toggles the screen lock.
  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _areControlsVisible =
          true; // Always show controls when locking/unlocking.
      _resetHideTimer();
    });
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // This GestureDetector covers the whole screen and is responsible for SHOWING the controls.
    return GestureDetector(
      onTap: _showControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The main controls UI, animated with opacity.
          AnimatedOpacity(
            opacity: _areControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AbsorbPointer(
              // Block interactions with the controls when they are invisible.
              absorbing: !_areControlsVisible,
              child: _buildControlsUI(),
            ),
          ),

          // Subtitle Overlay. Moves up when controls are visible.
          Positioned(
            bottom: _areControlsVisible && !_isLocked ? 150 : 20,
            left: 20,
            right: 20,
            child: const _SubtitleOverlay(),
          ),
        ],
      ),
    );
  }

  /// Builds the controls area, including the logic for HIDING them.
  Widget _buildControlsUI() {
    // This detector sits on top of the controls and HIDES them when the empty space is tapped.
    return GestureDetector(
      onTap: _hideControls,
      child: Container(
        color: Colors.transparent, // Makes the GestureDetector tappable.
        child: _isLocked ? _buildLockMode() : _buildFullControls(),
      ),
    );
  }

  /// Builds the simple "Unlock" button UI.
  Widget _buildLockMode() {
    return Center(
      // A GestureDetector to prevent the background tap from hiding the unlock button.
      child: GestureDetector(
        onTap: _resetHideTimer, // Tapping the button resets the timer.
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

  /// Builds the main top, center, and bottom controls.
  Widget _buildFullControls() {
    return Column(
      children: [
        // Top Controls with slide-down animation.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : -100, 0),
          child: _TopControls(
            onInteraction: _resetHideTimer,
            onEpisodesPressed: widget.onEpisodesPressed,
            onSettingsPressed: _showSettingsSheet,
            onQualityPressed: _showQualitySheet,
          ),
        ),

        // Center play/pause button.
        Expanded(
          child: Center(
            child: _CenterControls(onInteraction: _resetHideTimer),
          ),
        ),

        // Bottom Controls with slide-up animation.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : 150, 0),
          child: _BottomControls(
            onInteraction: _resetHideTimer,
            sliderValue: _draggedSliderValue,
            onSliderChangeStart: (val) {
              _hideControlsTimer?.cancel(); // Pause timer while scrubbing.
              setState(() => _draggedSliderValue = val);
            },
            onSliderChanged: (val) => setState(() => _draggedSliderValue = val),
            onSliderChangeEnd: (val) {
              ref
                  .read(playerStateProvider.notifier)
                  .seek(Duration(milliseconds: val.round()));
              setState(() => _draggedSliderValue = null);
              _resetHideTimer(); // Restart timer after scrubbing is done.
            },
            onLockPressed: _toggleLock,
            onSourcePressed: _showSourceSheet,
            onSubtitlePressed: _showSubtitleSheet,
            onServerPressed: _showServerSheet,
          ),
        ),
      ],
    );
  }

  // --- MODAL SHEET HANDLERS ---
  /// A helper to show a modal sheet and manage the hide timer.
  Future<void> _showPlayerModalSheet({required WidgetBuilder builder}) async {
    _hideControlsTimer?.cancel();
    await showModalBottomSheet(
      context: context,
      builder: builder,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      isScrollControlled: true,
    );
    if (mounted) _resetHideTimer(); // Reset timer after the sheet is closed.
  }

  void _showSettingsSheet() => _showPlayerModalSheet(
        builder: (context) => _SettingsSheetContent(
          onDismiss: () => Navigator.pop(context),
        ),
      );

  void _showQualitySheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<Map<String, dynamic>>(
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
      builder: (context) => _GenericSelectionSheet<Source>(
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
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<String>(
        title: 'Server',
        items: episodeData.servers,
        selectedIndex: episodeData.selectedSourceIdx ?? -1,
        displayBuilder: (item) => item,
        onItemSelected: (index) {
          episodeNotifier.changeSource(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubtitleSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<Subtitle>(
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

// --- REUSABLE WIDGETS ---

/// A generic bottom sheet for selecting an item from a list.
class _GenericSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int selectedIndex;
  final String Function(T item) displayBuilder;
  final void Function(int index) onItemSelected;

  const _GenericSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.displayBuilder,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            if (items.isEmpty)
              const Center(child: Text("No options available"))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      title: Text(displayBuilder(item)),
                      selected: isSelected,
                      trailing:
                          isSelected ? const Icon(Iconsax.tick_circle) : null,
                      onTap: () => onItemSelected(index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The top control bar (back button, title, settings).
class _TopControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onQualityPressed;

  const _TopControls({
    required this.onInteraction,
    this.onEpisodesPressed,
    this.onSettingsPressed,
    this.onQualityPressed,
  });

  // Helper to wrap button presses with the interaction callback.
  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      onInteraction();
      action();
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeData = ref.watch(episodeDataProvider);
    final source = ref.watch(selectedAnimeProvider);
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: onInteraction, // Prevents background tap from hiding controls.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                  onPressed: _wrap(() => context.pop()),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: "Back"),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source?.providerName.toUpperCase() ?? "SOURCE",
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      episodeData.episodes[episodeData.selectedEpisodeIdx ?? 0]
                              .title ??
                          'Unavailable',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (episodeData.qualityOptions.length > 1)
                IconButton(
                    onPressed: _wrap(onQualityPressed),
                    icon: const Icon(Iconsax.video_horizontal),
                    tooltip: "Quality"),
              if (onEpisodesPressed != null)
                IconButton(
                    onPressed: _wrap(onEpisodesPressed),
                    icon: const Icon(Icons.playlist_play),
                    tooltip: "Episodes"),
              IconButton(
                  onPressed: _wrap(onSettingsPressed),
                  icon: const Icon(Iconsax.setting_2),
                  tooltip: "Settings"),
            ],
          ),
        ),
      ),
    );
  }
}

/// The center play/pause/buffering indicator.
class _CenterControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  const _CenterControls({required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);
    return GestureDetector(
      onTap: onInteraction, // Prevents background tap from hiding controls.
      child: playerState.isBuffering
          ? const SizedBox(
              width: 80, height: 80, child: CircularProgressIndicator())
          : IconButton(
              onPressed: () {
                onInteraction(); // Reset timer on play/pause.
                playerNotifier.togglePlay();
              },
              icon:
                  Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 80,
            ),
    );
  }
}

/// The bottom control bar (slider, timestamps, action buttons).
class _BottomControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final double? sliderValue;
  final Function(double) onSliderChanged;
  final Function(double) onSliderChangeStart;
  final Function(double) onSliderChangeEnd;
  final VoidCallback onLockPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onServerPressed;

  const _BottomControls(
      {required this.onInteraction,
      this.sliderValue,
      required this.onSliderChanged,
      required this.onSliderChangeStart,
      required this.onSliderChangeEnd,
      required this.onLockPressed,
      required this.onSourcePressed,
      required this.onSubtitlePressed,
      required this.onServerPressed});

  // Helper to wrap button presses with the interaction callback.
  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      onInteraction();
      action();
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final episodeData = ref.watch(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);

    final positionMs = playerState.position.inMilliseconds.toDouble();
    final durationMs = playerState.duration.inMilliseconds.toDouble();
    final displayedValue = (sliderValue ?? positionMs).clamp(0.0, durationMs);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: onInteraction, // Prevents background tap from hiding controls.
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(_formatDuration(
                      Duration(milliseconds: displayedValue.round()))),
                ),
                Expanded(
                  child: Slider(
                    value: displayedValue,
                    max: durationMs > 0 ? durationMs : 1.0,
                    onChanged: onSliderChanged,
                    onChangeStart: onSliderChangeStart,
                    onChangeEnd: onSliderChangeEnd,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(_formatDuration(playerState.duration)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                    onPressed: _wrap(onLockPressed),
                    label: const Text('Lock'),
                    icon: const Icon(Iconsax.lock)),
                if (episodeData.dubSubSupport)
                  TextButton.icon(
                    onPressed: _wrap(() => episodeNotifier.toggleDubSub()),
                    label: Text(
                        episodeData.selectedCategory == 'sub' ? 'Sub' : 'Dub'),
                    icon: const Icon(Iconsax.text_block),
                  ),
                if (episodeData.servers.isNotEmpty)
                  TextButton.icon(
                    onPressed: _wrap(onServerPressed),
                    label: Text(episodeData.selectedServer ?? 'Server'),
                    icon: const Icon(Iconsax.d_cube_scan),
                  ),
                TextButton.icon(
                  onPressed: episodeData.sources.length > 1
                      ? _wrap(onSourcePressed)
                      : null,
                  label: const Text('Source'),
                  icon: const Icon(Iconsax.hierarchy_2),
                ),
                TextButton.icon(
                  onPressed: episodeData.subtitles.isNotEmpty
                      ? _wrap(onSubtitlePressed)
                      : null,
                  label: const Text('Subtitle'),
                  icon: const Icon(Iconsax.subtitle),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// The overlay that displays the current subtitle text.
class _SubtitleOverlay extends ConsumerWidget {
  const _SubtitleOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleText =
        ref.watch(playerStateProvider.select((s) => s.subtitle.firstOrNull));

    if (subtitleText == null || subtitleText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          subtitleText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

/// The content for the player settings bottom sheet.
class _SettingsSheetContent extends ConsumerWidget {
  final VoidCallback onDismiss;
  const _SettingsSheetContent({required this.onDismiss});

  void _showDialog(BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    showDialog(context: context, builder: builder).then((_) {
      if (Navigator.of(context).canPop()) onDismiss();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Iconsax.speedometer),
              title: const Text("Playback Speed"),
              trailing: Text("${playerState.playbackSpeed}x"),
              onTap: () =>
                  _showDialog(context, builder: (ctx) => _SpeedDialog()),
            ),
            ListTile(
              leading: const Icon(Iconsax.crop),
              title: const Text("Video Fit"),
              trailing: Text(_fitModeToString(playerState.fit)),
              onTap: () => _showDialog(context, builder: (ctx) => _FitDialog()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for changing playback speed.
class _SpeedDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends ConsumerState<_SpeedDialog> {
  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    _selectedSpeed = ref.read(playerStateProvider).playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Playback Speed"),
      content: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
            .map((speed) => ChoiceChip(
                  label: Text("${speed}x"),
                  selected: _selectedSpeed == speed,
                  onSelected: (isSelected) {
                    if (isSelected) setState(() => _selectedSpeed = speed);
                  },
                ))
            .toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setSpeed(_selectedSpeed);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

/// Dialog for changing the video fit mode.
class _FitDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FitDialog> createState() => _FitDialogState();
}

class _FitDialogState extends ConsumerState<_FitDialog> {
  late BoxFit _selectedFit;
  static const fitModes = [BoxFit.contain, BoxFit.cover, BoxFit.fill];

  @override
  void initState() {
    super.initState();
    _selectedFit = ref.read(playerStateProvider).fit;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Video Fit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: fitModes
            .map((fit) => RadioListTile<BoxFit>(
                  title: Text(_fitModeToString(fit)),
                  value: fit,
                  groupValue: _selectedFit,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedFit = value);
                  },
                ))
            .toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setFit(_selectedFit);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

// --- HELPER FUNCTIONS ---

/// Formats a Duration into hh:mm:ss or mm:ss.
String _formatDuration(Duration duration) {
  if (duration.isNegative) return '00:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

/// Converts a BoxFit enum to a readable string.
String _fitModeToString(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'Contain';
    case BoxFit.cover:
      return 'Cover';
    case BoxFit.fill:
      return 'Fill';
    default:
      return 'Fit';
  }
}
