import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class LibraryRow extends ConsumerWidget {
  final String title;
  final TrackedStatus status;
  final TrackerType targetTracker;
  final MediaType? targetMediaType;

  const LibraryRow({
    super.key,
    required this.title,
    required this.status,
    required this.targetTracker,
    this.targetMediaType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocal = targetTracker == TrackerType.local;
    final mediaType = targetMediaType ?? MediaType.ANIME;
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    Widget buildCard(BuildContext ctx, dynamic entry, String tagPrefix) {
      return MediaCard(
        tag: '$tagPrefix-$status-${entry.providerId}',
        title: entry.title,
        imageUrl: entry.cover,
        format: entry.format,
        style: style,
        onTap: () => ctx.push(
          '/details/${entry.type}/?tag=$tagPrefix-$status-${entry.providerId}',
          extra: entry.toUnifiedMedia(),
        ),
      );
    }

    if (isLocal) {
      final asyncData = ref.watch(
        localLibraryListProvider((status: status, mediaType: mediaType)),
      );
      return HorizontalSection(
        title: title,
        height: style.layout.height,
        emptyText: 'No items in this list.',
        data: asyncData,
        itemBuilder: (context, entry) => buildCard(context, entry, 'local-library'),
      );
    } else {
      final asyncData = ref.watch(
        cloudLibraryProvider((
          status: status,
          trackerType: targetTracker,
          mediaType: mediaType,
        )),
      );
      return HorizontalSection(
        title: title,
        height: style.layout.height,
        emptyText: 'No items in this list.',
        data: asyncData,
        itemBuilder: (context, entry) => buildCard(context, entry, 'library'),
      );
    }
  }
}
