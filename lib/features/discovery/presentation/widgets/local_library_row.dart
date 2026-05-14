import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';

class LocalLibraryRow extends ConsumerWidget {
  final String title;
  final TrackedStatus status;
  const LocalLibraryRow({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(localLibraryListProvider(status));
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return HorizontalSection(
      title: title,
      height: style.layout.height,
      emptyText: 'No items in this list.',
      data: asyncData,
      itemBuilder: (context, entry) {
        return MediaCard(
          tag: 'local-library-$status-${entry.providerId}',
          title: entry.title,
          imageUrl: entry.cover,
          format: entry.format,
          style: style,
          onTap: () => context.push(
            '/details/${entry.type}/?tag=local-library-$status-${entry.providerId}',
            extra: entry.toUnifiedMedia(),
          ),
        );
      },
    );
  }
}
