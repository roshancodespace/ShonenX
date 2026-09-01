import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_input_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/providers/app_lock_provider.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/confirmation_bottom_sheet.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = ref.watch(securityPrefsProvider);
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final bioCapabilityAsync = ref.watch(biometricCapabilityProvider);

    return AppScaffold(
      title: 'Security & Privacy',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          // Security Status Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(
                      alpha: prefs.isAppLockEnabled ? 0.18 : 0.08,
                    ),
                    cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color:
                      (prefs.isAppLockEnabled ? cs.primary : cs.outlineVariant)
                          .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (prefs.isAppLockEnabled
                                  ? cs.primary
                                  : cs.surfaceContainerHighest)
                              .withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      prefs.isAppLockEnabled
                          ? Icons.shield_rounded
                          : Icons.shield_outlined,
                      size: 28,
                      color: prefs.isAppLockEnabled
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prefs.isAppLockEnabled
                              ? 'App Lock is Active'
                              : 'App Lock is Disabled',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prefs.isAppLockEnabled
                              ? (isMobile && prefs.useBiometrics
                                    ? 'Protected with PIN & Biometrics'
                                    : 'Protected with 4-digit PIN')
                              : 'Set up a PIN to protect your data.',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // App Lock Section
          SettingsSection(
            title: 'App Lock',
            children: [
              SettingsSwitchTile(
                icon: Icons.lock_outline_rounded,
                title: 'Enable App Lock',
                subtitle: 'Require authentication to open ShonenX',
                value: prefs.isAppLockEnabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    // Check if PIN exists
                    if (!prefs.hasPin) {
                      final success = await PinInputSheet.show(
                        context: context,
                        flowType: PinFlowType.setup,
                      );
                      if (success == true) {
                        await ref
                            .read(securityPrefsProvider.notifier)
                            .refreshPinStatus();
                        await ref
                            .read(securityPrefsProvider.notifier)
                            .setAppLockEnabled(true);
                      }
                    } else {
                      await ref
                          .read(securityPrefsProvider.notifier)
                          .setAppLockEnabled(true);
                    }
                  } else {
                    // Confirm with PIN before disabling
                    final verified = await PinInputSheet.show(
                      context: context,
                      flowType: PinFlowType.verify,
                      customTitle: 'Disable App Lock',
                      customSubtitle: 'Enter your PIN to turn off app lock',
                    );
                    if (verified == true) {
                      await ref
                          .read(securityPrefsProvider.notifier)
                          .setAppLockEnabled(false);
                    }
                  }
                },
              ),

              if (prefs.isAppLockEnabled) ...[
                SettingsNavTile(
                  icon: Icons.pin_outlined,
                  title: 'Change PIN',
                  subtitle: 'Update your 4-digit security PIN',
                  onTap: () async {
                    final changed = await PinInputSheet.show(
                      context: context,
                      flowType: PinFlowType.change,
                    );
                    if (changed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN updated successfully'),
                        ),
                      );
                    }
                  },
                ),

                if (isMobile)
                  bioCapabilityAsync.when(
                    data: (capability) {
                      final isSupported = capability.canAuthenticate;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SettingsSwitchTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Biometric Unlock',
                            subtitle: capability.hardwareDescription,
                            value: prefs.useBiometrics && isSupported,
                            onChanged: isSupported
                                ? (useBio) async {
                                    if (useBio) {
                                      // Authenticate once to confirm biometric enrollment works
                                      final securityService = ref.read(
                                        securityServiceProvider,
                                      );
                                      final success = await securityService
                                          .authenticateBiometrics(
                                            reason:
                                                'Confirm biometrics to enable unlock',
                                          );
                                      if (success) {
                                        await ref
                                            .read(
                                              securityPrefsProvider.notifier,
                                            )
                                            .setUseBiometrics(true);
                                      }
                                    } else {
                                      await ref
                                          .read(securityPrefsProvider.notifier)
                                          .setUseBiometrics(false);
                                    }
                                  }
                                : null,
                          ),
                          if (prefs.useBiometrics && isSupported)
                            SettingsSwitchTile(
                              icon: Icons.flash_on_outlined,
                              title: 'Auto-prompt Biometrics',
                              subtitle:
                                  'Immediately show prompt when opening app',
                              value: prefs.autoPromptBiometrics,
                              onChanged: (val) {
                                ref
                                    .read(securityPrefsProvider.notifier)
                                    .setAutoPromptBiometrics(val);
                              },
                            ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                SettingsDropdownTile<LockTimeout>(
                  icon: Icons.timer_outlined,
                  title: 'Auto-Lock Timeout',
                  value: prefs.lockTimeout,
                  items: LockTimeout.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(securityPrefsProvider.notifier)
                          .setLockTimeout(val);
                    }
                  },
                ),
              ],
            ],
          ),

          // Privacy Section
          SettingsSection(
            title: 'Privacy',
            children: [
              SettingsSwitchTile(
                icon: Icons.visibility_off_outlined,
                title: 'Incognito Mode',
                subtitle:
                    'Pause watch history, read history, and cloud tracking',
                value: prefs.incognitoMode,
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
                                  'Private Viewing & Reading',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Incognito Mode prevents ShonenX from saving your watch progress, read history, or syncing activity to your connected trackers (MAL, AniList, etc.).',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
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
                                    'Watch history, read chapters, and cloud tracker updates are paused until disabled.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Your tracker accounts and existing history remain intact. Normal syncing and history resume when Incognito Mode is turned off.',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onChanged: (val) {
                  ref
                      .read(securityPrefsProvider.notifier)
                      .setIncognitoMode(val);
                },
              ),
            ],
          ),

          // Quick Actions Section
          if (prefs.isAppLockEnabled) ...[
            SettingsSection(
              title: 'Actions',
              children: [
                SettingsActionTile(
                  icon: Icons.lock_clock_outlined,
                  title: 'Lock App Now',
                  subtitle: 'Instantly lock the app to test security',
                  onTap: () {
                    ref.read(appLockProvider.notifier).lock();
                  },
                ),
                SettingsActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Reset Security Settings',
                  subtitle: 'Clear PIN and remove all lock preferences',
                  isDestructive: true,
                  onTap: () {
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Reset Security Settings',
                      message:
                          'This will remove your PIN and disable app lock. Are you sure?',
                      confirmText: 'Reset',
                      isDestructive: true,
                      onConfirm: () async {
                        final verified = await PinInputSheet.show(
                          context: context,
                          flowType: PinFlowType.remove,
                        );
                        if (verified == true && context.mounted) {
                          await ref
                              .read(securityPrefsProvider.notifier)
                              .disableAppLock();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Security settings reset'),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
