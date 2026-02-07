import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/features/anime/view/widgets/episodes_panel.dart';
import 'package:shonenx/features/anime/view/widgets/player/shonenx_video_player.dart';
import 'package:shonenx/features/anime/view_model/watch_controller.dart';
import 'package:shonenx/helpers/ui.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String mediaId;
  final String? animeId;
  final String animeName;
  final String animeFormat;
  final String animeCover;
  final int episode;
  final Duration startAt;
  final List<EpisodeDataModel>? episodes;

  const WatchScreen({
    super.key,
    required this.mediaId,
    required this.animeName,
    required this.animeFormat,
    required this.animeCover,
    this.animeId,
    this.startAt = Duration.zero,
    this.episode = 1,
    this.episodes = const [],
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final CurvedAnimation _panelAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _setupSystemUI();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      ref
          .read(watchControllerProvider.notifier)
          .initialize(
            animeName: widget.animeName,
            animeId: widget.animeId,
            episodes: widget.episodes ?? [],
            initialEpisodeIndex: widget.episode - 1,
            startAt: widget.startAt,
            mediaId: widget.mediaId,
            animeFormat: widget.animeFormat,
            animeCover: widget.animeCover,
          );
      ref
          .read(watchControllerProvider.notifier)
          .setScreenshotController(_screenshotController);
    });
  }

  void _togglePanel() {
    _panelController.isCompleted
        ? _panelController.reverse()
        : _panelController.forward();
  }

  Future<void> _setupSystemUI() async {
    await Future.wait([
      UIHelper.enableImmersiveMode(),
      UIHelper.forceLandscape(),
    ]);
  }

  Future<void> _resetSystemUI() async {
    await Future.wait([
      UIHelper.exitImmersiveMode(),
      UIHelper.enableAutoRotate(),
    ]);
  }

  @override
  void dispose() {
    _resetSystemUI();
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep controller alive to ensure listeners work
    ref.watch(watchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (_, orientation) {
          final player = ShonenXVideoPlayer(
            onEpisodesPressed: _togglePanel,
            screenshotController: _screenshotController,
          );

          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: player),
                SizeTransition(
                  sizeFactor: _panelAnimation,
                  axis: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: EpisodesPanel(
                      panelAnimation: _panelController,
                      mediaId: widget.mediaId,
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: player),
              Expanded(
                child: SizeTransition(
                  sizeFactor: _panelAnimation,
                  axis: Axis.vertical,
                  child: EpisodesPanel(
                    panelAnimation: _panelController,
                    mediaId: widget.mediaId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
