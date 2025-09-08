import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/features/anime/view/widgets/episodes_panel.dart';
import 'package:shonenx/features/anime/view/widgets/player/controls_overlay.dart';
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String animeId;
  final String animeName;
  final int? episode;
  final Duration startAt;

  const WatchScreen({
    super.key,
    required this.animeId,
    required this.animeName,
    this.startAt = Duration.zero,
    this.episode = 1,
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _panelAnimationController;

  @override
  void initState() {
    super.initState();
    _setUpSystemUI();

    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Trigger the initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(episodeDataProvider.notifier).fetchEpisodes(
            animeTitle: widget.animeName,
            animeId: widget.animeId,
            initialEpisodeIdx: (widget.episode ?? 1) - 1,
            startAt: widget.startAt,
          );
    });

    // ref.read(playerStateProvider.notifier).open(
    //     "https://ed.netmagcdn.com:2228/hls-playback/a2f735133a52c59ba600de41f3338b5d922ce3cad0b5ffbe500a7aacb5c1ae1a2c7f327dc4fefa0d9be07dc52c4249a839a96410b3fbae79007318ed3b2587772dbf5b55f0feb28cf1f20258417d66eead5572d9a4d53213671c9e57f0d991e4ed535f6c32139ddc9caf4e359a4253d121ac83dcbe45b20a95821ed43e08eb8dbfe36d87ac7e873b8c62ab7eb9cca24e/master.m3u8",
    //     null);
  }

  void _toggleEpisodesPanel() {
    final isPanelOpen =
        _panelAnimationController.status == AnimationStatus.completed;
    isPanelOpen
        ? _panelAnimationController.reverse()
        : _panelAnimationController.forward();
  }

  Future<void> _setUpSystemUI() async {
    await UIHelper.enableImmersiveMode();
    await UIHelper.forceLandscape();
  }

  Future<void> _resetSystemUI() async {
    await UIHelper.exitImmersiveMode();
    await UIHelper.forcePortrait();
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _resetSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: OrientationBuilder(
        builder: (context, orientation) {
          final videoPlayerWidget = Video(
            controller: playerNotifier.videoController,
            fit: playerState.fit,
            controls: (state) => CloudstreamControls(
              onEpisodesPressed: _toggleEpisodesPanel,
            ),
            subtitleViewConfiguration: SubtitleViewConfiguration(
              visible: false,
            ),
          );

          final episodesPanelWidget = _buildEpisodesPanel(context, orientation);

          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: videoPlayerWidget),
                episodesPanelWidget,
              ],
            );
          } else {
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: videoPlayerWidget,
                ),
                Expanded(
                  child: episodesPanelWidget,
                ),
              ],
            );
          }
        },
      )),
    );
  }

  Widget _buildEpisodesPanel(BuildContext context, Orientation orientation) {
    final animation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    );

    final panelContent = EpisodesPanel(animeId: widget.animeId);

    if (orientation == Orientation.landscape) {
      final screenWidth = MediaQuery.of(context).size.width;
      final panelWidth =
          screenWidth < 800 ? screenWidth * 0.45 : screenWidth * 0.35;
      return SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        child: SizedBox(width: panelWidth, child: panelContent),
      );
    } else {
      return SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        child: panelContent,
      );
    }
  }
}
