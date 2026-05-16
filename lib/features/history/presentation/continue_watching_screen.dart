import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ContinueWatchingScreen extends ConsumerWidget {
  const ContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final historyAsync = ref.watch(continueWatchingPerAnimeProvider(100));

    return AppScaffold(
      title: 'Continue Watching',
      subtitle: 'Pick up where you left off',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No watch history found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: style.layout.width + 10,
              mainAxisExtent: style.layout.height,
              childAspectRatio: style.layout.aspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];

              return MediaCard(
                tag: 'cw-${entry.animeId}',
                title: entry.animeTitle,
                imageUrl: entry.cover ?? entry.thumbnailUrl ?? '',
                style: style,
                onTap: () {
                  context.push('/continue-watching/${entry.animeId}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ContinueWatchingEpisodesScreen extends ConsumerWidget {
  final String animeId;

  const ContinueWatchingEpisodesScreen({super.key, required this.animeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyEpisodesProvider(animeId));
    final cardStyle = ref.watch(
      uiPrefsProvider.select((s) => s.continueWatchingStyle),
    );

    return AppScaffold(
      title: 'Episodes',
      subtitle: 'Watched episodes for this anime',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No watch history found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cardStyle.layout.width + 10,
              mainAxisExtent: cardStyle.layout.height,
              childAspectRatio: cardStyle.layout.aspectRatio,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];

              final progress = entry.durationInMilliseconds == 0
                  ? 0.0
                  : (entry.positionInMilliseconds /
                            entry.durationInMilliseconds)
                        .clamp(0.0, 1.0);
              return ContinueWatchingItem(
                entry: entry,
                progress: progress,
                style: cardStyle,
              );

              // return _HistoryEpisodeTile(
              //   entry: entry,
              //   progress: progress,
              //   onTap: () {
              //     final media = UnifiedMedia(
              //       id: entry.animeId,
              //       idMal: entry.animeIdMal,
              //       title: MediaTitle(english: entry.animeTitle),
              //       type: MediaType.ANIME,
              //       cover: entry.cover,
              //       banner: entry.banner,
              //     );

              //     context.push(
              //       '/details/${media.type.id}'
              //       '?tag=cw-ep-${entry.animeId}-${entry.episodeNumber}',
              //       extra: media,
              //     );
              //   },
              // );
            },
          );
        },
      ),
    );
  }
}
