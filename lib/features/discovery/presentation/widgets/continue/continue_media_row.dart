import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ContinueMediaRow extends ConsumerWidget {
  final String title;
  final MediaType type;

  const ContinueMediaRow({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = type == MediaType.ANIME;

    final asyncData = isAnime
        ? ref.watch(continueWatchingPerAnimeProvider(10))
        : ref.watch(continueReadingPerMangaProvider(10));

    final cwStyle = ref.watch(
      uiPrefsProvider.select((p) => p.continueWatchingStyle),
    );
    final crStyle = ref.watch(
      uiPrefsProvider.select((p) => p.continueReadingStyle),
    );

    final layoutHeight = isAnime ? cwStyle.layout.height : crStyle.layout.height;

    return HorizontalSection(
      title: title,
      height: layoutHeight,
      emptyText: isAnime ? 'No anime in this list.' : 'No manga in this list.',
      data: asyncData,
      onMoreTap: () => context.push('/continue/${type.id}'),
      itemBuilder: (context, dynamic entry) {
        if (isAnime) {
          final watchEntry = entry as WatchHistoryEntry;
          final progress = watchEntry.durationInMilliseconds == 0
              ? 0.0
              : watchEntry.positionInMilliseconds / watchEntry.durationInMilliseconds;

          return ContinueWatchingItem(
            entry: watchEntry,
            progress: progress,
            style: cwStyle,
          );
        } else {
          final readEntry = entry as ReadHistoryEntry;
          final progress = readEntry.totalPages == 0
              ? 0.0
              : readEntry.positionPage / readEntry.totalPages;

          return ContinueReadingItem(
            entry: readEntry,
            progress: progress,
            style: crStyle,
          );
        }
      },
    );
  }
}
