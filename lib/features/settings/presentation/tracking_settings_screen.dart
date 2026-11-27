import 'dart:io';

import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/tracking/providers/tracker_auth_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_auth_mode.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  bool _hasCredentials(TrackerType type) {
    final prefs = ref.read(trackingPrefsProvider);
    final custom = prefs.customCredentials[type];
    if (custom != null && custom.clientId.trim().isNotEmpty) {
      return true;
    }
    switch (type) {
      case TrackerType.anilist:
        return Env.ANILIST_CLIENT_ID.isNotEmpty;
      case TrackerType.myanimelist:
        return Env.MAL_CLIENT_ID.isNotEmpty;
      case TrackerType.simkl:
        return Env.SIMKL_CLIENT_ID.isNotEmpty;
      case TrackerType.trakt:
        return Env.TRAKT_CLIENT_ID.isNotEmpty;
      default:
        return true;
    }
  }

  void _showCredentialsDialog(TrackerType type) {
    final prefs = ref.read(trackingPrefsProvider);
    final custom = prefs.customCredentials[type];
    final hasCustom =
        custom != null &&
        (custom.clientId.trim().isNotEmpty ||
            custom.clientSecret.trim().isNotEmpty);

    final idController = TextEditingController(text: custom?.clientId ?? '');
    final secretController = TextEditingController(
      text: custom?.clientSecret ?? '',
    );

    final l10n = context.l10n;
    AppDialog.show(
      context: context,
      title: l10n.trackingCredentialsTitle(type.displayName),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trackingCredentialsBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trackingActiveRedirectUri(prefs.authMode.displayName),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  type == TrackerType.trakt
                      ? 'https://roshancodespace.github.io/ShonenX/oauth/trakt/callback'
                      : (prefs.authMode == TrackerAuthMode.browser ||
                                (prefs.authMode == TrackerAuthMode.auto &&
                                    (Platform.isWindows || Platform.isLinux))
                            ? 'http://localhost:43824/success?code=1337'
                            : 'shonenx://callback'),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: idController,
            decoration: InputDecoration(
              labelText: l10n.trackingClientId,
              hintText: l10n.trackingLeaveEmptyDefault,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: secretController,
            decoration: InputDecoration(
              labelText: l10n.trackingClientSecret,
              hintText: l10n.trackingLeaveEmptyDefault,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        if (hasCustom)
          TextButton.icon(
            onPressed: () {
              ref
                  .read(trackingPrefsProvider.notifier)
                  .clearCustomCredentials(type);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.trackingCredentialsResetSnack(type.displayName),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.restore, size: 18),
            label: Text(l10n.commonReset),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final id = idController.text.trim();
            final secret = secretController.text.trim();
            if (id.isEmpty && secret.isEmpty) {
              ref
                  .read(trackingPrefsProvider.notifier)
                  .clearCustomCredentials(type);
            } else {
              ref
                  .read(trackingPrefsProvider.notifier)
                  .setCustomCredentials(type, id, secret);
            }
            Navigator.pop(context);
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final prefs = ref.watch(trackingPrefsProvider);
    final authTokens = ref.watch(authTokensProvider).value ?? {};
    final allTrackers = ref.watch(availableTrackersProvider);

    return AppScaffold(
      title: l10n.trackingSyncTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: l10n.settingsGeneral,
            children: [
              SettingsSegmentedTile<TrackerAuthMode>(
                title: l10n.trackingOAuthMethod,
                segments: [
                  ButtonSegment(
                    value: TrackerAuthMode.auto,
                    label: Text(l10n.trackingAuthAuto),
                    icon: const Icon(Icons.auto_mode_outlined),
                  ),
                  ButtonSegment(
                    value: TrackerAuthMode.browser,
                    label: Text(l10n.trackingAuthBrowser),
                    icon: const Icon(Icons.open_in_browser_outlined),
                  ),
                  ButtonSegment(
                    value: TrackerAuthMode.webview,
                    label: Text(l10n.trackingAuthWebview),
                    icon: const Icon(Icons.web_outlined),
                  ),
                ],
                selected: {prefs.authMode},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    ref
                        .read(trackingPrefsProvider.notifier)
                        .setAuthMode(set.first);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  prefs.authMode.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SettingsSliderTile(
                icon: Icons.percent,
                title: l10n.trackingSyncThreshold,
                subtitle: l10n.trackingSyncThresholdSubtitle(
                  (prefs.syncThreshold * 100).toInt().toString(),
                ),
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
            title: l10n.trackingAutomationSection,
            children: [
              SettingsSwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: l10n.trackingAutoLink,
                subtitle: l10n.trackingAutoLinkSubtitle,
                value: prefs.autoTrackPrimary,
                onInfoCallback: () {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  final textTheme = theme.textTheme;

                  AppBottomSheet.show(
                    context: context,
                    title: l10n.trackingAutoLink,
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
                                  l10n.trackingAutoLinkSheetHeading,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            l10n.trackingAutoLinkSheetBody,
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
                                    l10n.trackingAutoLinkSheetHighlight,
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
                                TextSpan(
                                  text: l10n.trackingBestResultsPrefix,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: l10n.trackingBestResultsBody,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            l10n.trackingAutoLinkFooter,
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
            title: l10n.trackingTrackersSection,
            children: allTrackers.map((tracker) {
              final cs = theme.colorScheme;
              final isRemote = tracker is RemoteTracker;
              final loadingTracker = ref.watch(authLoadingTrackerProvider);
              final isLoggingIn = isRemote && loadingTracker == tracker.type;

              final localProfile = tracker.type.getProfile(ref);
              final isLoggedIn = isRemote
                  ? (authTokens.containsKey(tracker.type) &&
                        localProfile != null)
                  : true;
              final isPrimary =
                  prefs.primaryTracker == tracker.type && !prefs.isIncognito;

              final profileName = isRemote
                  ? localProfile?.username
                  : (localProfile?.username != null &&
                            localProfile!.username != 'Guest'
                        ? localProfile.username
                        : l10n.trackingGuest);

              final badgeRadius = (GlobalUI.uiRoundness * 0.75).clamp(
                8.0,
                12.0,
              );
              final hasCreds = _hasCredentials(tracker.type);

              Widget leadingWidget;
              if (isLoggingIn) {
                leadingWidget = Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(badgeRadius),
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2.2, color: cs.primary),
                  ),
                );
              } else if (isRemote && isLoggedIn) {
                leadingWidget = Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(badgeRadius),
                    border: Border.all(
                      color: isPrimary ? cs.primary : cs.outlineVariant,
                      width: isPrimary ? 2 : 1,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(badgeRadius),
                    child: SmartImage(
                      imageUrl: localProfile?.avatarUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                );
              } else if (!isRemote && localProfile?.avatarUrl != null) {
                leadingWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(badgeRadius),
                  child: TrackerAvatarWidget(
                    imageUrl: localProfile!.avatarUrl,
                    size: 40,
                  ),
                );
              } else {
                leadingWidget = Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(badgeRadius),
                  ),
                  child: isRemote
                      ? tracker.type.getIconWidget(
                          size: 21,
                          color: isPrimary
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        )
                      : Icon(
                          Icons.cloud_off_rounded,
                          size: 20,
                          color: isPrimary
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                );
              }

              Widget trailingWidget;
              if (isLoggingIn) {
                trailingWidget = FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(badgeRadius),
                    ),
                  ),
                  onPressed: null,
                  icon: SizedBox(
                    width: 14,
                    height: 14,
                    child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2, color: cs.onSurfaceVariant),
                  ),
                  label: Text(l10n.trackingLoggingIn),
                );
              } else if (!isRemote || isLoggedIn) {
                trailingWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.key_rounded, size: 20),
                      onPressed: () => _showCredentialsDialog(tracker.type),
                      tooltip: l10n.trackingCustomApiCredsTooltip,
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(badgeRadius),
                        ),
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) =>
                            TrackerProfileSheet(trackerType: tracker.type),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      tooltip: l10n.settingsCustomize,
                    ),
                  ],
                );
              } else if (!hasCreds) {
                trailingWidget = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.errorContainer,
                    foregroundColor: cs.onErrorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(badgeRadius),
                    ),
                  ),
                  onPressed: () => _showCredentialsDialog(tracker.type),
                  icon: const Icon(Icons.key_off_rounded, size: 18),
                  label: Text(l10n.trackingAddCredentials),
                );
              } else {
                trailingWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.key_rounded, size: 20),
                      onPressed: () => _showCredentialsDialog(tracker.type),
                      tooltip: l10n.trackingCustomApiCredsTooltip,
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(badgeRadius),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(authTokensProvider.notifier)
                              .login(tracker);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: cs.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(l10n.trackingLogin),
                    ),
                  ],
                );
              }

              return AbsorbPointer(
                absorbing: prefs.isIncognito || isLoggingIn,
                child: Opacity(
                  opacity: prefs.isIncognito ? 0.5 : 1.0,
                  child: SettingsCustomTile(
                    color: isPrimary
                        ? Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.12),
                            cs.surfaceContainerHigh,
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    onTap: isLoggingIn
                        ? null
                        : () {
                            ref
                                .read(trackingPrefsProvider.notifier)
                                .setPrimaryTracker(tracker.type);
                          },
                    child: Row(
                      children: [
                        leadingWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      tracker.type.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isPrimary
                                                ? cs.primary
                                                : cs.onSurface,
                                          ),
                                    ),
                                  ),
                                  if (isPrimary) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.trackingPrimaryBadge
                                            .replaceAll('(', '')
                                            .replaceAll(')', '')
                                            .trim(),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: cs.onPrimaryContainer,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                              height: 1.1,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (isLoggingIn)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2, color: cs.primary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.trackingLoggingIn,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: cs.primary,
                                          ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    if (isLoggedIn) ...[
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: isPrimary
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Flexible(
                                      child: Text(
                                        isRemote
                                            ? (isLoggedIn
                                                  ? l10n.trackingLoggedInAs(
                                                      profileName ?? '',
                                                    )
                                                  : (!hasCreds
                                                        ? l10n.trackingMissingApiCreds
                                                        : l10n.trackingNotLoggedIn))
                                            : l10n.trackingLoggedInAs(
                                                profileName ?? '',
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: isLoggedIn
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: !hasCreds
                                                  ? cs.error
                                                  : (isPrimary
                                                        ? cs.onPrimaryContainer
                                                        : cs.onSurfaceVariant),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        trailingWidget,
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This product uses the Trakt API but is not endorsed or certified by Trakt.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://github.com/roshancodespace/ShonenX/blob/main/docs/privacy-policy.md',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Privacy Policy',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
