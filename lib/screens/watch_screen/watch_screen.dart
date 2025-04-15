import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/screens/watch_screen/components/loading_overlay.dart';
import 'package:shonenx/screens/watch_screen/components/video_player_view.dart';
import 'package:shonenx/screens/watch_screen/episodes_panel.dart';
import 'package:shonenx/services/watch_progress_service.dart';
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
  // Services
  final WatchProgressService _progressService = WatchProgressService();

  // Controllers
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
    await _progressService.initialize();
    _progressService.startProgressTimer(() {
      if (mounted) _saveProgress();
    });
  }

  Future<void> _saveProgress() async {

    await _progressService.saveProgress(
      animeMedia: widget.animeMedia,
      ref: ref,
      onError: (errorMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _performInitialFetch(WidgetRef ref) async {
    if (mounted) {
      final notifier = ref.read(watchProvider.notifier);
      await notifier.fetchEpisodes(
        animeId: widget.animeId,
        episodeIdx: (widget.episode ?? 1) - 1,
      );
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
    _progressService.dispose();
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
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final watchState = ref.watch(watchProvider);

          // Handle loading state changes
          if (watchState.episodesLoading || watchState.sourceLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  !watchState.episodesLoading &&
                  !watchState.sourceLoading) {
                Navigator.of(context).pop();
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
                  // Video player
                  VideoPlayerView(
                    controller: _controller,
                    panelAnimationController: _animationController,
                  ),
                  // Episodes panel
                  _buildEpisodesPanel(context, constraints),
                ],
              ),
            ),
          );
        },
      ),
      // Loading overlay
      floatingActionButton: LoadingOverlay(
        onRetry: () => _performInitialFetch(ref),
      ),
    );
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
