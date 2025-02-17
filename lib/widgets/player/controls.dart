import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/continue_watching_box.dart';
import 'package:shonenx/data/hive/models/continue_watching_model.dart';
import 'package:shonenx/utils/compression.dart';

class CustomControls extends StatefulWidget {
  final VideoState state;
  final Media animeMedia;
  final List<Map<String, String>> qualityOptions;
  final Function(String) changeQuality;
  final int currentEpisodeIndex;
  final List<EpisodeDataModel> episodes;

  const CustomControls({
    super.key,
    required this.state,
    required this.animeMedia,
    required this.changeQuality,
    required this.qualityOptions,
    required this.currentEpisodeIndex,
    required this.episodes,
  });

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  late Timer? progressSaveTimer;
  late ContinueWatchingBox? continueWatchingBox;
  bool isBuffering = true;
  bool isPlaying = true;
  bool showControls = true;
  Duration? staticPositionDrag;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isFullScreen = false;
  double volume = 1.0;
  double playbackSpeed = 1.0;
  Timer? _hideTimer;
  bool _showSettings = false;
  String _currentSettingsPage = 'main';

  final List<double> _playbackSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
  ];

  @override
  void initState() {
    super.initState();
    _initializeContinueWatchingBox();
    _initializeState();
    _attachListeners();
    _startHideTimer();
    _startProgressSaveTimer();
  }

  Future<void> _initializeContinueWatchingBox() async {
    continueWatchingBox = ContinueWatchingBox();
    await continueWatchingBox?.init();
  }

  Future<void> _startProgressSaveTimer() async {
    progressSaveTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final thumbnail = await widget.state.widget.controller.player
          .screenshot(format: 'image/png');
      final thumbnailCompressed = await compressUint8ListToBase64(thumbnail!);
      if (continueWatchingBox != null) {
        final episode = widget.episodes[widget.currentEpisodeIndex];
        continueWatchingBox?.setEntry(
          ContinueWatchingEntry(
            animeId: widget.animeMedia.id!,
            animeTitle: widget.animeMedia.title?.english ??
                widget.animeMedia.title?.native ??
                widget.animeMedia.title?.romaji ??
                '',
            animeCover: widget.animeMedia.coverImage?.large ??
                widget.animeMedia.coverImage?.medium ??
                '',
            animeFormat: widget.animeMedia.format,
            episodeThumbnail: thumbnailCompressed,
            episodeNumber: episode.number!,
            episodeTitle: episode.title!,
            totalEpisodes: widget.episodes.length,
            progressInSeconds: position.inSeconds,
            durationInSeconds: duration.inSeconds,
            lastUpdated: DateTime.now().toIso8601String(),
          ),
        );
      }
    });
  }

  void _initializeState() {
    final player = widget.state.widget.controller.player;
    setState(() {
      duration = player.state.duration;
      position = player.state.position;
      volume = player.state.volume / 100; // Convert volume to 0.0-1.0 range
      isPlaying = player.state.playing;
      isBuffering = player.state.buffering;
    });
  }

  void _attachListeners() {
    final player = widget.state.widget.controller.player;

    player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => isBuffering = buffering);
    });

    player.stream.playing.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    player.stream.position.listen((pos) {
      if (mounted) setState(() => position = pos);
    });

    player.stream.duration.listen((dur) {
      if (mounted) setState(() => duration = dur);
    });

    player.stream.volume.listen((vol) {
      if (mounted) {
        setState(() => volume = vol / 100); // Convert to 0.0-1.0 range
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showControls = false);
    });
  }

  void _resetHideTimer() {
    if (mounted) {
      setState(() => showControls = true);
      _startHideTimer();
    }
  }

  void _toggleFullScreen() {
    final isFull = isFullscreen(widget.state.context);
    if (isFull) {
      widget.state.exitFullscreen();
    } else {
      widget.state.enterFullscreen();
    }
    if (mounted) setState(() => isFullScreen = !isFull);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    progressSaveTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetHideTimer,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Gradient overlay
          if (showControls)
            AnimatedOpacity(
              opacity: showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
              ),
            ),

          // Controls
          if (showControls)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopBar(),
                  _buildCenterControls(),
                  _buildBottomControls(),
                ],
              ),
            ),

          // Settings overlay
          if (_showSettings) _buildSettingsOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _showSettings = true),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 40,
          onPressed: () {
            final player = widget.state.widget.controller.player;
            player.seek(Duration(seconds: position.inSeconds - 10));
          },
          icon: const Icon(Iconsax.backward_10_seconds, color: Colors.white),
        ),
        const SizedBox(width: 24),
        _buildPlayPauseButton(),
        const SizedBox(width: 24),
        IconButton(
          iconSize: 40,
          onPressed: () {
            final player = widget.state.widget.controller.player;
            player.seek(Duration(seconds: position.inSeconds + 10));
          },
          icon: const Icon(Iconsax.forward_10_seconds, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    if (isBuffering) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return IconButton(
      iconSize: 48,
      onPressed: () {
        final player = widget.state.widget.controller.player;
        if (isPlaying) {
          player.pause();
        } else {
          player.play();
        }
      },
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Progress bar
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white38,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: staticPositionDrag == null
                ? position.inSeconds.toDouble()
                : staticPositionDrag!.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            onChanged: (value) {
              staticPositionDrag = Duration(seconds: value.toInt());
            },
            onChangeEnd: (value) async {
              final player = widget.state.widget.controller.player;
              await player.seek(Duration(seconds: value.toInt()));
              staticPositionDrag = null;
            },
          ),
        ),

        // Bottom row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
          child: Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white),
              ),
              const Text(
                ' / ',
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleFullScreen,
                icon: Icon(
                  isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOverlay() {
    return Container(
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsHeader(),
          Expanded(
            child: _currentSettingsPage == 'main'
                ? _buildMainSettingsMenu()
                : _buildSettingsSubPage(_currentSettingsPage),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return ListTile(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (_currentSettingsPage == 'main') {
            setState(() => _showSettings = false);
          } else {
            setState(() => _currentSettingsPage = 'main');
          }
        },
      ),
      title: Text(
        _getSettingsTitle(),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  String _getSettingsTitle() {
    switch (_currentSettingsPage) {
      case 'quality':
        return 'Video Quality';
      case 'speed':
        return 'Playback Speed';
      case 'audio':
        return 'Audio Settings';
      default:
        return 'Settings';
    }
  }

  Widget _buildMainSettingsMenu() {
    return ListView(
      children: [
        _buildSettingsItem(
          icon: Icons.high_quality,
          title: 'Quality',
          subtitle: widget.state.widget.controller.player.state.width != null
              ? '${widget.state.widget.controller.player.state.height}p'
              : 'Auto',
          onTap: () => setState(() => _currentSettingsPage = 'quality'),
        ),
        _buildSettingsItem(
          icon: Icons.speed,
          title: 'Playback Speed',
          subtitle: '${playbackSpeed}x',
          onTap: () => setState(() => _currentSettingsPage = 'speed'),
        ),
        _buildSettingsItem(
          icon: Icons.volume_up,
          title: 'Volume',
          subtitle: '${(volume * 100).round()}%',
          onTap: () => setState(() => _currentSettingsPage = 'audio'),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildSettingsSubPage(String page) {
    switch (page) {
      case 'quality':
        return _buildQualitySettings();
      case 'speed':
        return _buildSpeedSettings();
      case 'audio':
        return _buildAudioSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQualitySettings() {
    return ListView(
      children: widget.qualityOptions.map((quality) {
        return ListTile(
          title: Text(
            quality['quality']!,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: Icon(
            Icons.check,
            color: quality['quality'] == 'Auto'
                ? Colors.white
                : Colors.transparent,
          ),
          onTap: () {
            widget.changeQuality(quality['url']!);
            setState(() => _showSettings = false);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSpeedSettings() {
    return ListView(
      children: _playbackSpeeds.map((speed) {
        return ListTile(
          title: Text(
            '${speed}x',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: Icon(
            Icons.check,
            color: speed == playbackSpeed ? Colors.white : Colors.transparent,
          ),
          onTap: () {
            setState(() => playbackSpeed = speed);
            widget.state.widget.controller.player.setRate(speed);
          },
        );
      }).toList(),
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.volume_up, color: Colors.white),
          title: const Text('Volume', style: TextStyle(color: Colors.white)),
          subtitle: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white38,
              thumbColor: Colors.blueAccent,
            ),
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() => volume = value);
                widget.state.widget.controller.player.setVolume(value * 100);
              },
            ),
          ),
        ),
      ],
    );
  }
}
