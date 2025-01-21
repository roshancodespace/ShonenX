import 'dart:ui';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class CustomControlsWidget extends StatefulWidget {
  final BetterPlayerController? controller;
  final Function(bool visibility)? onControlsVisibilityChanged;
  final String? subtitle;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const CustomControlsWidget({
    super.key,
    this.controller,
    this.onControlsVisibilityChanged,
    this.subtitle,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<CustomControlsWidget> createState() => _CustomControlsWidgetState();
}

class _CustomControlsWidgetState extends State<CustomControlsWidget>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  double _currentVolume = 1.0;
  bool _isMuted = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLocked = false;
  bool _isBuffering = false;
  late AnimationController _fadeController;
  bool _isDoubleTapEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _startControlsTimer();
  }

  void _initializePlayer() {
    widget.controller?.videoPlayerController?.addListener(_updateState);
    widget.controller?.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.bufferingStart) {
        setState(() => _isBuffering = true);
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.bufferingEnd) {
        setState(() => _isBuffering = false);
      }
    });
    _updateState();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls && !_isLocked) {
        setState(() {
          _showControls = false;
          widget.onControlsVisibilityChanged?.call(false);
        });
      }
    });
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _currentPosition =
          widget.controller?.videoPlayerController?.value.position ??
              Duration.zero;
      _totalDuration =
          widget.controller?.videoPlayerController?.value.duration ??
              Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  void _showVolumeModal() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Volume', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    icon: HugeIcon(
                      icon: _isMuted
                          ? HugeIcons.strokeRoundedVolumeMute01
                          : HugeIcons.strokeRoundedVolumeHigh,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        widget.controller
                            ?.setVolume(_isMuted ? 0 : _currentVolume);
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        thumbColor: theme.colorScheme.primary,
                        overlayColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _currentVolume,
                        onChanged: (value) {
                          setState(() {
                            _currentVolume = value;
                            _isMuted = value == 0;
                            widget.controller?.setVolume(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsModal() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.speed, color: theme.colorScheme.onSurface),
                  title:
                      Text('Playback Speed', style: theme.textTheme.bodyLarge),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface),
                  onTap: () {
                    Navigator.pop(context);
                    _showPlaybackSpeedDialog();
                  },
                ),
                ListTile(
                  leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedVolumeHigh,
                      color: theme.colorScheme.onSurface),
                  title: Text('Volume', style: theme.textTheme.bodyLarge),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface),
                  onTap: () {
                    Navigator.pop(context);
                    _showVolumeModal();
                  },
                ),
                ListTile(
                  leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedVideo02,
                      color: theme.colorScheme.onSurface),
                  title: Text(
                      widget.controller?.betterPlayerAsmsTrack?.height == 0
                          ? 'Auto'
                          : '${widget.controller?.betterPlayerAsmsTrack!.height}p',
                      style: theme.textTheme.bodyLarge),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface),
                  onTap: () {
                    Navigator.pop(context);
                    _showQualitiesDialog();
                  },
                ),
                ListTile(
                  leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedSubtitle,
                      color: theme.colorScheme.onSurface),
                  title: Text('Subtitles', style: theme.textTheme.bodyLarge),
                  trailing: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface),
                  onTap: () {
                    Navigator.pop(context);
                    _showSubtitlesDialog();
                  },
                ),
                SwitchListTile(
                  secondary: HugeIcon(
                      icon: HugeIcons.strokeRoundedTap02,
                      color: theme.colorScheme.onSurface),
                  title:
                      Text('Double Tap Seek', style: theme.textTheme.bodyLarge),
                  value: _isDoubleTapEnabled,
                  onChanged: (value) {
                    setState(() => _isDoubleTapEnabled = value);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQualitiesDialog() {
    final theme = Theme.of(context);
    final tracks = widget.controller?.betterPlayerAsmsTracks;

    // Ensure the controller and tracks are valid
    if (widget.controller == null || tracks == null || tracks.isEmpty) {
      return;
    }

    // Filter video tracks and sort by height
    final videoTracks = tracks
        .where((track) => track.width != null && track.height != null)
        .toList()
      ..sort((a, b) => b.height!.compareTo(a.height!));

    if (videoTracks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quality', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ...videoTracks.map((track) {
                final quality = track.height == 0 ? 'Auto' : '${track.height}p';
                final isSelected =
                    widget.controller?.betterPlayerAsmsTrack == track;

                return ListTile(
                  title: Text(quality, style: theme.textTheme.bodyLarge),
                  trailing: Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (_) {
                      widget.controller?.setTrack(track);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubtitlesDialog() {
    final theme = Theme.of(context);
    final currentSource = widget.controller?.betterPlayerSubtitlesSource;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Subtitles', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Off', style: theme.textTheme.bodyLarge),
                  trailing: Radio<BetterPlayerSubtitlesSource?>(
                    value: null,
                    groupValue: currentSource,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      widget.controller?.setupSubtitleSource(value!);
                      Navigator.pop(context);
                    },
                  ),
                ),
                if (widget.controller?.betterPlayerSubtitlesSourceList != null)
                  ...widget.controller!.betterPlayerSubtitlesSourceList
                      .map((source) {
                    if (source.name == null) return const SizedBox.shrink();
                    return ListTile(
                      title:
                          Text(source.name!, style: theme.textTheme.bodyLarge),
                      trailing: Radio<BetterPlayerSubtitlesSource>(
                        value: source,
                        groupValue: currentSource,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          widget.controller?.setupSubtitleSource(value!);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaybackSpeedDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Playback Speed', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ...([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map(
                (speed) => ListTile(
                  title: Text('${speed}x', style: theme.textTheme.bodyLarge),
                  trailing: Radio<double>(
                    value: speed,
                    groupValue:
                        widget.controller?.videoPlayerController?.value.speed ??
                            1.0,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      widget.controller?.setSpeed(value!);
                      Navigator.pop(context);
                    },
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controlBackground = theme.colorScheme.surface.withValues(alpha: 0.3);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
            widget.onControlsVisibilityChanged?.call(_showControls);
            if (_showControls) _startControlsTimer();
          });
        },
        onDoubleTapDown: _isDoubleTapEnabled
            ? (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  widget.controller?.seekTo(
                      Duration(seconds: _currentPosition.inSeconds - 10));
                } else {
                  widget.controller?.seekTo(
                      Duration(seconds: _currentPosition.inSeconds + 10));
                }
              }
            : null,
        child: AbsorbPointer(
          absorbing: !_showControls,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      if (_isBuffering)
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: controlBackground,
                                  child: IconButton(
                                    icon: HugeIcon(
                                        icon: _isLocked
                                            ? HugeIcons.strokeRoundedLocked
                                            : Icons.lock,
                                        color: theme.colorScheme.onSurface),
                                    onPressed: () =>
                                        setState(() => _isLocked = !_isLocked),
                                  ),
                                ),
                                if (!_isLocked)
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: controlBackground,
                                        child: IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: _showSettingsModal,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      CircleAvatar(
                                        backgroundColor: controlBackground,
                                        child: IconButton(
                                          icon: Icon(
                                            widget.controller?.isFullScreen ??
                                                    false
                                                ? Icons.fullscreen_exit
                                                : Icons.fullscreen,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          onPressed: () {
                                            if (widget
                                                    .controller?.isFullScreen ??
                                                false) {
                                              widget.controller
                                                  ?.exitFullScreen();
                                            } else {
                                              widget.controller
                                                  ?.enterFullScreen();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Center Controls
                          if (!_isLocked)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.onPrevious != null)
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: controlBackground,
                                    child: IconButton(
                                      iconSize: 32,
                                      icon: const Icon(Icons.skip_previous),
                                      onPressed: widget.onPrevious,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                const SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    iconSize: 32,
                                    icon: HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedGoBackward10Sec,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                    onPressed: () => widget.controller?.seekTo(
                                      Duration(
                                          seconds:
                                              _currentPosition.inSeconds - 10),
                                    ),
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(5),
                                  child: IconButton(
                                    icon: HugeIcon(
                                      icon: _isBuffering
                                          ? Icons.hourglass_empty
                                          : widget.controller?.isPlaying() ??
                                                  false
                                              ? HugeIcons.strokeRoundedPause
                                              : Icons.play_arrow,
                                      size: 35,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (widget.controller?.isPlaying() ??
                                            false) {
                                          widget.controller?.pause();
                                        } else {
                                          widget.controller?.play();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    iconSize: 32,
                                    icon: HugeIcon(
                                      icon:
                                          HugeIcons.strokeRoundedGoForward10Sec,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                    onPressed: () => widget.controller?.seekTo(
                                      Duration(
                                          seconds:
                                              _currentPosition.inSeconds + 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                if (widget.onNext != null)
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: controlBackground,
                                    child: IconButton(
                                      iconSize: 32,
                                      icon: const Icon(Icons.skip_next),
                                      onPressed: widget.onNext,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                              ],
                            ),

                          // Bottom Controls
                          if (!_isLocked)
                            Column(
                              children: [
                                if (widget.subtitle != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.subtitle!,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _formatDuration(_currentPosition),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            activeTrackColor: theme
                                                .colorScheme.primaryContainer,
                                            inactiveTrackColor: Colors.white
                                                .withValues(alpha: 0.3),
                                            thumbColor: Colors.white,
                                            overlayColor: Colors.white
                                                .withValues(alpha: 0.2),
                                            trackHeight: 8.0,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                              enabledThumbRadius: 4.0,
                                              pressedElevation: 4.0,
                                            ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                              overlayRadius: 20.0,
                                            ),
                                          ),
                                          child: Slider(
                                            value: _currentPosition.inSeconds
                                                .toDouble(),
                                            min: 0,
                                            max: _totalDuration.inSeconds
                                                .toDouble(),
                                            onChanged: (value) {
                                              widget.controller?.seekTo(
                                                Duration(
                                                    seconds: value.toInt()),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_totalDuration),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.videoPlayerController?.removeListener(_updateState);
    _fadeController.dispose();
    super.dispose();
  }
}
