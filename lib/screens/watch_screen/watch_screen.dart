import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:image/image.dart' as img;
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/screens/watch_screen/controls.dart';
import 'package:shonenx/screens/watch_screen/episodes_panel.dart';
import 'package:window_manager/window_manager.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String animeId;
  final anilist_media.Media animeMedia;
  final String animeName;
  final int? episode;
  final Duration startAt;

  const WatchScreen({
    required this.animeId,
    required this.animeMedia,
    required this.animeName,
    this.startAt = Duration.zero,
    this.episode = 1,
    super.key,
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with TickerProviderStateMixin {
  static const _progressSaveInterval = Duration(seconds: 10);
  static const _thumbnailWidth = 320;
  static const _thumbnailHeight = 180;
  static const _thumbnailQuality = 75;

  final AnimeWatchProgressBox _animeWatchProgressBox = AnimeWatchProgressBox();
  Timer? _saveProgressTimer;
  late AnimationController _animationController;
  late final VideoController _controller;
  // bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _setupOrientation();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: ref.read(watchProvider).isExpanded ? 1.0 : 0.0,
    );
    _controller = ref.read(controllerProvider);
    _initializeAsync().then((_) => _performInitialFetch(ref));
  }

  Future<void> _setupOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeAsync() async {
    await _animeWatchProgressBox.init();
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _saveProgressTimer =
        Timer.periodic(_progressSaveInterval, (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
    final watchState = ref.read(watchProvider);
    final playerState = ref.read(playerStateProvider);
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;

    if (!_shouldSaveProgress(watchState, playerState)) return;
    log("Saving progress");

    final episodeIdx = watchState.selectedEpisodeIdx!;
    final episode = watchState.episodes[episodeIdx];
    final progress = playerState.position;
    final duration = playerState.duration;

    final thumbnailBase64 = await _generateThumbnail();
    final isCompleted = progress.inSeconds >=
        (duration.inSeconds * playerSettings.episodeCompletionThreshold);

    await _animeWatchProgressBox.updateEpisodeProgress(
      animeMedia: widget.animeMedia,
      episodeNumber: episode.number!,
      episodeTitle: episode.title ?? 'Untitled',
      episodeThumbnail: thumbnailBase64,
      progressInSeconds: progress.inSeconds,
      durationInSeconds: duration.inSeconds,
      isCompleted: isCompleted,
    );
  }

  bool _shouldSaveProgress(WatchState watchState, PlayerState playerState) {
    return watchState.selectedEpisodeIdx != null &&
        playerState.duration.inSeconds >= 10 &&
        playerState.position.inSeconds >= 10 &&
        playerState.position <= playerState.duration;
  }

  Future<String?> _generateThumbnail() async {
    final rawScreenshot =
        await ref.read(playerProvider).screenshot(format: 'image/jpg');
    if (rawScreenshot == null) return null;

    return compute(_processThumbnail, rawScreenshot);
  }

  static String? _processThumbnail(Uint8List rawScreenshot) {
    final image = img.decodeImage(rawScreenshot);
    if (image == null) return null;

    final resizedImage = img.copyResize(
      image,
      width: _thumbnailWidth,
      height: _thumbnailHeight,
    );
    return base64Encode(
        img.encodeJpg(resizedImage, quality: _thumbnailQuality));
  }

  Future<void> _performInitialFetch(WidgetRef ref) async {
    final notifier = ref.read(watchProvider.notifier);
    await notifier.fetchEpisodes(animeId: widget.animeId);
    await notifier.fetchStreamData(
      withPlay: false,
      episodeIdx: (widget.episode ?? 1) - 1,
    );
  }

  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _animationController.dispose();
    ref.read(playerProvider).dispose();
    _resetOrientationAndUI();
    super.dispose();
  }

  Future<void> _resetOrientationAndUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await windowManager.setFullScreen(false);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Video(
                  controller: _controller,
                  subtitleViewConfiguration:
                      const SubtitleViewConfiguration(visible: false),
                  filterQuality:
                      kDebugMode ? FilterQuality.low : FilterQuality.none,
                  fit: BoxFit.contain,
                  controls: (state) => CustomControls(
                    state: state,
                    panelAnimationController: _animationController,
                  ),
                  // onEnterFullscreen: _enterFullscreen,
                  // onExitFullscreen: _exitFullscreen,
                ),
              ),
              _buildEpisodesPanel(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  // Future<void> _enterFullscreen() async {
  //   try {
  //     setState(() => _isFullscreen = true);

  //     // Hide panel if it's expanded
  //     if (ref.read(watchProvider).isExpanded) {
  //       await ref.read(watchProvider.notifier).togglePanel(_animationController);
  //     }

  //     await Future.wait([
  //       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
  //       windowManager.setFullScreen(true),
  //       _setupOrientation(),
  //     ]);
  //   } catch (e) {
  //     debugPrint('Error entering fullscreen: $e');
  //     setState(() => _isFullscreen = false);
  //   }
  // }

  // Future<void> _exitFullscreen() async {
  //   try {
  //     // Show panel if it was previously hidden
  //     if (!ref.read(watchProvider).isExpanded) {
  //       await ref.read(watchProvider.notifier).togglePanel(_animationController);
  //     }

  //     await Future.wait([
  //       SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
  //       windowManager.setFullScreen(false),
  //       _setupOrientation(),
  //     ]);

  //     setState(() => _isFullscreen = false);
  //   } catch (e) {
  //     debugPrint('Error exiting fullscreen: $e');
  //     setState(() => _isFullscreen = true);
  //   }
  // }

  Widget _buildEpisodesPanel(BuildContext context, BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
        axis: Axis.horizontal,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.35,
          height: constraints.maxHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: EpisodesPanel(animeId: widget.animeId),
          ),
        ),
      ),
    );
  }
}
