import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';

import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

import 'package:shonenx/shared/models/unified_media.dart';

class CloudLibraryRowWidget extends ConsumerWidget {
  final String title;
  final TrackedStatus status;
  final TrackerType? targetTracker;
  final MediaType? targetMediaType;

  const CloudLibraryRowWidget({
    super.key,
    required this.title,
    required this.status,
    this.targetTracker,
    this.targetMediaType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(cloudLibraryProvider((
      status: status, 
      trackerType: targetTracker, 
      mediaType: targetMediaType ?? MediaType.ANIME
    )));
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return HorizontalSection(
      title: title,
      height: style.layout.height,
      emptyText: 'No anime in this list.',
      data: asyncData,
      itemBuilder: (context, entry) {
        return MediaCard(
          tag: 'library-$status-${entry.providerId}',
          title: entry.title,
          imageUrl: entry.cover,
          format: entry.format,
          style: style,
          onTap: () => context.push(
            '/details/${entry.type}/?tag=library-$status-${entry.providerId}',
            extra: entry.toUnifiedMedia(),
          ),
        );
      },
    );
  }
}
