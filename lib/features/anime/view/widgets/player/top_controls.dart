import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:go_router/go_router.dart';

class TopControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final VoidCallback? onEpisodesPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onQualityPressed;

  const TopControls({
    super.key,
    required this.onInteraction,
    this.onEpisodesPressed,
    this.onSettingsPressed,
    this.onQualityPressed,
  });

  VoidCallback? _wrap(VoidCallback? action) {
    if (action == null) return null;
    return () {
      onInteraction();
      action();
    };
  }

  T watchTheme<T>(
    WidgetRef ref,
    T Function(EpisodeDataState s) selector,
  ) {
    return ref.watch(episodeDataProvider.select(selector));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(selectedAnimeProvider);
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: onInteraction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                  onPressed: _wrap(() => context.pop()),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: "Back"),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source?.providerName.toUpperCase() ?? "SOURCE",
                        style: Theme.of(context).textTheme.bodySmall),
                    if (watchTheme(ref, (e) => e.selectedEpisodeIdx) != null &&
                        watchTheme(ref, (e) => e.sources).isNotEmpty)
                      Text(
                        watchTheme(ref, (e) => e.episodes)[watchTheme(
                                    ref, (e) => e.selectedEpisodeIdx)!]
                                .title ??
                            'Unavailable',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (watchTheme(ref, (e) => e.qualityOptions).length > 1)
                IconButton(
                    onPressed: _wrap(onQualityPressed),
                    icon: const Icon(Icons.high_quality_outlined),
                    tooltip: "Quality"),
              if (onEpisodesPressed != null)
                IconButton(
                    onPressed: _wrap(onEpisodesPressed),
                    icon: const Icon(Icons.playlist_play),
                    tooltip: "Episodes"),
              IconButton(
                  onPressed: _wrap(onSettingsPressed),
                  icon: const Icon(Iconsax.setting_2),
                  tooltip: "Settings"),
            ],
          ),
        ),
      ),
    );
  }
}
