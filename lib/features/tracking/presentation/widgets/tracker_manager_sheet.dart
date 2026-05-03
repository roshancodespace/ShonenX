import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/presentation/widgets/link_tracker_dialog.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class TrackerManagerSheet extends ConsumerWidget {
  final UnifiedMedia media;
  final List<TrackerType> activeTrackers;
  final TrackerType? editTracker;

  const TrackerManagerSheet({
    super.key,
    required this.media,
    required this.activeTrackers,
    this.editTracker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerLinks = ref.watch(trackerLinkProvider(media.id)).value ?? {};

    return AppBottomSheet(
      title: 'Manage Trackers',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...activeTrackers.map((type) {
            final tracker = ref
                .read(availableTrackersProvider)
                .firstWhere((t) => t.type == type);

            final isRemote = tracker is RemoteTracker;
            final isLinked = isRemote ? trackerLinks.containsKey(type) : true;
            final isAuthenticated = type.isAuthenticated(ref) || !isRemote;

            if (isLinked) {
              return _LinkedTrackerRow(
                media: media,
                trackerMapping: isRemote ? trackerLinks[type] : null,
                tracker: tracker,
              );
            } else if (isAuthenticated) {
              return ListTile(
                leading: const Icon(Icons.sync),
                title: Text(type.displayName),
                subtitle: const Text('Tap to link anime'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                onTap: () {
                  if (isRemote) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => LinkTrackerSheet(
                        primaryMediaId: media.id,
                        initialSearchQuery: media.title.availableTitle,
                        tracker: tracker,
                      ),
                    );
                  }
                },
              );
            } else {
              return ListTile(
                leading: const Icon(Icons.sync),
                title: Text(type.displayName),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                subtitle: Text('Login to ${type.displayName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (isRemote) {
                    ref.read(authTokensProvider.notifier).login(tracker);
                  }
                },
              );
            }
          }),
        ],
      ),
    );
  }
}

class _LinkedTrackerRow extends ConsumerWidget {
  final UnifiedMedia media;
  final TrackerMapping? trackerMapping;
  final TrackingService tracker;

  const _LinkedTrackerRow({
    required this.media,
    required this.trackerMapping,
    required this.tracker,
  });

  Future<void> _removeTracker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        bool deleteRemote = false;
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AppBottomSheet(
              title: 'Remove Connection',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Are you sure you want to completely remove the link to ${tracker.type.displayName}?',
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Also drop from remote list'),
                    subtitle: const Text('Erases tracked progress on remote.'),
                    value: deleteRemote,
                    onChanged: isDeleting
                        ? null
                        : (val) => setState(() => deleteRemote = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setState(() => isDeleting = true);
                            if (deleteRemote) {
                              try {
                                await tracker.removeEntry(
                                  trackingId:
                                      trackerMapping?.trackingId ?? media.id,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete remote data: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                            ref
                                .read(trackerLinkProvider(media.id).notifier)
                                .removeLink(tracker.type);
                            if (context.mounted) context.pop();
                          },
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Remove Connection'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(tracker.type, media.id)),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return trackingState.when(
      loading: () => ListTile(
        title: Text(tracker.type.displayName),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => ListTile(
        leading: Icon(Icons.error_outline, color: colorScheme.error),
        title: Text(tracker.type.displayName),
        subtitle: const Text('Failed to load'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(
            mediaTrackingProvider(TrackingQuery(tracker.type, media.id)),
          ),
        ),
      ),
      data: (listItem) {
        final isRemote = tracker is RemoteTracker;
        final isAuth = !isRemote || tracker.type.isAuthenticated(ref);

        if (!isAuth) {
          return ListTile(
            leading: Icon(Icons.cloud_off, color: colorScheme.onSurfaceVariant),
            title: Text(tracker.type.displayName),
            subtitle: const Text('Not logged in'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            trailing: FilledButton.tonal(
              onPressed: () {
                if (isRemote) {
                  ref
                      .read(authTokensProvider.notifier)
                      .login(tracker as RemoteTracker);
                }
              },
              child: const Text('Login'),
            ),
          );
        } else if (listItem == null) {
          return ListTile(
            leading: Icon(Icons.cloud_off, color: colorScheme.onSurfaceVariant),
            title: Text(
              '${tracker.type.displayName} - (${trackerMapping?.trackingTitle ?? media.title.availableTitle})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Not in list'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRemote)
                  IconButton.outlined(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => LinkTrackerSheet(
                          primaryMediaId: media.id,
                          initialSearchQuery: media.title.availableTitle,
                          tracker: tracker as RemoteTracker,
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                  ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () {
                    final blankItem = TrackedListItem(
                      status: TrackedStatus.unknown,
                      progress: 0,
                      score: 0.0,
                    );

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => EditTrackerSheet(
                        media: media,
                        initialItem: blankItem,
                        trackerType: tracker.type,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        }

        return ListTile(
          leading: Icon(Icons.bookmark_added, color: colorScheme.primary),
          title: Text(
            '${tracker.type.displayName} - (${trackerMapping?.trackingTitle ?? media.title.availableTitle})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Ep ${listItem.progress.toInt()} • ${listItem.status.displayName}',
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                onPressed: () => _removeTracker(context, ref),
                icon: const Icon(Icons.link_off),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isRemote)
                IconButton.outlined(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => LinkTrackerSheet(
                        primaryMediaId: media.id,
                        initialSearchQuery: media.title.availableTitle,
                        tracker: tracker as RemoteTracker,
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                ),
              if (isRemote) const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => EditTrackerSheet(
                      media: media,
                      initialItem: listItem,
                      trackerType: tracker.type,
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        );
      },
    );
  }
}
