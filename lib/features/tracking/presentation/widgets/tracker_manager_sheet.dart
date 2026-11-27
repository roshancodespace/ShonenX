import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/tracking/providers/tracker_auth_provider.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/presentation/widgets/link_tracker_dialog.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_button_group.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class TrackerManagerSheet extends ConsumerWidget {
  final UnifiedMedia media;

  const TrackerManagerSheet({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerLinks = ref.watch(trackerLinkProvider(media.id)).value ?? {};
    final activeTrackers = ref.watch(activeTrackersProvider(media.type));

    return AppBottomSheet(
      title: 'Manage Trackers',
      child: AppCardGroup(
        padding: EdgeInsets.zero,
        children: activeTrackers.map((tracker) {
          final type = tracker.type;
          final isRemote = tracker is RemoteTracker;
          final isLinked = isRemote ? trackerLinks.containsKey(type) : true;
          final isAuthenticated = type.isAuthenticated(ref) || !isRemote;

          if (isLinked) {
            return _LinkedTrackerRow(
              media: media,
              trackerMapping: isRemote ? trackerLinks[type] : null,
              tracker: tracker,
            );
          }

          if (isAuthenticated) {
            return _AvailableTrackerRow(media: media, tracker: tracker);
          }

          return _LoginTrackerRow(tracker: tracker);
        }).toList(),
      ),
    );
  }
}

class _AvailableTrackerRow extends StatelessWidget {
  final UnifiedMedia media;
  final TrackingService tracker;

  const _AvailableTrackerRow({required this.media, required this.tracker});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCardSurface(
      padding: EdgeInsets.zero,
      onTap: () {
        if (tracker is RemoteTracker) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => LinkTrackerSheet(
              primaryMediaId: media.id,
              mediaType: media.type,
              initialSearchQuery: media.title.getPreferedTitle,
              tracker: tracker as RemoteTracker,
            ),
          );
        }
      },
      child: ListTile(
        minTileHeight: 40,
        leading: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHighest,
          ),
          child: tracker.type.getIconWidget(size: 20, color: cs.onSurfaceVariant),
        ),
        title: Text(
          tracker.type.displayName,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Tap to link ${media.type == MediaType.MANGA ? 'manga' : 'anime'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _LoginTrackerRow extends ConsumerWidget {
  final TrackingService tracker;

  const _LoginTrackerRow({required this.tracker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCardSurface(
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 40,
        leading: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHighest,
          ),
          child: tracker.type.getIconWidget(size: 20, color: cs.onSurfaceVariant),
        ),
        title: Text(
          tracker.type.displayName,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Login required',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ),
        ),
        trailing: AppButton(
          label: 'Login',
          variant: AppButtonVariant.tonal,
          size: AppButtonSize.small,
          onPressed: () {
            if (tracker is RemoteTracker) {
              ref
                  .read(authTokensProvider.notifier)
                  .login(tracker as RemoteTracker);
            }
          },
        ),
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
        bool isLocal = tracker.type == TrackerType.local;
        bool deleteRemote = isLocal;
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
                    'Remove link with ${tracker.type.displayName}?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  CheckboxListTile(
                    value: deleteRemote,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Also remove remote entry'),
                    subtitle: const Text(
                      'Deletes tracked progress from remote service.',
                    ),
                    onChanged: isLocal || isDeleting
                        ? null
                        : (value) {
                            setState(() {
                              deleteRemote = value ?? false;
                            });
                          },
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Remove Connection',
                    variant: AppButtonVariant.destructive,
                    size: AppButtonSize.large,
                    isExpanded: true,
                    isLoading: isDeleting,
                    onPressed: () async {
                      setState(() {
                        isDeleting = true;
                      });

                      if (deleteRemote) {
                        try {
                          await tracker.removeEntry(
                            trackingId:
                                trackerMapping?.trackingId ?? media.id,
                            mediaType: media.type,
                          );
                        } catch (_) {}
                      }

                      ref
                          .read(trackerLinkProvider(media.id).notifier)
                          .removeLink(tracker.type);

                      if (isLocal) {
                        ref.invalidate(
                          mediaTrackingProvider(
                            TrackingQuery(tracker.type, media),
                          ),
                        );
                      }

                      ref.invalidate(cloudLibraryProvider);

                      if (context.mounted) {
                        context.pop();
                      }
                    },
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
      mediaTrackingProvider(TrackingQuery(tracker.type, media)),
    );

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return trackingState.when(
      loading: () {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: AppProgressIndicator(type: AppProgressType.circular)),
        );
      },
      error: (_, __) {
        return AppCardSurface(
          padding: EdgeInsets.zero,
          child: ListTile(
            minTileHeight: 40,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.errorContainer,
              ),
              child: Center(
                child: tracker.type.getIconWidget(
                  size: 20,
                  color: cs.onErrorContainer,
                ),
              ),
            ),
            title: Text(
              tracker.type.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Failed to load'),
            trailing: AppActionButtonGroup(
              height: 36,
              items: [
                AppActionItem(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Retry',
                  onTap: () {
                    ref.invalidate(
                      mediaTrackingProvider(TrackingQuery(tracker.type, media)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      data: (listItem) {
        final isRemote = tracker is RemoteTracker;

        if (listItem == null) {
          return AppCardSurface(
            padding: EdgeInsets.zero,
            child: ListTile(
              minTileHeight: 40,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              title: Text(
                tracker.type.displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Not in list',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.78),
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRemote) ...[
                    AppActionButtonGroup(
                      height: 36,
                      items: [
                        AppActionItem(
                          icon: Icons.swap_horiz_rounded,
                          tooltip: 'Relink',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => LinkTrackerSheet(
                                primaryMediaId: media.id,
                                mediaType: media.type,
                                initialSearchQuery:
                                    media.title.getPreferedTitle,
                                tracker: tracker as RemoteTracker,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppButton(
                    label: 'Add',
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.small,
                    onPressed: () {
                      final blankItem = TrackedListItem(
                        status: TrackedStatus.unknown,
                        progress: 0,
                        score: 0,
                      );

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => EditTrackerSheet(
                          media: media,
                          initialItem: blankItem,
                          tracker: tracker,
                          trackingId: trackerMapping?.trackingId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return AppCardSurface(
          padding: EdgeInsets.zero,
          child: ListTile(
            minTileHeight: 40,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Center(
                child: tracker.type.getIconWidget(
                  size: 20,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(
              tracker.type.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${media.type == MediaType.MANGA ? "Ch" : "Ep"} ${listItem.progress.toInt()} • ${listItem.status.getLabelForMedia(media.type)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.78),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppActionButtonGroup(
                  height: 36,
                  items: [
                    AppActionItem(
                      icon: Icons.link_off_rounded,
                      tooltip: 'Unlink',
                      onTap: () => _removeTracker(context, ref),
                    ),
                    if (isRemote)
                      AppActionItem(
                        icon: Icons.swap_horiz_rounded,
                        tooltip: 'Relink',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => LinkTrackerSheet(
                              primaryMediaId: media.id,
                              mediaType: media.type,
                              initialSearchQuery: media.title.getPreferedTitle,
                              tracker: tracker as RemoteTracker,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Edit',
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => EditTrackerSheet(
                        media: media,
                        initialItem: listItem,
                        tracker: tracker,
                        trackingId: trackerMapping?.trackingId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
