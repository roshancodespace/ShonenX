import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ContinueHistoryScreen extends ConsumerWidget {
  final MediaType type;

  const ContinueHistoryScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = type == MediaType.ANIME;
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    final AsyncValue<List<dynamic>> historyAsync;
    if (isAnime) {
      historyAsync = ref
          .watch(continueWatchingPerAnimeProvider(100))
          .whenData((data) => data.toList());
    } else {
      historyAsync = ref
          .watch(continueReadingPerMangaProvider(100))
          .whenData((data) => data.toList());
    }

    return AppScaffold(
      title: isAnime ? 'Continue Watching' : 'Continue Reading',
      subtitle: 'Pick up where you left off',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
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
              final String id = isAnime ? entry.animeId : entry.mangaId;
              final String title = isAnime
                  ? entry.animeTitle
                  : entry.mangaTitle;
              final String imageUrl =
                  entry.cover ?? (isAnime ? entry.thumbnailUrl : null) ?? '';

              return MediaCard(
                tag: 'ch-$id',
                title: title,
                imageUrl: imageUrl,
                style: style,
                onTap: () {
                  context.push('/continue/${type.id}/$id');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ContinueHistoryItemsScreen extends ConsumerWidget {
  final MediaType type;
  final String mediaId;

  const ContinueHistoryItemsScreen({
    super.key,
    required this.type,
    required this.mediaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = type == MediaType.ANIME;

    final AsyncValue<List<dynamic>> historyAsync;
    if (isAnime) {
      historyAsync = ref
          .watch(historyEpisodesProvider(mediaId))
          .whenData((data) => data.toList());
    } else {
      historyAsync = ref
          .watch(historyChaptersProvider(mediaId))
          .whenData((data) => data.toList());
    }

    final cwStyle = ref.watch(
      uiPrefsProvider.select((s) => s.continueWatchingStyle),
    );
    final crStyle = ref.watch(
      uiPrefsProvider.select((s) => s.continueReadingStyle),
    );
    final layout = isAnime ? cwStyle.layout : crStyle.layout;

    return AppScaffold(
      title: isAnime ? 'Episodes' : 'Chapters',
      subtitle: isAnime
          ? 'Watched episodes for this anime'
          : 'Read chapters for this manga',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: layout.width + 10,
              mainAxisExtent: layout.height,
              childAspectRatio: layout.aspectRatio,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];

              if (isAnime) {
                final progress = entry.durationInMilliseconds == 0
                    ? 0.0
                    : (entry.positionInMilliseconds /
                              entry.durationInMilliseconds)
                          .clamp(0.0, 1.0);
                return ContinueWatchingItem(
                  entry: entry,
                  progress: progress,
                  style: cwStyle,
                );
              } else {
                final progress = entry.totalPages == 0
                    ? 0.0
                    : (entry.positionPage / entry.totalPages).clamp(0.0, 1.0);
                return ContinueReadingItem(
                  entry: entry,
                  progress: progress,
                  style: crStyle,
                );
              }
            },
          );
        },
      ),
    );
  }
}
