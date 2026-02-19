import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/shared/providers/settings/source_notifier.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class TopControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback? onQualityPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSubtitlePressed;

  const TopControls({
    super.key,
    required this.onInteraction,
    this.onEpisodesPressed,
    this.onQualityPressed,
    this.onSettingsPressed,
    this.onSubtitlePressed,
  });

  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      action();
      onInteraction();
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEp = ref.watch(
      episodeDataProvider.select((e) => e.selectedEpisode),
    );
    final sources = ref.watch(episodeDataProvider.select((e) => e.sources));
    final qualityOptions = ref.watch(
      episodeDataProvider.select((e) => e.qualityOptions),
    );
    final hasSubtitles = ref.watch(
      episodeDataProvider.select((e) => e.selectedSubtitleIdx != 0),
    );

    final episodeTitle = ref.watch(
      episodeListProvider.select((s) {
        if (selectedEp == null || selectedEp > s.episodes.length) return null;
        return s.episodes.firstWhere((i) => i.number == selectedEp).title;
      }),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.black54, Colors.transparent],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _wrap(() => context.pop()),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSourceName(ref).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (selectedEp != null && sources.isNotEmpty)
                      Text(
                        episodeTitle ?? 'Episode $selectedEp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSubtitlePressed != null)
                    _TopIconButton(
                      icon: hasSubtitles
                          ? Icons.closed_caption_rounded
                          : Icons.closed_caption_off_rounded,
                      onTap: _wrap(onSubtitlePressed),
                      color: hasSubtitles
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),

                  if (qualityOptions.length > 1)
                    _TopIconButton(
                      icon: Icons.high_quality_rounded,
                      onTap: _wrap(onQualityPressed),
                    ),

                  _TopIconButton(
                    icon: Icons.aspect_ratio_rounded,
                    onTap: () {
                      const fitModes = [
                        BoxFit.contain,
                        BoxFit.cover,
                        BoxFit.fill,
                      ];
                      final notifier = ref.read(playerStateProvider.notifier);
                      final currentFit = ref.read(playerStateProvider).fit;
                      notifier.setFit(
                        fitModes[(fitModes.indexOf(currentFit) + 1) %
                            fitModes.length],
                      );
                      onInteraction();
                    },
                  ),

                  _TopIconButton(
                    icon: Icons.settings_rounded,
                    onTap: _wrap(onSettingsPressed),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSourceName(WidgetRef ref) {
    if (!ref.watch(experimentalProvider).useExtensions) {
      return ref.watch(selectedAnimeProvider)?.providerName ?? "Legacy";
    } else {
      return ref.watch(sourceProvider).activeAnimeSource?.name ?? 'Extension';
    }
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _TopIconButton({
    required this.icon,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
