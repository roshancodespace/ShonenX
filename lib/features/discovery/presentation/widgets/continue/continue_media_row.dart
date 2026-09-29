import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ContinueMediaRow extends ConsumerWidget {
  final String title;
  final MediaType type;

  const ContinueMediaRow({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = type == MediaType.ANIME;

    final asyncData = ref.watch(
      historyPerMediaProvider((mediaType: type.id, limit: 10)),
    );

    if (asyncData.value?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final cwStyle = ref.watch(
      uiPrefsProvider.select((p) => p.continueWatchingStyle),
    );
    final crStyle = ref.watch(
      uiPrefsProvider.select((p) => p.continueReadingStyle),
    );
    final isCwWide = ref.watch(
      uiPrefsProvider.select((p) => p.isContinueWatchingWide(cwStyle.name)),
    );
    final isCrWide = ref.watch(
      uiPrefsProvider.select((p) => p.isContinueReadingWide(crStyle.name)),
    );

    final layoutHeight = isAnime
        ? cwStyle
              .getLayout(isContinueWatching: true, isWideMode: isCwWide)
              .height
        : crStyle
              .getLayout(isContinueReading: true, isWideMode: isCrWide)
              .height;

    return HorizontalSection(
      title: title,
      height: layoutHeight,
      emptyText: isAnime ? 'No anime in this list.' : 'No manga in this list.',
      data: asyncData,
      onMoreTap: () => context.pushContinueHistory(type),
      itemBuilder: (context, dynamic entryDynamic) {
        final entry = entryDynamic as HistoryEntry;
        final progress = entry.total == 0 ? 0.0 : entry.progress / entry.total;

        if (isAnime) {
          return ContinueWatchingItem(
            entry: entry,
            progress: progress,
            style: cwStyle,
          );
        } else {
          return ContinueReadingItem(
            entry: entry,
            progress: progress,
            style: crStyle,
          );
        }
      },
    );
  }
}
