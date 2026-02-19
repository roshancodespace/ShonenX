import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/details/view/widgets/tracker/tracker_config_sheet.dart';
import 'package:shonenx/features/details/view/widgets/tracker/tracker_search_sheet.dart';
import 'package:shonenx/features/details/view_model/external_tracker_notifier.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';

/// Bottom sheet for selecting a tracker provider (AniList / MAL).
/// Shows login options if not authenticated, or opens config/search sheets.
class TrackerSelectionSheet extends ConsumerWidget {
  final UniversalMedia media;

  const TrackerSelectionSheet({super.key, required this.media});

  static Future<void> show(BuildContext context, UniversalMedia media) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackerSelectionSheet(media: media),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final trackerState = ref.watch(externalTrackerProvider(media.id));

    final isAnilistAuth = auth.isAniListAuthenticated;
    final isMalAuth = auth.isMalAuthenticated;
    final noneAuth = !isAnilistAuth && !isMalAuth;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'Track with',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            media.title.userPreferred,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          if (noneAuth) ...[
            // No tracker accounts linked
            _buildInfoCard(
              theme,
              icon: Iconsax.info_circle,
              text: 'Log in to a tracker to start tracking your anime.',
            ),
            const SizedBox(height: 12),
            _buildLoginTile(
              context,
              ref,
              theme,
              tracker: TrackerType.anilist,
              platform: AuthPlatform.anilist,
              auth: auth,
            ),
            const SizedBox(height: 8),
            _buildLoginTile(
              context,
              ref,
              theme,
              tracker: TrackerType.mal,
              platform: AuthPlatform.mal,
              auth: auth,
            ),
          ] else ...[
            // Show authenticated tracker options
            if (isAnilistAuth)
              _buildTrackerTile(
                context,
                ref,
                theme,
                tracker: TrackerType.anilist,
                media: media,
                trackerState: trackerState,
                user: auth.anilistUser,
              ),
            if (isAnilistAuth && isMalAuth) const SizedBox(height: 8),
            if (isMalAuth)
              _buildTrackerTile(
                context,
                ref,
                theme,
                tracker: TrackerType.mal,
                media: media,
                trackerState: trackerState,
                user: auth.malUser,
              ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme, {
    required TrackerType tracker,
    required AuthPlatform platform,
    required AuthState auth,
  }) {
    final isLoading = auth.isLoadingFor(platform);
    return ListTile(
      leading: _trackerIcon(tracker, theme),
      title: Text(
        'Log in to ${tracker.displayName}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Iconsax.login, color: theme.colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.surfaceContainerHigh,
      onTap: isLoading
          ? null
          : () async {
              await ref.read(authProvider.notifier).login(platform);
              if (context.mounted) Navigator.pop(context);
            },
    );
  }

  Widget _buildTrackerTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme, {
    required TrackerType tracker,
    required UniversalMedia media,
    required ExternalTrackerState trackerState,
    dynamic user,
  }) {
    final entry = trackerState.entries[tracker];
    final isLoading = trackerState.isLoading[tracker] ?? false;
    final statusSummary = trackerState.getStatusSummary(tracker);

    return ListTile(
      leading: _trackerIcon(tracker, theme),
      title: Text(
        'Track with ${tracker.displayName}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: isLoading
          ? const Text('Loading...')
          : statusSummary != null
          ? Text(
              statusSummary,
              style: TextStyle(color: theme.colorScheme.primary),
            )
          : const Text('Not tracked'),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              entry != null ? Iconsax.edit : Iconsax.add_circle,
              color: theme.colorScheme.primary,
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.surfaceContainerHigh,
      onTap: isLoading
          ? null
          : () {
              Navigator.pop(context);
              _handleTrackerSelection(
                context,
                ref,
                tracker,
                media,
                trackerState,
              );
            },
    );
  }

  void _handleTrackerSelection(
    BuildContext context,
    WidgetRef ref,
    TrackerType tracker,
    UniversalMedia media,
    ExternalTrackerState trackerState,
  ) {
    final notifier = ref.read(externalTrackerProvider(media.id).notifier);
    final remoteId = notifier.resolveRemoteId(media, tracker);

    if (remoteId != null) {
      // ID available — skip search, open config directly
      TrackerConfigSheet.show(
        context,
        media: media,
        tracker: tracker,
        remoteId: remoteId,
      );
    } else {
      // ID not available — open search
      TrackerSearchSheet.show(context, media: media, tracker: tracker);
    }
  }

  Widget _trackerIcon(TrackerType tracker, ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tracker == TrackerType.anilist
            ? const Color(0xFF02A9FF).withOpacity(0.15)
            : const Color(0xFF2E51A2).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          tracker.shortName,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: tracker == TrackerType.anilist
                ? const Color(0xFF02A9FF)
                : const Color(0xFF2E51A2),
          ),
        ),
      ),
    );
  }
}
