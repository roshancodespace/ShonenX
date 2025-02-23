import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

class CustomControls extends StatefulWidget {
  final VideoState state;
  final anime_media.Media animeMedia;
  final List<SubtitleTrack> subtitles;
  final List<Map<String, String>> qualityOptions;
  final Function(String) changeQuality;
  final int currentEpisodeIndex;
  final List<EpisodeDataModel> episodes;

  const CustomControls({
    super.key,
    required this.subtitles,
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

class _CustomControlsState extends State<CustomControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Timer? progressSaveTimer;
  late AnimeWatchProgressBox? animeWatchProgressBox;
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeContinueWatchingBox();
    _initializeState();
    _attachListeners();
    _startHideTimer();
    _startProgressSaveTimer();
  }

  Future<void> _initializeContinueWatchingBox() async {
    animeWatchProgressBox = AnimeWatchProgressBox();
    await animeWatchProgressBox?.init();
    if (animeWatchProgressBox?.isInitialized == true) {
      await animeWatchProgressBox?.setEntry(
        AnimeWatchProgressEntry(
          animeId: widget.animeMedia.id!,
          animeTitle: widget.animeMedia.title?.english ??
              widget.animeMedia.title?.romaji ??
              widget.animeMedia.title?.native ??
              '',
          animeFormat: widget.animeMedia.format ?? '',
          animeCover: widget.animeMedia.coverImage?.large ??
              widget.animeMedia.coverImage?.medium ??
              '',
          totalEpisodes: widget.episodes.length,
        ),
      );
    }
  }

  Future<void> _startProgressSaveTimer() async {
    progressSaveTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isPlaying) {
        await Future.delayed(
            const Duration(milliseconds: 500)); // Ensure frame is rendered
        final thumbnail = await widget.state.widget.controller.player
            .screenshot(format: 'image/png');
        if (thumbnail != null && animeWatchProgressBox != null) {
          final episode = widget.episodes[widget.currentEpisodeIndex];
          animeWatchProgressBox?.updateEpisodeProgress(
            animeId: widget.animeMedia.id!,
            episodeNumber: episode.number!,
            episodeTitle: episode.title ?? 'Untitled',
            episodeThumbnail: base64Encode(thumbnail),
            progressInSeconds: position.inSeconds,
            durationInSeconds: duration.inSeconds,
          );
        }
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
          // Gradient overlays
          if (showControls)
            FadeTransition(
              opacity: _fadeController,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),

          // Main controls
          if (showControls)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernTopBar(),
                  const Spacer(),
                  _buildModernCenterControls(),
                  const Spacer(),
                  _buildModernBottomControls(),
                ],
              ),
            ),

          // Settings panel
          if (_showSettings) _buildModernSettingsPanel(),
        ],
      ),
    );
  }

  Widget _buildModernTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildIconButton(
            Icons.arrow_back,
            () => context.pop(),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animeMedia.title?.english ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.episodes.isNotEmpty)
                  Text(
                    'Episode ${widget.episodes[widget.currentEpisodeIndex].number}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          _buildSubtitleButton(),
          _buildIconButton(
            Icons.settings,
            () => setState(() => _showSettings = true),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconButton(
          Iconsax.backward_10_seconds,
          () => widget.state.widget.controller.player
              .seek(Duration(seconds: position.inSeconds - 10)),
          size: 36,
        ),
        const SizedBox(width: 32),
        _buildPlayPauseButton(),
        const SizedBox(width: 32),
        _buildIconButton(
          Iconsax.forward_10_seconds,
          () => widget.state.widget.controller.player
              .seek(Duration(seconds: position.inSeconds + 10)),
          size: 36,
        ),
      ],
    );
  }

  Widget _buildModernBottomControls() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildProgressBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildTimeDisplay(),
                const Spacer(),
                _buildVolumeControl(),
                const SizedBox(width: 16),
                _buildFullscreenButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.white24,
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: staticPositionDrag?.inSeconds.toDouble() ??
                position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            onChanged: (value) {
              setState(
                  () => staticPositionDrag = Duration(seconds: value.toInt()));
            },
            onChangeEnd: (value) async {
              await widget.state.widget.controller.player
                  .seek(Duration(seconds: value.toInt()));
              setState(() => staticPositionDrag = null);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    if (isBuffering) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            final player = widget.state.widget.controller.player;
            isPlaying ? player.pause() : player.play();
          },
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {double size = 24}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Text(
      '${_formatDuration(position)} / ${_formatDuration(duration)}',
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Row(
      children: [
        Icon(
          volume == 0
              ? Icons.volume_off
              : volume < 0.5
                  ? Icons.volume_down
                  : Icons.volume_up,
          color: Colors.white,
          size: 24,
        ),
        SizedBox(
          width: 100,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: Theme.of(context).primaryColor,
            ),
            child: Slider(
              value: volume,
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

  Widget _buildSubtitleButton() {
    return PopupMenuButton(
      tooltip: "Subtitles",
      icon: const Icon(Icons.subtitles, color: Colors.white, size: 28),
      itemBuilder: (context) {
        return widget.subtitles.map((sub) {
          return PopupMenuItem(
            onTap: () async {
              await widget.state.widget.controller.player.setSubtitleTrack(sub);
              setState(() => _showSettings = false);
            },
            child: Text(sub.language ?? 'No subtitles'),
          );
        }).toList();
      },
    );
  }

  Widget _buildFullscreenButton() {
    return _buildIconButton(
      isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
      _toggleFullScreen,
      size: 28,
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

  Widget _buildModernSettingsPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: Colors.black.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsHeader(),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: Colors.black87,
                  child: _currentSettingsPage == 'main'
                      ? _buildMainSettingsMenu()
                      : _buildSettingsSubPage(_currentSettingsPage),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildIconButton(
            Icons.arrow_back,
            () {
              if (_currentSettingsPage == 'main') {
                setState(() => _showSettings = false);
              } else {
                setState(() => _currentSettingsPage = 'main');
              }
            },
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            _getSettingsTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSettingsMenu() {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        _buildSettingsMenuItem(
          icon: Icons.high_quality_rounded,
          title: 'Quality',
          subtitle: widget.state.widget.controller.player.state.width != null
              ? '${widget.state.widget.controller.player.state.height}p'
              : 'Auto',
          onTap: () => setState(() => _currentSettingsPage = 'quality'),
        ),
        _buildSettingsMenuItem(
          icon: Icons.speed_rounded,
          title: 'Playback Speed',
          subtitle: '${playbackSpeed}x',
          onTap: () => setState(() => _currentSettingsPage = 'speed'),
        ),
        _buildSettingsMenuItem(
          icon: Icons.volume_up_rounded,
          title: 'Volume & Audio',
          subtitle: '${(volume * 100).round()}%',
          onTap: () => setState(() => _currentSettingsPage = 'audio'),
        ),
        _buildSettingsMenuItem(
          icon: Icons.subtitles_rounded,
          title: 'Subtitles',
          subtitle: widget.subtitles.isNotEmpty
              ? widget.subtitles.first.language ?? 'Default'
              : 'None available',
          onTap: () => setState(() => _currentSettingsPage = 'subtitles'),
        ),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
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
      case 'subtitles':
        return _buildSubtitleSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQualitySettings() {
    return ListView.builder(
      itemCount: widget.qualityOptions.length,
      itemBuilder: (context, index) {
        final quality = widget.qualityOptions[index];
        final isSelected = quality['quality'] == 'Auto';

        return _buildSettingsOptionItem(
          title: quality['quality']!,
          isSelected: isSelected,
          onTap: () {
            widget.changeQuality(quality['url']!);
            setState(() => _showSettings = false);
          },
        );
      },
    );
  }

  Widget _buildSpeedSettings() {
    return ListView.builder(
      itemCount: _playbackSpeeds.length,
      itemBuilder: (context, index) {
        final speed = _playbackSpeeds[index];
        final isSelected = speed == playbackSpeed;

        return _buildSettingsOptionItem(
          title: '${speed}x',
          isSelected: isSelected,
          onTap: () {
            setState(() => playbackSpeed = speed);
            widget.state.widget.controller.player.setRate(speed);
          },
        );
      },
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Volume',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    volume == 0
                        ? Icons.volume_off_rounded
                        : volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 4,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() => volume = value);
                          widget.state.widget.controller.player
                              .setVolume(value * 100);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(volume * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleSettings() {
    return ListView.builder(
      itemCount: widget.subtitles.length,
      itemBuilder: (context, index) {
        final subtitle = widget.subtitles[index];
        final isSelected = index == 0; // Assuming first is selected

        return _buildSettingsOptionItem(
          title: subtitle.language ?? 'Unknown',
          subtitle: subtitle.title,
          isSelected: isSelected,
          onTap: () async {
            await widget.state.widget.controller.player
                .setSubtitleTrack(subtitle);
            setState(() => _showSettings = false);
          },
        );
      },
    );
  }

  Widget _buildSettingsOptionItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
