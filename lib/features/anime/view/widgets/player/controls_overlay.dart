import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/anime/view/widgets/player/bottom_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/center_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/subtitle_overlay.dart';
import 'package:shonenx/features/anime/view/widgets/player/top_controls.dart';
import 'package:shonenx/features/anime/view/widgets/player/components/seek_indicator.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/generic_selection_sheet.dart';
import 'package:shonenx/features/anime/view/widgets/player/sheets/settings_sheet.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class CloudstreamControls extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;
  const CloudstreamControls({super.key, this.onEpisodesPressed});

  @override
  ConsumerState<CloudstreamControls> createState() =>
      _CloudstreamControlsState();
}

class _CloudstreamControlsState extends ConsumerState<CloudstreamControls> {
  bool _visible = true;
  bool _locked = false;
  int _seekAccum = 0;

  Timer? _hideTimer;
  Timer? _seekResetTimer;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _restartHide();
  }

  @override
  void dispose() {
    _focus.dispose();
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

  void _onDoubleTap(TapDownDetails d) {
    if (_locked) return;

    final w = MediaQuery.of(context).size.width;
    final forward = d.globalPosition.dx > w / 2;
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

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerStateProvider.notifier);

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
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: GestureDetector(
          onTap: _toggle,
          onDoubleTapDown: _onDoubleTap,
          behavior: HitTestBehavior.translucent,
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
              Positioned(
                left: 8,
                right: 8,
                bottom: _visible ? 90 : 20,
                child: const SubtitleOverlay(),
              ),
            ],
          ),
        ),
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
    double? draggedSliderValue;
    final notifier = ref.read(playerStateProvider.notifier);

    return Stack(
      children: [
        Center(child: CenterControls(onInteraction: _restartHide)),
        TopControls(
          onInteraction: _restartHide,
          onEpisodesPressed: widget.onEpisodesPressed,
          onSettingsPressed: _openSettings,
          onQualityPressed: _openQuality,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomControls(
            onInteraction: _restartHide,
            onLockPressed: _toggleLock,
            onEpisodePressed: widget.onEpisodesPressed,
            onForwardPressed: () => notifier.forward(85),
            onSourcePressed: _openSource,
            onSubtitlePressed: _openSubtitle,
            onServerPressed: _openServer,
            onSliderChangeStart: (val) {
              _hideTimer?.cancel();
              setState(() => draggedSliderValue = val);
            },
            onSliderChanged: (val) => setState(() => draggedSliderValue = val),
            onSliderChangeEnd: (val) {
              notifier.seek(Duration(milliseconds: val.round()));
              setState(() => draggedSliderValue = null);
              _restartHide();
            },
            sliderValue: draggedSliderValue,
          ),
        ),
      ],
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
    final data = ref.read(episodeDataProvider);

    _sheet(
      GenericSelectionSheet<Subtitle>(
        title: 'Subtitle',
        items: data.subtitles,
        selectedIndex: data.selectedSubtitleIdx,
        displayBuilder: (e) => e.lang ?? '',
        onItemSelected: (i) {
          ref.read(episodeDataProvider.notifier).changeSubtitle(i);
          Navigator.pop(context);
        },
      ),
    );
  }
}
