import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:image/image.dart' as img;
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/helpers/ui.dart';
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
    if (!mounted) return;
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
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer.periodic(_progressSaveInterval, (_) {
      if (mounted) _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    final watchState = ref.read(watchProvider);
    final playerState = ref.read(playerStateProvider);
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;

    if (!_shouldSaveProgress(watchState, playerState)) {
      log("Skipping progress save - conditions not met");
      return;
    }

    try {
      final episodeIdx = watchState.selectedEpisodeIdx!;
      final episode = watchState.episodes[episodeIdx];
      final progress = playerState.position;
      final duration = playerState.duration;

      if (episode.number == null) {
        log("Episode number is null, cannot save progress");
        return;
      }

      final thumbnailBase64 = await _generateThumbnail();
      final isCompleted = progress.inSeconds >=
          (duration.inSeconds * playerSettings.episodeCompletionThreshold);

      log("Saving progress for episode ${episode.number} - Progress: ${progress.inSeconds}s / ${duration.inSeconds}s");

      await _animeWatchProgressBox.updateEpisodeProgress(
        animeMedia: widget.animeMedia,
        episodeNumber: episode.number!,
        episodeTitle: episode.title ?? 'Episode ${episode.number}',
        episodeThumbnail: thumbnailBase64,
        progressInSeconds: progress.inSeconds,
        durationInSeconds: duration.inSeconds,
        isCompleted: isCompleted,
      );

      log("Progress saved successfully");
    } catch (e) {
      log("Error saving progress: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  bool _shouldSaveProgress(WatchState watchState, PlayerState playerState) {
    final hasValidEpisode = watchState.selectedEpisodeIdx != null &&
        watchState.episodes.isNotEmpty &&
        watchState.selectedEpisodeIdx! < watchState.episodes.length;
    final hasValidDuration = playerState.duration.inSeconds >= 10;
    final hasValidPosition = playerState.position.inSeconds >= 10;
    final isPositionValid = playerState.position <= playerState.duration;

    return hasValidEpisode &&
        hasValidDuration &&
        hasValidPosition &&
        isPositionValid;
  }

  Future<String?> _generateThumbnail() async {
    try {
      final rawScreenshot =
          await ref.read(playerProvider).screenshot(format: 'image/jpg');
      if (rawScreenshot == null) {
        log("Failed to capture screenshot");
        return null;
      }
      return await compute(_processThumbnail, rawScreenshot);
    } catch (e) {
      log("Error generating thumbnail: $e");
      return null;
    }
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
    if (mounted) {
      final notifier = ref.read(watchProvider.notifier);
      // Show loading dialog for initial fetch
      await Future.wait([
        notifier.fetchEpisodes(animeId: widget.animeId),
        notifier.fetchStreamData(
          withPlay: true,
          episodeIdx: (widget.episode ?? 1) - 1,
        )
      ]);
    }
  }

  void _showErrorSnackBar(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            ref.read(watchProvider.notifier).clearError();
            _performInitialFetch(ref);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    if (ref.context.mounted) {
      ref.read(watchProvider.notifier).dispose();
    }
    _saveProgressTimer?.cancel();
    _animationController.dispose();
    if (mounted) {
      _resetOrientationAndUI();
    }
    super.dispose();
  }

  Future<void> _resetOrientationAndUI() async {
    if (!mounted) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await windowManager.setFullScreen(false);
    await UIHelper.enableAutoRotate();
    await UIHelper.exitImmersiveMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Consumer(
      builder: (context, ref, child) {
        final watchState = ref.watch(watchProvider);

        // Handle loading states
        if (watchState.episodesLoading || watchState.sourceLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !watchState.episodesLoading &&
                !watchState.sourceLoading) {
              Navigator.of(context).pop(); // Close any lingering loading dialog
            }
          });
        }

        // Handle errors
        if (watchState.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showErrorSnackBar(watchState.error!);
          });
        }

        return Center(
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
                  ),
                ),
                _buildEpisodesPanel(context, constraints),
              ],
            ),
          ),
        );
      },
    ), floatingActionButton: Consumer(
      builder: (context, ref, child) {
        final watchState = ref.watch(watchProvider);
        if (!watchState.sourceLoading && !watchState.episodesLoading) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  watchState.loadingMessage ?? 'Loading...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                    onPressed: () async => _performInitialFetch(ref),
                    icon: Icon(Iconsax.repeat_circle))
              ],
            ),
          ),
        );
      },
    ));
  }

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
