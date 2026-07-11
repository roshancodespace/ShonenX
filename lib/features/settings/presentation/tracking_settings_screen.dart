import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';

class TrackingSettingsScreen extends ConsumerWidget {
  const TrackingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final prefs = ref.watch(trackingPrefsProvider);
    final authTokens = ref.watch(authTokensProvider).value ?? {};
    final allTrackers = ref.watch(availableTrackersProvider);

    return AppScaffold(
      title: 'Tracking & Sync',
      body: ListView(
        children: [
          SettingsSection(
            title: 'General',
            children: [
              SettingsSliderTile(
                icon: Icons.percent,
                title: 'Sync Threshold',
                subtitle:
                    'Mark episode as watched after ${(prefs.syncThreshold * 100).toInt()}% runtime',
                value: prefs.syncThreshold,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(prefs.syncThreshold * 100).toInt()}%',
                onChanged: (val) {
                  ref
                      .read(trackingPrefsProvider.notifier)
                      .updateSyncThreshold(val);
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Privacy & Automation',
            children: [
              SettingsSwitchTile(
                icon: Icons.visibility_off_outlined,
                title: 'Incognito Mode',
                subtitle: 'Pause all cloud syncing temporarily',
                value: prefs.isIncognito,
                onInfoCallback: () {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  final textTheme = theme.textTheme;

                  AppBottomSheet.show(
                    context: context,
                    title: 'Incognito Mode',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Temporarily pause cloud tracking',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Incognito Mode temporarily prevents ShonenX from updating your connected trackers while you browse, read, or watch.',
                            style: textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pause_circle_outline_rounded,
                                  size: 24,
                                  color: cs.onSecondaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Progress updates, status changes, and automatic tracking are paused until Incognito Mode is disabled.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Good for: ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      'previewing content, testing sources, avoiding tracker spoilers, or keeping activity private temporarily.',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Your tracker accounts remain connected. Syncing simply resumes when Incognito Mode is turned off.',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onChanged: (_) {
                  ref.read(trackingPrefsProvider.notifier).toggleIncognito();
                },
              ),
              SettingsSwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Auto Track Primary',
                subtitle:
                    'Automatically link media to your primary tracker if a matching ID is found',
                value: prefs.autoTrackPrimary,
                onInfoCallback: () {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  final textTheme = theme.textTheme;

                  AppBottomSheet.show(
                    context: context,
                    title: 'Auto Track Primary',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Automatically connect tracker entries',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Normally you need to manually link anime and manga to your tracker. '
                            'With Auto Track Primary enabled, ShonenX attempts to do that automatically whenever possible.',
                            style: textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 24,
                                  color: cs.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'If a title already exists on your primary tracker account, '
                                    'its status, progress and other tracking information can appear instantly without manually linking it.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Best results: ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      'Use the same service for both your Metadata Provider and Primary Tracker (for example, AniList + AniList).',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Auto Track Primary does not add titles to your tracker account. '
                            'It only links titles that are already present on your tracker.',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onChanged: (_) {
                  ref
                      .read(trackingPrefsProvider.notifier)
                      .toggleAutoTrackPrimary();
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Trackers',
            children: allTrackers.map((tracker) {
              final isRemote = tracker is RemoteTracker;
              final isLoggedIn = isRemote
                  ? authTokens.containsKey(tracker.type)
                  : true;
              final isPrimary =
                  prefs.primaryTracker == tracker.type && !prefs.isIncognito;

              final localProfile = tracker.type.getProfile(ref);
              final profileName = isRemote
                  ? localProfile?.username
                  : (localProfile?.username != null &&
                            localProfile!.username != 'Guest'
                        ? localProfile.username
                        : 'Guest');

              return AbsorbPointer(
                absorbing: prefs.isIncognito,
                child: Opacity(
                  opacity: prefs.isIncognito ? 0.5 : 1.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    selected: isPrimary,
                    selectedTileColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    selectedColor: theme.colorScheme.primary,
                    leading: isRemote
                        ? isLoggedIn
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: localProfile?.avatarUrl ?? '',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person_outline),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: tracker.type.getIconWidget(
                                    size: 24,
                                    color: isPrimary
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                  ),
                                )
                        : (localProfile?.avatarUrl != null
                              ? ClipOval(
                                  child: TrackerAvatarWidget(
                                    imageUrl: localProfile!.avatarUrl,
                                    size: 40,
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Icon(
                                    Icons.cloud_off,
                                    color: isPrimary
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                )),
                    title: Text(
                      '${tracker.type.displayName} ${isPrimary ? '(Primary)' : ''}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isRemote
                          ? (isLoggedIn
                                ? 'Logged in as $profileName'
                                : 'Not logged in')
                          : (localProfile != null
                                ? 'Logged in as $profileName'
                                : 'Offline tracking database'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: !isPrimary
                            ? null
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    onTap: !prefs.isIncognito
                        ? () {
                            ref
                                .read(trackingPrefsProvider.notifier)
                                .setPrimaryTracker(tracker.type);
                          }
                        : null,
                    trailing: !isRemote || isLoggedIn
                        ? FilledButton.icon(
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: theme.colorScheme.onSurface,
                            ),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => TrackerProfileSheet(
                                trackerType: tracker.type,
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Customize'),
                          )
                        : FilledButton.icon(
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              if (isRemote) {
                                ref
                                    .read(authTokensProvider.notifier)
                                    .login(tracker);
                              }
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
          SettingsSection(
            title: 'Metadata Settings',
            children: [
              SettingsDropdownTile<TitlePreference>(
                icon: Icons.title_rounded,
                title: 'Preferred Title Language',
                value: prefs.titlePreference,
                items: TitlePreference.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(trackingPrefsProvider.notifier)
                        .setTitlePreference(val);
                    ref.invalidate(homeFeedProvider);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
