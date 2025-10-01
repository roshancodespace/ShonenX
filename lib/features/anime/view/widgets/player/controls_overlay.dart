import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
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
      _resetHideTimer(); // Start the auto-hide timer after showing.
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showControls,
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
          Positioned(
            bottom: _areControlsVisible && !_isLocked ? 150 : 20,
            left: 20,
            right: 20,
            child: const SubtitleOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsUI() {
    return GestureDetector(
      onTap: _hideControls,
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
    if (episodeData.selectedServer == null) return;
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<String>(
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

class _SettingsSheetContent extends ConsumerWidget {
  final VoidCallback onDismiss;
  const _SettingsSheetContent({required this.onDismiss});

  void _showDialog(BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    showDialog(context: context, builder: builder).then((_) {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) onDismiss();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              trailing: Text(
                  "${ref.watch(playerStateProvider.select((p) => p.playbackSpeed))}x"),
              onTap: () =>
                  _showDialog(context, builder: (ctx) => _SpeedDialog()),
            ),
            ListTile(
              leading: const Icon(Iconsax.crop),
              title: const Text("Video Fit"),
              trailing: Text(_fitModeToString(
                  ref.watch(playerStateProvider.select((p) => p.fit)))),
              onTap: () => _showDialog(context, builder: (ctx) => _FitDialog()),
            ),
          ],
        ),
      ),
    );
  }
}

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
