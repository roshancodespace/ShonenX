import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';

class ContinueReadingRow extends ConsumerWidget {
  final String title;
  const ContinueReadingRow({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(continueReadingPerMangaProvider(10));
    final style = ref.watch(
      uiPrefsProvider.select((p) => p.continueReadingStyle),
    );

    return HorizontalSection(
      title: title,
      height: style.layout.height,
      emptyText: 'No manga in this list.',
      data: asyncData,
      onMoreTap: () => context.push('/continue/manga'),
      itemBuilder: (context, entry) {
        final progress = entry.totalPages == 0
            ? 0.0
            : entry.positionPage / entry.totalPages;

        return ContinueReadingItem(
          entry: entry,
          progress: progress,
          style: style,
        );
      },
    );
  }
}
