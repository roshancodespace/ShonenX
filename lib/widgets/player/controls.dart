import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:image/image.dart' as img;
import 'package:shonenx/data/hive/models/subtitle_style_offline_model.dart';
import 'package:shonenx/widgets/player/controls_ui.dart';

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

  // Player state notifiers
  final _isPlaying = ValueNotifier(false);
  final _isBuffering = ValueNotifier(false);
  final _position = ValueNotifier(Duration.zero);
  final _duration = ValueNotifier(Duration.zero);
  final _volume = ValueNotifier(1.0);
  final _playbackSpeed = ValueNotifier(1.0);
  final _subtitleStyle = ValueNotifier(SubtitleStyle()); // Add this

  @override
  void initState() {
    super.initState();
    _player = widget.state.widget.controller.player;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _initializeAsyncComponents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncInitialState());
  }

  // In _initializeAsyncComponents
  Future<void> _initializeAsyncComponents() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    _settingsBox = SettingsBox();
    await Future.wait([
      _animeWatchProgressBox!.init(),
      _settingsBox!.init(),
    ]);

    final playerSettings = _settingsBox!.getPlayerSettings();
    _subtitleStyle.value = playerSettings.toSubtitleStyle();

    _startHideTimer();
    _startProgressSaveTimer();
    _subscribeToPlayerState();
  }

// In _subscribeToPlayerState
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

    _subtitleStyle.addListener(() {
      final currentSettings = _settingsBox!.getPlayerSettings();
      _settingsBox!.updatePlayerSettings(
        currentSettings.copyWith(
          subtitleFontSize: _subtitleStyle.value.fontSize,
          subtitleTextColor: _subtitleStyle.value.textColor.value,
          subtitleBackgroundOpacity: _subtitleStyle.value.backgroundOpacity,
          subtitleHasShadow: _subtitleStyle.value.hasShadow,
        ),
      );
    });
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

  Future<void> _saveProgress({bool screenshot = false}) async {
    if (_animeWatchProgressBox == null ||
        widget.episodes.isEmpty ||
        _duration.value.inSeconds < 10) {
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
    _subtitleStyle.dispose(); // Dispose the new notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControlsUI(
      fadeController: _fadeController,
      controlsVisible: _controlsVisible,
      showSettings: _showSettings,
      player: _player,
      isFullScreen: _isFullScreen,
      isPlaying: _isPlaying,
      isBuffering: _isBuffering,
      position: _position,
      duration: _duration,
      volume: _volume,
      playbackSpeed: _playbackSpeed,
      animeMedia: widget.animeMedia,
      episodes: widget.episodes,
      currentEpisodeIndex: widget.currentEpisodeIndex,
      subtitles: widget.subtitles,
      onResetHideTimer: _resetHideTimer,
      onToggleFullScreen: _toggleFullScreen,
      onToggleSettings: () => setState(() => _showSettings = !_showSettings),
      subtitleStyle: _subtitleStyle, // Pass the new notifier
    );
  }
}

// Placeholder for isFullscreen function (implement as needed)
bool isFullscreen(BuildContext context) {
  return MediaQuery.of(context).orientation == Orientation.landscape;
}
