import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:shonenx/core/utils/env.dart';

class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  final Set<TrackerType> _loggingInTrackers = {};

  Future<void> _handleLogin(RemoteTracker tracker) async {
    if (_loggingInTrackers.contains(tracker.type)) return;
    setState(() {
      _loggingInTrackers.add(tracker.type);
    });
    try {
      await ref.read(authTokensProvider.notifier).login(tracker);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully logged into ${tracker.type.displayName}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed for ${tracker.type.displayName}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingInTrackers.remove(tracker.type);
        });
      }
    }
  }

  bool _hasCredentials(TrackerType type) {
    final prefs = ref.read(trackingPrefsProvider);
    final custom = prefs.customCredentials[type];
    if (custom != null && custom.clientId.isNotEmpty) {
      return true;
    }
    switch (type) {
      case TrackerType.anilist:
        return true; // Built-in public credentials bundled
      case TrackerType.myanimelist:
        return true; // Built-in public credentials bundled
      case TrackerType.simkl:
        return Env.SIMKL_CLIENT_ID.isNotEmpty;
      default:
        return true;
    }
  }

  void _showCredentialsDialog(TrackerType type) {
    final prefs = ref.read(trackingPrefsProvider);
    final custom = prefs.customCredentials[type];

    final idController = TextEditingController(text: custom?.clientId);
    final secretController = TextEditingController(text: custom?.clientSecret);
    final tokenController = TextEditingController();
    bool isSubmittingToken = false;

    AppDialog.show(
      context: context,
      title: '${type.displayName} Settings & Token',
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom API Credentials',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Override bundled credentials if you want to use your own developer registration.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretController,
                  decoration: const InputDecoration(
                    labelText: 'Client Secret',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(trackingPrefsProvider.notifier)
                          .setCustomCredentials(
                            type,
                            idController.text.trim(),
                            secretController.text.trim(),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Custom credentials saved for ${type.displayName}.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Save Credentials'),
                  ),
                ),
                const Divider(height: 28),
                Text(
                  'Manual Access Token Login',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If the OAuth browser does not redirect on your device, paste an Access Token directly below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (type == TrackerType.anilist) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(
                        text:
                            'https://anilist.co/api/v2/oauth/authorize?client_id=20815&response_type=token',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('AniList token URL copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Copy AniList Token Generation URL',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Access Token',
                    hintText: 'Paste OAuth Bearer Token',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: isSubmittingToken
                        ? null
                        : () async {
                            final rawToken = tokenController.text.trim();
                            if (rawToken.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please enter an access token.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setDialogState(() {
                              isSubmittingToken = true;
                            });
                            final allTrackers =
                                ref.read(availableTrackersProvider);
                            final tracker = allTrackers
                                .whereType<RemoteTracker>()
                                .cast<RemoteTracker?>()
                                .firstWhere(
                                  (t) => t?.type == type,
                                  orElse: () => null,
                                );
                            if (tracker == null) {
                              setDialogState(() {
                                isSubmittingToken = false;
                              });
                              return;
                            }
                            try {
                              await ref
                                  .read(authTokensProvider.notifier)
                                  .setToken(tracker, rawToken);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Successfully logged into ${type.displayName}!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setDialogState(() {
                                  isSubmittingToken = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Token login failed: $e'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmittingToken
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log In with Token'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final prefs = ref.watch(trackingPrefsProvider);
    final authTokens = ref.watch(authTokensProvider).value ?? {};
    final allTrackers = ref.watch(availableTrackersProvider);

    return AppScaffold(
      title: 'Tracking & Sync',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
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
                            'Incognito Mode temporarily prevents KuroX from updating your connected trackers while you browse, read, or watch.',
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
                            'With Auto Track Primary enabled, KuroX attempts to do that automatically whenever possible.',
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
                                : (!_hasCredentials(tracker.type)
                                      ? 'Missing API Credentials'
                                      : 'Not logged in'))
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
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.key_rounded, size: 20),
                                onPressed: () =>
                                    _showCredentialsDialog(tracker.type),
                                tooltip: 'Custom API Credentials',
                              ),
                              FilledButton.icon(
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
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_hasCredentials(tracker.type))
                                FilledButton.icon(
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                                  onPressed: () =>
                                      _showCredentialsDialog(tracker.type),
                                  icon: const Icon(Icons.key_off),
                                  label: const Text('Add Credentials'),
                                )
                              else ...[
                                IconButton(
                                  icon: const Icon(Icons.key_rounded, size: 20),
                                  onPressed: () =>
                                      _showCredentialsDialog(tracker.type),
                                  tooltip: 'Custom API Credentials & Token',
                                ),
                                Builder(
                                  builder: (context) {
                                    final isLoggingIn =
                                        _loggingInTrackers.contains(tracker.type);
                                    return FilledButton.icon(
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                      ),
                                      onPressed: isLoggingIn
                                          ? null
                                          : () => _handleLogin(tracker),
                                      icon: isLoggingIn
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                            )
                                          : const Icon(Icons.login),
                                      label: Text(isLoggingIn
                                          ? 'Logging in...'
                                          : 'Login'),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
