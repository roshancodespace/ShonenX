import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/recommendations/presentation/widgets/like_button.dart';
import 'package:shonenx/features/recommendations/providers/recommendations_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class QuickStatusSheet extends ConsumerStatefulWidget {
  final UnifiedMedia media;

  const QuickStatusSheet({super.key, required this.media});

  static Future<void> show(BuildContext context, UnifiedMedia media) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickStatusSheet(media: media),
    );
  }

  @override
  ConsumerState<QuickStatusSheet> createState() => _QuickStatusSheetState();
}

class _QuickStatusSheetState extends ConsumerState<QuickStatusSheet> {
  bool _isSaving = false;

  Future<void> _setStatus(TrackedStatus status) async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final tracker = ref.read(primaryTrackerProvider);
      final trackerLinks =
          await ref.read(trackerLinkProvider(widget.media.id).future);

      final trackingId =
          trackerLinks[tracker.type]?.trackingId ??
          resolveTrackingIdFromMedia(
            trackerType: tracker.type,
            media: widget.media,
            links: trackerLinks,
          ) ??
          widget.media.id;

      await tracker.updateListItem(
        media: widget.media,
        trackingId: trackingId,
        status: status,
      );

      // Invalidate relevant tracking and recommendation states
      ref.invalidate(
        mediaTrackingProvider(TrackingQuery(tracker.type, widget.media)),
      );
      ref.invalidate(cloudLibraryProvider);
      ref.invalidate(userTasteProfileProvider);
      ref.invalidate(recommendedAnimeFeedProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked as "${status.getLabelForMedia(widget.media.type)}" • Recommendations updated',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    final tracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(tracker.type, widget.media)),
    );

    final currentStatus = trackingState.value?.status;
    final isManga = widget.media.type == MediaType.MANGA;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(uiRoundness)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with Anime Thumbnail, Title, and Like Button
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.media.cover ?? '',
                    width: 50,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.movie_rounded, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.media.title.availableTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStatus != null &&
                                currentStatus != TrackedStatus.unknown
                            ? 'Current: ${currentStatus.getLabelForMedia(widget.media.type)}'
                            : 'Not in Library',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: currentStatus != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                LikeButton(media: widget.media, size: 24),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Text(
              'Set Status (Updates Recommendations)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusOptionChip(
                    icon: Icons.play_circle_fill_rounded,
                    label: isManga ? 'Reading' : 'Watching',
                    color: Colors.green,
                    isSelected: currentStatus == TrackedStatus.watching,
                    onTap: () => _setStatus(TrackedStatus.watching),
                  ),
                  _StatusOptionChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Completed',
                    color: Colors.deepPurpleAccent,
                    isSelected: currentStatus == TrackedStatus.completed,
                    onTap: () => _setStatus(TrackedStatus.completed),
                  ),
                  _StatusOptionChip(
                    icon: Icons.bookmark_add_rounded,
                    label: isManga ? 'Plan to Read' : 'Plan to Watch',
                    color: Colors.blueAccent,
                    isSelected: currentStatus == TrackedStatus.planning,
                    onTap: () => _setStatus(TrackedStatus.planning),
                  ),
                  _StatusOptionChip(
                    icon: Icons.pause_circle_filled_rounded,
                    label: 'Paused',
                    color: Colors.amber,
                    isSelected: currentStatus == TrackedStatus.paused,
                    onTap: () => _setStatus(TrackedStatus.paused),
                  ),
                  _StatusOptionChip(
                    icon: Icons.cancel_rounded,
                    label: 'Dropped',
                    color: Colors.redAccent,
                    isSelected: currentStatus == TrackedStatus.dropped,
                    onTap: () => _setStatus(TrackedStatus.dropped),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusOptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOptionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
