import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:image/image.dart' as img;

class CustomControls extends StatefulWidget {
  final VideoState state;
  final anime_media.Media animeMedia;
  final List<SubtitleTrack> subtitles;
  final int currentEpisodeIndex;
  final List<EpisodeDataModel> episodes;

  const CustomControls({
    super.key,
    required this.state,
    required this.animeMedia,
    required this.subtitles,
    required this.currentEpisodeIndex,
    required this.episodes,
  });

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final AnimationController _fadeController;

  // State management
  AnimeWatchProgressBox? _animeWatchProgressBox;
  SettingsBox? _settingsBox;
  Timer? _hideTimer;
  Timer? _saveProgressTimer;
  List<StreamSubscription>? _playerSubscriptions;

  // UI state
  bool _isFullScreen = false;
  bool _showSettings = false;
  bool _controlsVisible = true;
  String _currentSettingsPage = 'main';

  // Player state notifiers
  final _isPlaying = ValueNotifier(false);
  final _isBuffering = ValueNotifier(false);
  final _position = ValueNotifier(Duration.zero);
  final _duration = ValueNotifier(Duration.zero);
  final _volume = ValueNotifier(1.0);
  final _playbackSpeed = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    _player = widget.state.widget.controller.player;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();

    _initializeAsyncComponents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncInitialState());
  }

  Future<void> _initializeAsyncComponents() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    _settingsBox = SettingsBox();
    await Future.wait([
      _animeWatchProgressBox!.init(),
      _settingsBox!.init(),
    ]);
    _startHideTimer();
    _startProgressSaveTimer();
    _subscribeToPlayerState();
  }

  void _syncInitialState() {
    _isFullScreen = isFullscreen(context);
    _isPlaying.value = _player.state.playing;
    _isBuffering.value = _player.state.buffering;
    _position.value = _player.state.position;
    _duration.value = _player.state.duration;
    _volume.value = _player.state.volume / 100;
    _playbackSpeed.value = _player.state.rate;
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

  void _startProgressSaveTimer() {
    int tickCount = 0;
    _saveProgressTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      tickCount++;
      if (tickCount == 5) {
        await _saveProgress(screenshot: true);
        tickCount = 0;
      }
    });
  }

  void _subscribeToPlayerState() {
    _playerSubscriptions?.forEach((sub) => sub.cancel());
    _playerSubscriptions = [
      _player.stream.playing.listen((playing) => _isPlaying.value = playing),
      _player.stream.buffering
          .listen((buffering) => _isBuffering.value = buffering),
      _player.stream.position.listen((position) => _position.value = position),
      _player.stream.duration.listen((duration) => _duration.value = duration),
      _player.stream.volume.listen((volume) => _volume.value = volume / 100),
      _player.stream.rate.listen((rate) => _playbackSpeed.value = rate),
    ];
  }

  Future<void> _saveProgress({bool screenshot = false}) async {
    if (_animeWatchProgressBox == null ||
        widget.episodes.isEmpty ||
        _duration.value.inSeconds < 10) return;

    final episode = widget.episodes[widget.currentEpisodeIndex];
    String? thumbnailBase64;

    if (screenshot) {
      final rawScreenshot = await _player.screenshot(format: 'image/png');
      if (rawScreenshot != null) {
        final image = img.decodeImage(rawScreenshot);
        if (image != null) {
          final resizedImage = img.copyResize(image, width: 320, height: 180);
          thumbnailBase64 =
              base64Encode(img.encodeJpg(resizedImage, quality: 75));
        }
      }
    }

    final completionThreshold =
        _settingsBox?.getPlayerSettings().episodeCompletionThreshold ?? 90;
    final isCompleted = _duration.value.inSeconds > 0 &&
        (_position.value.inSeconds / _duration.value.inSeconds * 100) >
            completionThreshold;

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
    _isFullScreen
        ? await widget.state.exitFullscreen()
        : await widget.state.enterFullscreen();
    if (mounted) setState(() => _isFullScreen = !_isFullScreen);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    if (mounted) {
      setState(() => _controlsVisible = true);
      _fadeController.forward();
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hideTimer?.cancel();
    _saveProgressTimer?.cancel();
    _playerSubscriptions?.forEach((sub) => sub.cancel());
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
    return GestureDetector(
      onTap: _controlsVisible ? null : _resetHideTimer,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          if (_controlsVisible)
            FadeTransition(
              opacity: _fadeController,
              child: _ControlsContainer(
                state: widget.state,
                animeMedia: widget.animeMedia,
                episodes: widget.episodes,
                currentEpisodeIndex: widget.currentEpisodeIndex,
                isPlaying: _isPlaying,
                isBuffering: _isBuffering,
                position: _position,
                duration: _duration,
                volume: _volume,
                playbackSpeed: _playbackSpeed,
                isFullScreen: _isFullScreen,
                onFullScreenToggle: _toggleFullScreen,
                onSettingsToggle: () =>
                    setState(() => _showSettings = !_showSettings),
                showSettings: _showSettings,
                currentSettingsPage: _currentSettingsPage,
                onPageChange: (page) =>
                    setState(() => _currentSettingsPage = page),
                subtitles: widget.subtitles,
                onResetHideTimer: _resetHideTimer,
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlsContainer extends StatelessWidget {
  final VideoState state;
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<bool> isBuffering;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueNotifier<double> volume;
  final ValueNotifier<double> playbackSpeed;
  final bool isFullScreen;
  final VoidCallback onFullScreenToggle;
  final VoidCallback onSettingsToggle;
  final bool showSettings;
  final String currentSettingsPage;
  final Function(String) onPageChange;
  final List<SubtitleTrack> subtitles;
  final VoidCallback onResetHideTimer;

  const _ControlsContainer({
    required this.state,
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.volume,
    required this.playbackSpeed,
    required this.isFullScreen,
    required this.onFullScreenToggle,
    required this.onSettingsToggle,
    required this.showSettings,
    required this.currentSettingsPage,
    required this.onPageChange,
    required this.subtitles,
    required this.onResetHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    final player = state.widget.controller.player;
    return GestureDetector(
      onTap: onResetHideTimer,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.4)),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  animeMedia: animeMedia,
                  episodes: episodes,
                  currentEpisodeIndex: currentEpisodeIndex,
                  onBack: () => context.pop(),
                ),
                const Spacer(),
                _PlaybackControls(
                  player: player,
                  isPlaying: isPlaying,
                  isBuffering: isBuffering,
                  position: position,
                ),
                const Spacer(),
                _BottomControls(
                  player: player,
                  position: position,
                  duration: duration,
                  volume: volume,
                  isFullScreen: isFullScreen,
                  onFullScreenToggle: onFullScreenToggle,
                  onSettingsToggle: onSettingsToggle,
                ),
              ],
            ),
          ),
          if (showSettings)
            _SettingsPanel(
              player: player,
              subtitles: subtitles,
              playbackSpeed: playbackSpeed,
              volume: volume,
              currentPage: currentSettingsPage,
              onPageChange: onPageChange,
              onClose: () => onSettingsToggle(),
              onResetHideTimer: onResetHideTimer,
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final anime_media.Media animeMedia;
  final List<EpisodeDataModel> episodes;
  final int currentEpisodeIndex;
  final VoidCallback onBack;

  const _TopBar({
    required this.animeMedia,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _IconButton(icon: Iconsax.arrow_left_1, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              animeMedia.title?.english ?? animeMedia.title?.romaji ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final Player player;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<bool> isBuffering;
  final ValueNotifier<Duration> position;

  const _PlaybackControls({
    required this.player,
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
          onTap: () =>
              player.seek(position.value - const Duration(seconds: 10)),
        ),
        const SizedBox(width: 24),
        ValueListenableBuilder<bool>(
          valueListenable: isBuffering,
          builder: (context, buffering, _) => buffering
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: isPlaying,
                  builder: (context, playing, _) => _IconButton(
                    icon: playing ? Iconsax.pause : Iconsax.play,
                    onTap: () => playing ? player.pause() : player.play(),
                    size: 32,
                  ),
                ),
        ),
        const SizedBox(width: 24),
        _IconButton(
          icon: Iconsax.forward_10_seconds,
          onTap: () =>
              player.seek(position.value + const Duration(seconds: 10)),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  final Player player;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueNotifier<double> volume;
  final bool isFullScreen;
  final VoidCallback onFullScreenToggle;
  final VoidCallback onSettingsToggle;

  const _BottomControls({
    required this.player,
    required this.position,
    required this.duration,
    required this.volume,
    required this.isFullScreen,
    required this.onFullScreenToggle,
    required this.onSettingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: duration,
            builder: (context, duration, _) => ValueListenableBuilder<Duration>(
              valueListenable: position,
              builder: (context, position, _) => _ProgressSlider(
                value: position.inSeconds.toDouble(),
                max: duration.inSeconds.toDouble(),
                onChanged: (value) =>
                    player.seek(Duration(seconds: value.toInt())),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<Duration>(
                valueListenable: position,
                builder: (context, position, _) =>
                    ValueListenableBuilder<Duration>(
                  valueListenable: duration,
                  builder: (context, duration, _) => Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
              Row(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: volume,
                    builder: (context, vol, _) => _IconButton(
                      icon:
                          vol == 0 ? Iconsax.volume_mute : Iconsax.volume_high,
                      onTap: () => player.setVolume(vol == 0 ? 100 : 0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _IconButton(
                    icon:
                        isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    onTap: onFullScreenToggle,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  _IconButton(
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

class _ProgressSlider extends StatelessWidget {
  final double value;
  final double max;
  final Function(double) onChanged;

  const _ProgressSlider(
      {required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.white.withOpacity(0.2),
        thumbColor: Colors.white,
        overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
      child: Slider(
        value: value.clamp(0.0, max),
        min: 0.0,
        max: max > 0 ? max : 1.0,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final Player player;
  final List<SubtitleTrack> subtitles;
  final ValueNotifier<double> playbackSpeed;
  final ValueNotifier<double> volume;
  final String currentPage;
  final Function(String) onPageChange;
  final VoidCallback onClose;
  final VoidCallback onResetHideTimer;

  const _SettingsPanel({
    required this.player,
    required this.subtitles,
    required this.playbackSpeed,
    required this.volume,
    required this.currentPage,
    required this.onPageChange,
    required this.onClose,
    required this.onResetHideTimer,
  });

  static const _playbackSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _SettingsHeader(
              currentPage: currentPage,
              onBack: () => onPageChange('main'),
              onClose: onClose,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: currentPage == 'main'
                    ? _MainSettingsMenu(onPageChange: onPageChange)
                    : _SubSettingsMenu(
                        player: player,
                        subtitles: subtitles,
                        playbackSpeed: playbackSpeed,
                        volume: volume,
                        currentPage: currentPage,
                        onClose: onClose,
                        onResetHideTimer: onResetHideTimer,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String currentPage;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _SettingsHeader({
    required this.currentPage,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentPage != 'main')
            _IconButton(icon: Iconsax.arrow_left_1, onTap: onBack, size: 20),
          Text(
            currentPage == 'main' ? 'Settings' : currentPage.capitalize(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          _IconButton(icon: Iconsax.close_circle, onTap: onClose, size: 20),
        ],
      ),
    );
  }
}

class _MainSettingsMenu extends StatelessWidget {
  final Function(String) onPageChange;

  const _MainSettingsMenu({required this.onPageChange});

  @override
  Widget build(BuildContext context) {
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
}

class _SubSettingsMenu extends StatelessWidget {
  final Player player;
  final List<SubtitleTrack> subtitles;
  final ValueNotifier<double> playbackSpeed;
  final ValueNotifier<double> volume;
  final String currentPage;
  final VoidCallback onClose;
  final VoidCallback onResetHideTimer;

  const _SubSettingsMenu({
    required this.player,
    required this.subtitles,
    required this.playbackSpeed,
    required this.volume,
    required this.currentPage,
    required this.onClose,
    required this.onResetHideTimer,
  });

  static const _playbackSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    switch (currentPage) {
      case 'speed':
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _playbackSpeeds
              .map((speed) => _SettingsTile(
                    title: '${speed}x',
                    isSelected: speed == playbackSpeed.value,
                    onTap: () {
                      playbackSpeed.value = speed;
                      player.setRate(speed);
                      onResetHideTimer();
                    },
                    isCompact: true,
                  ))
              .toList(),
        );
      case 'audio':
        return ValueListenableBuilder<double>(
          valueListenable: volume,
          builder: (context, vol, _) => Row(
            children: [
              _IconButton(
                icon: vol == 0 ? Iconsax.volume_mute : Iconsax.volume_high,
                onTap: () {
                  volume.value = vol == 0 ? 1.0 : 0.0;
                  player.setVolume(volume.value * 100);
                  onResetHideTimer();
                },
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: vol,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    volume.value = value;
                    player.setVolume(value * 100);
                    onResetHideTimer();
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(vol * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        );
      case 'subtitles':
        return Column(
          children: [
            _SettingsTile(
              title: 'Off',
              isSelected: player.state.subtitle == SubtitleTrack.no(),
              onTap: () async {
                await player.setSubtitleTrack(SubtitleTrack.no());
                onClose();
              },
            ),
            ...subtitles.map((subtitle) => _SettingsTile(
                  title: subtitle.language ?? 'Unknown',
                  subtitle: subtitle.title,
                  isSelected: player.state.subtitle == subtitle,
                  onTap: () async {
                    await player.setSubtitleTrack(subtitle);
                    onClose();
                  },
                )),
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
  final bool isCompact;

  const _SettingsTile({
    this.icon,
    required this.title,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
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
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: isCompact ? TextAlign.center : TextAlign.left,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ),
            if (isSelected && !isCompact)
              Icon(Icons.check,
                  color: Theme.of(context).primaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _IconButton({required this.icon, required this.onTap, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
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

extension StringExtension on String {
  String capitalize() => isNotEmpty ? this[0].toUpperCase() + substring(1) : '';
}
