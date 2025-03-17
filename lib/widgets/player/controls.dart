import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart' as anime_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:image/image.dart' as img;
import 'package:shonenx/data/hive/boxes/settings_box.dart';

class CustomControls extends StatefulWidget {
  final VideoState state;
  final anime_media.Media animeMedia;
  final List<SubtitleTrack> subtitles;
  final List<Map<String, dynamic>> qualityOptions; // Updated to String for consistency
  final Function(String) changeQuality;
  final int currentEpisodeIndex;
  final List<EpisodeDataModel> episodes;

  const CustomControls({
    super.key,
    required this.subtitles,
    required this.state,
    required this.animeMedia,
    required this.qualityOptions,
    required this.changeQuality,
    required this.currentEpisodeIndex,
    required this.episodes,
  });

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Player _player;
  AnimeWatchProgressBox? _animeWatchProgressBox;
  SettingsBox? _settingsBox;
  Timer? _hideTimer;
  Timer? _saveProgressTimer;
  StreamSubscription? _playerStateSubscription;
  bool _isFullScreen = false;
  bool _showSettings = false;
  bool _controlsVisible = true;
  String _currentSettingsPage = 'main';

  final _isPlaying = ValueNotifier(false);
  final _isBuffering = ValueNotifier(false);
  final _position = ValueNotifier(Duration.zero);
  final _duration = ValueNotifier(Duration.zero);
  final _volume = ValueNotifier(1.0);
  final _playbackSpeed = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this)..forward();
    _player = widget.state.widget.controller.player;
    _isFullScreen = isFullscreen(widget.state.context);
    _initializeBoxes();
    _startHideTimer();
    _startProgressSaveTimer();
    _subscribeToPlayerState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncInitialState());
  }

  void _syncInitialState() {
    _isPlaying.value = _player.state.playing;
    _isBuffering.value = _player.state.buffering;
    _position.value = _player.state.position;
    _duration.value = _player.state.duration;
    _volume.value = _player.state.volume / 100.0;
    _playbackSpeed.value = _player.state.rate;
  }

  Future<void> _initializeBoxes() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    await _animeWatchProgressBox?.init();
  }

  void _startProgressSaveTimer() {
    int tickCount = 0;
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      tickCount++;
      if (tickCount == 5) {
        await _saveProgress(screenshot: true);
        tickCount = 0;
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showSettings) {
        setState(() => _controlsVisible = false);
        _fadeController.reverse();
      }
    });
  }

  void _resetHideTimer() {
    if (mounted) {
      setState(() => _controlsVisible = true);
      _fadeController.forward();
      _startHideTimer();
    }
  }

  void _subscribeToPlayerState() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _player.stream.playing.listen((playing) => _isPlaying.value = playing);
    _player.stream.buffering.listen((buffering) => _isBuffering.value = buffering);
    _player.stream.position.listen((position) => _position.value = position);
    _player.stream.duration.listen((duration) => _duration.value = duration);
    _player.stream.volume.listen((volume) => _volume.value = volume / 100.0);
    _player.stream.rate.listen((rate) => _playbackSpeed.value = rate);
  }

  Future<void> _saveProgress({bool screenshot = false}) async {
    if (_animeWatchProgressBox == null || widget.episodes.isEmpty || _duration.value.inSeconds < 10) {
      return;
    }

    final episode = widget.episodes[widget.currentEpisodeIndex];
    String? thumbnailBase64;

    if (screenshot) {
      final rawScreenshot = await _player.screenshot(format: 'image/png');
      if (rawScreenshot != null) {
        final image = img.decodeImage(rawScreenshot);
        if (image != null) {
          final resizedImage = img.copyResize(image, width: 320, height: 180);
          final compressedImage = img.encodeJpg(resizedImage, quality: 75);
          thumbnailBase64 = base64Encode(compressedImage);
        }
      }
    }

    final isCompleted = _duration.value.inSeconds > 0 &&
        ((_position.value.inSeconds / _duration.value.inSeconds) * 100) >
            (_settingsBox?.getPlayerSettings().episodeCompletionThreshold ?? 90);

    await _animeWatchProgressBox?.updateEpisodeProgress(
      animeMedia: widget.animeMedia,
      episodeNumber: episode.number!,
      episodeTitle: episode.title ?? 'Untitled',
      episodeThumbnail: thumbnailBase64,
      progressInSeconds: _position.value.inSeconds,
      durationInSeconds: _duration.value.inSeconds,
      isCompleted: isCompleted,
    );
  }

  void _toggleFullScreen() async {
    final isFull = isFullscreen(widget.state.context);
    if (isFull) {
      await widget.state.exitFullscreen();
    } else {
      await widget.state.enterFullscreen();
    }
    if (mounted) setState(() => _isFullScreen = !isFull);
    _resetHideTimer();
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
    _resetHideTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hideTimer?.cancel();
    _saveProgressTimer?.cancel();
    _playerStateSubscription?.cancel();
    _isPlaying.dispose();
    _isBuffering.dispose();
    _position.dispose();
    _duration.dispose();
    _volume.dispose();
    _playbackSpeed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _controlsVisible ? null : _resetHideTimer(),
          behavior: HitTestBehavior.opaque,
        ),
        if (_controlsVisible)
          FadeTransition(
            opacity: _fadeController,
            child: GestureDetector(
              onTap: _resetHideTimer,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Container(color: Colors.black.withOpacity(0.3)), // Softer overlay
                  _ControlOverlay(
                    state: widget.state,
                    animeMedia: widget.animeMedia,
                    episodes: widget.episodes,
                    currentEpisodeIndex: widget.currentEpisodeIndex,
                    isPlaying: _isPlaying,
                    isBuffering: _isBuffering,
                    position: _position,
                    duration: _duration,
                    volume: _volume,
                    isFullScreen: _isFullScreen,
                    onFullScreenToggle: _toggleFullScreen,
                    onSettingsToggle: _toggleSettings,
                  ),
                  if (_showSettings)
                    _SettingsDrawer(
                      state: widget.state,
                      subtitles: widget.subtitles,
                      qualityOptions: widget.qualityOptions,
                      changeQuality: widget.changeQuality,
                      playbackSpeed: _playbackSpeed,
                      onSpeedChange: (speed) {
                        _playbackSpeed.value = speed;
                        _player.setRate(speed);
                        _resetHideTimer();
                      },
                      volume: _volume,
                      onVolumeChange: (vol) {
                        _volume.value = vol;
                        _player.setVolume(vol * 100);
                        _resetHideTimer();
                      },
                      onClose: () => setState(() => _showSettings = false),
                      currentPage: _currentSettingsPage,
                      onPageChange: (page) => setState(() => _currentSettingsPage = page),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ControlOverlay extends StatelessWidget {
  final VideoState state;
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<bool> isBuffering;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueNotifier<double> volume;
  final bool isFullScreen;
  final VoidCallback onFullScreenToggle;
  final VoidCallback onSettingsToggle;

  const _ControlOverlay({
    required this.state,
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.volume,
    required this.isFullScreen,
    required this.onFullScreenToggle,
    required this.onSettingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Increased padding for breathing room
            child: Row(
              children: [
                _GlowButton(
                  icon: Iconsax.arrow_left_1,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    animeMedia.title?.english ?? animeMedia.title?.romaji ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Slightly larger for prominence
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (episodes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Ep ${episodes[currentEpisodeIndex].number}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlowButton(
                icon: Iconsax.backward_10_seconds,
                onTap: () => state.widget.controller.player.seek(position.value - const Duration(seconds: 10)),
              ),
              const SizedBox(width: 24),
              ValueListenableBuilder<bool>(
                valueListenable: isBuffering,
                builder: (context, buffering, _) => buffering
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : ValueListenableBuilder<bool>(
                        valueListenable: isPlaying,
                        builder: (context, playing, _) => _GlowButton(
                          icon: playing ? Iconsax.pause : Iconsax.play,
                          onTap: () => playing ? state.widget.controller.player.pause() : state.widget.controller.player.play(),
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 24),
              _GlowButton(
                icon: Iconsax.forward_10_seconds,
                onTap: () => state.widget.controller.player.seek(position.value + const Duration(seconds: 10)),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: duration,
                  builder: (context, duration, _) {
                    final maxDuration = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
                    return ValueListenableBuilder<Duration>(
                      valueListenable: position,
                      builder: (context, position, _) => _ProgressSlider(
                        value: position.inSeconds.toDouble(),
                        max: maxDuration,
                        onChanged: (value) => state.widget.controller.player.seek(Duration(seconds: value.toInt())),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<Duration>(
                      valueListenable: position,
                      builder: (context, position, _) => ValueListenableBuilder<Duration>(
                        valueListenable: duration,
                        builder: (context, duration, _) => Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _GlowButton(
                          icon: volume.value == 0 ? Iconsax.volume_mute : Iconsax.volume_high,
                          onTap: () => state.widget.controller.player.setVolume(volume.value == 0 ? 100 : 0),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        _GlowButton(
                          icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          onTap: onFullScreenToggle,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        _GlowButton(
                          icon: Iconsax.setting_2,
                          onTap: onSettingsToggle,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
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

class _GlowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GlowButton({required this.icon, required this.onTap, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8), // Reduced padding for compactness
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6), // Subtle background
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1), // Subtle glow
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _ProgressSlider extends StatefulWidget {
  final double value;
  final double max;
  final Function(double) onChanged;

  const _ProgressSlider({required this.value, required this.max, required this.onChanged});

  @override
  State<_ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<_ProgressSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final currentValue = _dragValue ?? widget.value;
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2, // Thinner track
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.white.withOpacity(0.2),
        thumbColor: Colors.white,
        overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
      child: Slider(
        value: currentValue.clamp(0.0, widget.max),
        min: 0.0,
        max: widget.max,
        onChanged: (value) => setState(() => _dragValue = value),
        onChangeEnd: (value) {
          widget.onChanged(value);
          setState(() => _dragValue = null);
        },
      ),
    );
  }
}

class _SettingsDrawer extends StatelessWidget {
  final VideoState state;
  final List<SubtitleTrack> subtitles;
  final List<Map<String, dynamic>> qualityOptions; // Updated to String
  final Function(String) changeQuality;
  final ValueNotifier<double> playbackSpeed;
  final Function(double) onSpeedChange;
  final ValueNotifier<double> volume;
  final Function(double) onVolumeChange;
  final VoidCallback onClose;
  final String currentPage;
  final Function(String) onPageChange;

  const _SettingsDrawer({
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

  static const _playbackSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.45, // Slightly shorter
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentPage != 'main')
                    _GlowButton(
                      icon: Iconsax.arrow_left_1,
                      onTap: () => onPageChange('main'),
                      size: 20,
                    ),
                  Text(
                    currentPage == 'main' ? 'Settings' : currentPage.capitalize(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  _GlowButton(icon: Iconsax.close_circle, onTap: onClose, size: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: currentPage == 'main' ? _buildMainMenu(context) : _buildSubMenu(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsTile(
          icon: Icons.high_quality,
          title: 'Quality',
          onTap: () => onPageChange('quality'),
        ),
        _SettingsTile(
          icon: Iconsax.speedometer,
          title: 'Playback Speed',
          onTap: () => onPageChange('speed'),
        ),
        _SettingsTile(
          icon: Iconsax.volume_high,
          title: 'Volume',
          onTap: () => onPageChange('audio'),
        ),
        _SettingsTile(
          icon: Iconsax.subtitle,
          title: 'Subtitles',
          onTap: () => onPageChange('subtitles'),
        ),
      ],
    );
  }

  Widget _buildSubMenu(BuildContext context) {
    switch (currentPage) {
      case 'quality':
        return Column(
          children: qualityOptions.map((quality) {
            final isDub = quality['isDub'] == 'true';
            final isSelected = quality['url'] == state.widget.controller.player.state.playlist.medias.first.uri;
            return _SettingsTile(
              title: '${quality['quality']}${isDub ? ' (Dub)' : ''}',
              isSelected: isSelected,
              onTap: () {
                changeQuality(quality['url']!);
                onClose();
              },
              accentColor: isDub ? Colors.greenAccent : Colors.blueAccent,
            );
          }).toList(),
        );
      case 'speed':
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _playbackSpeeds.map((speed) {
            final isSelected = speed == playbackSpeed.value;
            return _SettingsTile(
              title: '${speed}x',
              isSelected: isSelected,
              onTap: () => onSpeedChange(speed),
              isCompact: true,
            );
          }).toList(),
        );
      case 'audio':
        return ValueListenableBuilder<double>(
          valueListenable: volume,
          builder: (context, vol, _) => Row(
            children: [
              _GlowButton(
                icon: vol == 0 ? Iconsax.volume_mute : Iconsax.volume_high,
                onTap: () => onVolumeChange(vol == 0 ? 1.0 : 0.0),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: vol,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onVolumeChange,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(vol * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      case 'subtitles':
        return Column(
          children: [
            _SettingsTile(
              title: 'Off',
              isSelected: state.widget.controller.player.state.subtitle == SubtitleTrack.no(),
              onTap: () async {
                await state.widget.controller.player.setSubtitleTrack(SubtitleTrack.no());
                onClose();
              },
            ),
            ...subtitles.map((subtitle) {
              final isSelected = state.widget.controller.player.state.subtitle == subtitle;
              return _SettingsTile(
                title: subtitle.language ?? 'Unknown',
                subtitle: subtitle.title,
                isSelected: isSelected,
                onTap: () async {
                  await state.widget.controller.player.setSubtitleTrack(subtitle);
                  onClose();
                },
              );
            }),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final bool isCompact;

  const _SettingsTile({
    this.icon,
    required this.title,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
    this.accentColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? 80 : double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (icon != null) ...[
              Icon(icon, color: accentColor ?? Colors.white70, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor ?? Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: isCompact ? TextAlign.center : TextAlign.left,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (isSelected && !isCompact)
              Icon(Icons.check, color: Theme.of(context).primaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}

// Placeholder for isFullscreen function (assuming it exists elsewhere)
bool isFullscreen(BuildContext context) {
  return MediaQuery.of(context).orientation == Orientation.landscape;
}