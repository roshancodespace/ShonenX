import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';

class ContinueWatchingRow extends ConsumerWidget {
  final String title;
  const ContinueWatchingRow({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(continueWatchingProvider);
    final style = ref.watch(
      uiPrefsProvider.select((p) => p.continueWatchingStyle),
    );

    return HorizontalSection(
      title: title,
      height: style.layout.height,
      emptyText: 'No anime in this list.',
      data: asyncData,
      itemBuilder: (context, entry) {
        final progress = entry.durationInMilliseconds == 0
            ? 0.0
            : entry.positionInMilliseconds / entry.durationInMilliseconds;

        return ContinueWatchingItem(
          entry: entry,
          progress: progress,
          style: style,
        );
      },
    );
  }
}
