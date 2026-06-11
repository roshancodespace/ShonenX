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
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';

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

              final profileName = isRemote
                  ? tracker.type.getProfile(ref)?.username
                  : 'Local Storage';

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
                                      imageUrl:
                                          tracker.type
                                              .getProfile(ref)
                                              ?.avatarUrl ??
                                          '',
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
                                  child: SvgIcon(
                                    tracker.type.iconSvgString,
                                    color: isPrimary
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
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
                          ),
                    title: Text(
                      '${tracker.type.displayName} ${isPrimary ? '(Primary)' : ''}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isRemote
                          ? (isLoggedIn
                                ? 'Logged in as $profileName'
                                : 'Not logged in')
                          : 'Offline tracking database',
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
                    trailing: !isRemote
                        ? null
                        : FilledButton.icon(
                            style: IconButton.styleFrom(
                              backgroundColor: !isLoggedIn
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              foregroundColor: !isLoggedIn
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onError,
                            ),
                            onPressed: () {
                              if (isRemote) {
                                if (isLoggedIn) {
                                  ref
                                      .read(authTokensProvider.notifier)
                                      .logout(tracker);
                                } else {
                                  ref
                                      .read(authTokensProvider.notifier)
                                      .login(tracker);
                                }
                              }
                            },
                            icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
                            label: Text(isLoggedIn ? 'Logout' : 'Login'),
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
