import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/shared/providers/settings/source_notifier.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class TopControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback? onQualityPressed;
  final VoidCallback? onSettingsPressed;

  const TopControls({
    super.key,
    required this.onInteraction,
    this.onEpisodesPressed,
    this.onQualityPressed,
    this.onSettingsPressed,
  });

  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      action();
      onInteraction();
    };
  }

  T watchEpisode<T>(WidgetRef ref, T Function(EpisodeDataState s) selector) {
    return ref.watch(episodeDataProvider.select(selector));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEp = watchEpisode(ref, (e) => e.selectedEpisode);
    final episodeTitle = ref.watch(
      episodeListProvider.select((s) {
        if (selectedEp == null || selectedEp > s.episodes.length) return null;
        return s.episodes.firstWhere((i) => i.number == selectedEp).title;
      }),
    );
    final sources = watchEpisode(ref, (e) => e.sources);
    final qualityOptions = watchEpisode(ref, (e) => e.qualityOptions);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: onInteraction,
          behavior: HitTestBehavior.deferToChild,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                // Back button
                _buildControlButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: _wrap(() => context.pop()),
                  color: Colors.white,
                ),

                const SizedBox(width: 16),

                // Title section
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source name
                      Text(
                        _getSourceName(ref),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Episode title
                      if (selectedEp != null && sources.isNotEmpty)
                        Text(
                          episodeTitle ?? 'Episode: $selectedEp',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (qualityOptions.length > 1) ...[
                      _buildControlButton(
                        icon: Icons.hd_outlined,
                        onPressed: _wrap(onQualityPressed),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    // if (onEpisodesPressed != null) ...[
                    //   _buildControlButton(
                    //     icon: Icons.,
                    //     onPressed: _wrap(onEpisodesPressed),
                    //     color: scheme.onSurface,
                    //   ),
                    //   const SizedBox(width: 8),
                    // ],
                    (() {
                      const fitModes = [
                        BoxFit.contain,
                        BoxFit.cover,
                        BoxFit.fill,
                      ];

                      return _buildControlButton(
                        icon: Iconsax.crop,
                        color: Colors.white,
                        onPressed: () {
                          final notifier = ref.read(
                            playerStateProvider.notifier,
                          );
                          final currentFit = ref.read(playerStateProvider).fit;

                          final index = fitModes.indexOf(currentFit);
                          final nextFit =
                              fitModes[(index + 1) % fitModes.length];

                          notifier.setFit(nextFit);
                        },
                      );
                    })(),
                    _buildControlButton(
                      icon: Iconsax.menu_1,
                      color: Colors.white,
                      onPressed: _wrap(onSettingsPressed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  String _getSourceName(WidgetRef ref) {
    final source = ref.watch(selectedAnimeProvider);

    if (!ref.watch(experimentalProvider).useExtensions) {
      return source?.providerName.toUpperCase() ?? "LEGACY";
    } else {
      final sourceNotifier = ref.watch(sourceProvider);
      return sourceNotifier.activeAnimeSource?.name ?? 'Extension';
    }
  }
}
