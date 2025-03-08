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
  late final AnimationController _fadeController;
  late final Player _player;
  AnimeWatchProgressBox? _animeWatchProgressBox;
  Timer? _hideTimer;
  Timer? _updateTimer;
  Timer? _progressSaveTimer;
  bool _isFullScreen = false;
  bool _showSettings = false;
  String _currentSettingsPage = 'main';
  double _playbackSpeed = 1.0;

  // Player state variables
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

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
    )..forward();
    _player = widget.state.widget.controller.player;
    _isFullScreen = isFullscreen(widget.state.context);
    _initializeProgressBox();
    _startHideTimer();
    _startUpdateTimer();
    _startProgressSaveTimer();
    _syncInitialState();
  }

  void _syncInitialState() {
    setState(() {
      _isPlaying = _player.state.playing;
      _isBuffering = _player.state.buffering;
      _position = _player.state.position;
      _duration = _player.state.duration;
      _volume = _player.state.volume / 100.0;
      _playbackSpeed = _player.state.rate;
    });
  }

  Future<void> _initializeProgressBox() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    await _animeWatchProgressBox?.init();
    // if (_animeWatchProgressBox?.isInitialized == true) {
    //   await _animeWatchProgressBox?.setEntry(
    //     AnimeWatchProgressEntry(
    //       animeId: widget.animeMedia.id!,
    //       animeTitle: widget.animeMedia.title?.english ??
    //           widget.animeMedia.title?.romaji ??
    //           widget.animeMedia.title?.native ??
    //           '',
    //       animeFormat: widget.animeMedia.format ?? '',
    //       animeCover: widget.animeMedia.coverImage?.large ??
    //           widget.animeMedia.coverImage?.medium ??
    //           '',
    //       totalEpisodes: widget.episodes.length,
    //     ),
    //   );
    // }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () async {
      await _fadeController.reverse();
      if (mounted) setState(() {});
    });
  }

  void _resetHideTimer() {
    if (mounted) {
      _fadeController.forward();
      _startHideTimer();
    }
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _isPlaying = _player.state.playing;
          _isBuffering = _player.state.buffering;
          _position = _player.state.position;
          _duration = _player.state.duration;
          _volume = _player.state.volume / 100.0;
          _playbackSpeed = _player.state.rate;
        });
      }
    });
  }

  void _startProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _isPlaying) _saveProgress(screenshot: true);
    });
  }

  Future<void> _saveProgress({bool screenshot = false}) async {
    if (_animeWatchProgressBox == null || widget.episodes.isEmpty) return;
    final episode = widget.episodes[widget.currentEpisodeIndex];
    final thumbnail =
        screenshot ? await _player.screenshot(format: 'image/png') : null;
    await _animeWatchProgressBox?.updateEpisodeProgress(
      animeMedia: widget.animeMedia,
      episodeNumber: episode.number!,
      episodeTitle: episode.title ?? 'Untitled',
      episodeThumbnail: thumbnail != null ? base64Encode(thumbnail) : null,
      progressInSeconds: _position.inSeconds,
      durationInSeconds: _duration.inSeconds,
    );
  }

  void _toggleFullScreen() {
    final isFull = isFullscreen(widget.state.context);
    if (isFull) {
      widget.state.exitFullscreen();
    } else {
      widget.state.enterFullscreen();
    }
    if (mounted) setState(() => _isFullScreen = !isFull);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hideTimer?.cancel();
    _updateTimer?.cancel();
    _progressSaveTimer?.cancel();
    _saveProgress(screenshot: true);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetHideTimer,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          _buildGradientOverlay(),
          _ControlsLayer(
            state: widget.state,
            fadeController: _fadeController,
            onFullScreenToggle: _toggleFullScreen,
            isFullScreen: _isFullScreen,
            onSettingsToggle: (show) => setState(() => _showSettings = show),
            animeMedia: widget.animeMedia,
            episodes: widget.episodes,
            currentEpisodeIndex: widget.currentEpisodeIndex,
            isPlaying: _isPlaying,
            isBuffering: _isBuffering,
            position: _position,
            duration: _duration,
            volume: _volume,
          ),
          if (_showSettings)
            _SettingsPanel(
              state: widget.state,
              subtitles: widget.subtitles,
              qualityOptions: widget.qualityOptions,
              changeQuality: widget.changeQuality,
              playbackSpeed: _playbackSpeed,
              onSpeedChange: (speed) {
                setState(() => _playbackSpeed = speed);
                _player.setRate(speed);
              },
              volume: _volume,
              onVolumeChange: (vol) {
                setState(() => _volume = vol);
                _player.setVolume(vol * 100);
              },
              onClose: () => setState(() => _showSettings = false),
              currentPage: _currentSettingsPage,
              onPageChange: (page) =>
                  setState(() => _currentSettingsPage = page),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return FadeTransition(
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
    );
  }
}

// Controls Layer
class _ControlsLayer extends StatelessWidget {
  final VideoState state;
  final AnimationController fadeController;
  final VoidCallback onFullScreenToggle;
  final bool isFullScreen;
  final Function(bool) onSettingsToggle;
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;

  const _ControlsLayer({
    required this.state,
    required this.fadeController,
    required this.onFullScreenToggle,
    required this.isFullScreen,
    required this.onSettingsToggle,
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeController,
      builder: (context, child) {
        if (fadeController.value == 0) return const SizedBox.shrink();
        return SafeArea(
          child: Opacity(
            opacity: fadeController.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopBar(
                  animeMedia: animeMedia,
                  episodes: episodes,
                  currentEpisodeIndex: currentEpisodeIndex,
                  onSettingsToggle: () => onSettingsToggle(true),
                ),
                const Spacer(),
                _CenterControls(
                  state: state,
                  isPlaying: isPlaying,
                  isBuffering: isBuffering,
                  position: position,
                ),
                const Spacer(),
                _BottomControls(
                  state: state,
                  onFullScreenToggle: onFullScreenToggle,
                  isFullScreen: isFullScreen,
                  position: position,
                  duration: duration,
                  volume: volume,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Top Bar
class _TopBar extends StatelessWidget {
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final VoidCallback onSettingsToggle;

  const _TopBar({
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.onSettingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconButton(
            icon: Iconsax.arrow_left_1,
            onPressed: () async {
              await toggleFullscreen(context);
              if (!context.mounted) return;
              context.pop();
            },
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animeMedia.title?.english ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (episodes.isNotEmpty)
                  Text(
                    'Episode ${episodes[currentEpisodeIndex].number}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          _IconButton(
            icon: Iconsax.setting_2,
            onPressed: onSettingsToggle,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// Center Controls
class _CenterControls extends StatelessWidget {
  final VideoState state;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;

  const _CenterControls({
    required this.state,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconButton(
          icon: Iconsax.backward_10_seconds,
          onPressed: () => state.widget.controller.player
              .seek(position - const Duration(seconds: 10)),
          size: 36,
        ),
        const SizedBox(width: 32),
        isBuffering
            ? const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : _PlayPauseButton(state: state, isPlaying: isPlaying),
        const SizedBox(width: 32),
        _IconButton(
          icon: Iconsax.forward_10_seconds,
          onPressed: () => state.widget.controller.player
              .seek(position + const Duration(seconds: 10)),
          size: 36,
        ),
      ],
    );
  }
}

// Play/Pause Button
class _PlayPauseButton extends StatelessWidget {
  final VideoState state;
  final bool isPlaying;

  const _PlayPauseButton({required this.state, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: _IconButton(
        icon: isPlaying ? Iconsax.pause : Iconsax.play,
        onPressed: () => isPlaying
            ? state.widget.controller.player.pause()
            : state.widget.controller.player.play(),
        size: 36,
      ),
    );
  }
}

// Bottom Controls
class _BottomControls extends StatefulWidget {
  final VideoState state;
  final VoidCallback onFullScreenToggle;
  final bool isFullScreen;
  final Duration position;
  final Duration duration;
  final double volume;

  const _BottomControls({
    required this.state,
    required this.onFullScreenToggle,
    required this.isFullScreen,
    required this.position,
    required this.duration,
    required this.volume,
  });

  @override
  State<_BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<_BottomControls> {
  Duration? _dragPosition;

  @override
  Widget build(BuildContext context) {
    final maxDuration = widget.duration.inSeconds > 0
        ? widget.duration.inSeconds.toDouble()
        : 1.0;
    final sliderValue = (_dragPosition?.inSeconds.toDouble() ??
            widget.position.inSeconds.toDouble())
        .clamp(0.0, maxDuration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: Theme.of(context).primaryColor,
              overlayColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: sliderValue,
              min: 0.0,
              max: maxDuration,
              onChanged: (value) => setState(
                  () => _dragPosition = Duration(seconds: value.toInt())),
              onChangeEnd: (value) async {
                await widget.state.widget.controller.player
                    .seek(Duration(seconds: value.toInt()));
                setState(() => _dragPosition = null);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  '${_formatDuration(widget.position)} / ${_formatDuration(widget.duration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                _VolumeControl(state: widget.state, volume: widget.volume),
                const SizedBox(width: 16),
                _IconButton(
                  icon: widget.isFullScreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onPressed: widget.onFullScreenToggle,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Volume Control
class _VolumeControl extends StatelessWidget {
  final VideoState state;
  final double volume;

  const _VolumeControl({required this.state, required this.volume});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          volume == 0
              ? Iconsax.volume_mute
              : volume < 0.5
                  ? Iconsax.volume_low
                  : Iconsax.volume_high,
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
              onChanged: (value) =>
                  state.widget.controller.player.setVolume(value * 100),
            ),
          ),
        ),
      ],
    );
  }
}

// Icon Button
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

// Settings Panel
class _SettingsPanel extends StatelessWidget {
  final VideoState state;
  final List<SubtitleTrack> subtitles;
  final List<Map<String, String>> qualityOptions;
  final Function(String) changeQuality;
  final double playbackSpeed;
  final Function(double) onSpeedChange;
  final double volume;
  final Function(double) onVolumeChange;
  final VoidCallback onClose;
  final String currentPage;
  final Function(String) onPageChange;

  const _SettingsPanel({
    required this.state,
    required this.subtitles,
    required this.qualityOptions,
    required this.changeQuality,
    required this.playbackSpeed,
    required this.onSpeedChange,
    required this.volume,
    required this.onVolumeChange,
    required this.onClose,
    required this.currentPage,
    required this.onPageChange,
  });

  final List<double> _playbackSpeeds = const [
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: Colors.black.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsHeader(context),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: Colors.black87,
                  child: currentPage == 'main'
                      ? _buildMainSettingsMenu(context)
                      : _buildSettingsSubPage(context, currentPage),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconButton(
            icon: Iconsax.arrow_left_1,
            onPressed: () {
              if (currentPage == 'main') {
                onClose();
              } else {
                onPageChange('main');
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

  String _getSettingsTitle() {
    switch (currentPage) {
      case 'quality':
        return 'Video Quality';
      case 'speed':
        return 'Playback Speed';
      case 'audio':
        return 'Audio Settings';
      case 'subtitles':
        return 'Subtitles';
      default:
        return 'Settings';
    }
  }

  Widget _buildMainSettingsMenu(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.high_quality_outlined,
          title: 'Quality',
          subtitle: state.widget.controller.player.state.width != null
              ? '${state.widget.controller.player.state.height}p'
              : 'Auto',
          onTap: () => onPageChange('quality'),
        ),
        _buildSettingsMenuItem(
          context: context,
          icon: Iconsax.speedometer,
          title: 'Playback Speed',
          subtitle: '${playbackSpeed}x',
          onTap: () => onPageChange('speed'),
        ),
        _buildSettingsMenuItem(
          context: context,
          icon: Iconsax.volume_high,
          title: 'Volume & Audio',
          subtitle: '${(volume * 100).round()}%',
          onTap: () => onPageChange('audio'),
        ),
        _buildSettingsMenuItem(
          context: context,
          icon: Iconsax.subtitle,
          title: 'Subtitles',
          subtitle: subtitles.isNotEmpty
              ? subtitles.first.language ?? 'Default'
              : 'None available',
          onTap: () => onPageChange('subtitles'),
        ),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required BuildContext context,
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

  Widget _buildSettingsSubPage(BuildContext context, String page) {
    switch (page) {
      case 'quality':
        return _buildQualitySettings(context);
      case 'speed':
        return _buildSpeedSettings(context);
      case 'audio':
        return _buildAudioSettings(context);
      case 'subtitles':
        return _buildSubtitleSettings(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQualitySettings(BuildContext context) {
    return ListView.builder(
      itemCount: qualityOptions.length,
      itemBuilder: (context, index) {
        final quality = qualityOptions[index];
        final isSelected =
            quality['quality'] == 'Auto'; // Adjust logic as needed
        return _buildSettingsOptionItem(
          context: context,
          title: quality['quality']!,
          isSelected: isSelected,
          onTap: () {
            changeQuality(quality['url']!);
            onClose();
          },
        );
      },
    );
  }

  Widget _buildSpeedSettings(BuildContext context) {
    return ListView.builder(
      itemCount: _playbackSpeeds.length,
      itemBuilder: (context, index) {
        final speed = _playbackSpeeds[index];
        final isSelected = speed == playbackSpeed;
        return _buildSettingsOptionItem(
          context: context,
          title: '${speed}x',
          isSelected: isSelected,
          onTap: () {
            onSpeedChange(speed);
          },
        );
      },
    );
  }

  Widget _buildAudioSettings(BuildContext context) {
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
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: onVolumeChange,
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

  Widget _buildSubtitleSettings(BuildContext context) {
    return ListView.builder(
      itemCount: subtitles.length,
      itemBuilder: (context, index) {
        final subtitle = subtitles[index];
        final isSelected = index == 0; // Adjust selection logic as needed
        return _buildSettingsOptionItem(
          context: context,
          title: subtitle.language ?? 'Unknown',
          subtitle: subtitle.title,
          isSelected: isSelected,
          onTap: () async {
            await state.widget.controller.player.setSubtitleTrack(subtitle);
            onClose();
          },
        );
      },
    );
  }

  Widget _buildSettingsOptionItem({
    required BuildContext context,
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
