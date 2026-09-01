import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/security/domain/security_prefs.dart';
import 'package:shonenx/features/security/presentation/app_lock_screen.dart';
import 'package:shonenx/features/security/providers/security_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityPrefs = ref.watch(securityPrefsProvider);
    final notifier = ref.read(securityPrefsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Privacy'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // App Lock Section
          SettingsSectionHeader(title: 'App Protection'),
          SettingsSwitchTile(
            icon: Icons.lock_outline_rounded,
            title: 'Native App Lock',
            subtitle: securityPrefs.isLockEnabled
                ? 'PIN lock is active'
                : 'Protect ShonenX with a 4-digit PIN',
            value: securityPrefs.isLockEnabled,
            onChanged: (val) async {
              if (val) {
                // Open PIN creation screen
                final success = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AppLockScreen(mode: AppLockMode.setup),
                  ),
                );
                if (success != true) {
                  notifier.updatePrefs(securityPrefs.copyWith(isLockEnabled: false));
                }
              } else {
                // Verify before disabling
                final success = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AppLockScreen(mode: AppLockMode.unlock),
                  ),
                );
                if (success == true) {
                  await notifier.removePin();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Lock disabled.')),
                    );
                  }
                }
              }
            },
          ),

          if (securityPrefs.isLockEnabled) ...[
            SettingsActionTile(
              icon: Icons.password_rounded,
              title: 'Change PIN',
              subtitle: 'Update your 4-digit security PIN',
              onTap: () async {
                final verified = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AppLockScreen(mode: AppLockMode.unlock),
                  ),
                );
                if (verified == true && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AppLockScreen(mode: AppLockMode.setup),
                    ),
                  );
                }
              },
            ),
            SettingsActionTile(
              icon: Icons.timer_outlined,
              title: 'Auto-Lock Timeout',
              subtitle: _getTimeoutLabel(securityPrefs.autoLockDelaySeconds),
              onTap: () {
                _showTimeoutSelector(context, ref, securityPrefs);
              },
            ),
          ],

          const SizedBox(height: 16),
          // Privacy Section
          SettingsSectionHeader(title: 'Privacy & History'),
          SettingsSwitchTile(
            icon: Icons.visibility_off_outlined,
            title: 'Incognito Mode',
            subtitle:
                'Temporarily pause saving watch/read history and tracker synchronizations',
            value: securityPrefs.incognitoMode,
            onChanged: (val) {
              notifier.toggleIncognito(val);
              ScognitoSnackbar(context, val);
            },
          ),
          SettingsSwitchTile(
            icon: Icons.security_rounded,
            title: 'Hide in App Switcher',
            subtitle: 'Blur or hide app preview in recent applications view',
            value: securityPrefs.hideContentInAppSwitcher,
            onChanged: (val) {
              notifier.updatePrefs(
                securityPrefs.copyWith(hideContentInAppSwitcher: val),
              );
            },
          ),

          const SizedBox(height: 24),
          // Information Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App Lock PIN is stored securely in encrypted storage on your device. It is never transmitted to external servers.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  static void ScognitoSnackbar(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Incognito Mode activated (History paused)'
              : 'Incognito Mode deactivated',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getTimeoutLabel(int seconds) {
    switch (seconds) {
      case 0:
        return 'Immediately';
      case 60:
        return '1 minute';
      case 300:
        return '5 minutes';
      case 900:
        return '15 minutes';
      case 1800:
        return '30 minutes';
      default:
        return '$seconds seconds';
    }
  }

  void _showTimeoutSelector(
    BuildContext context,
    WidgetRef ref,
    SecurityPrefs currentPrefs,
  ) {
    const timeouts = [0, 60, 300, 900, 1800];
    AppBottomSheet.showSelector<int>(
      context: context,
      title: 'Auto-Lock Delay',
      items: timeouts,
      selectedValue: currentPrefs.autoLockDelaySeconds,
      itemLabel: (item) => _getTimeoutLabel(item),
      onChanged: (item) {
        ref.read(securityPrefsProvider.notifier).updatePrefs(
              currentPrefs.copyWith(autoLockDelaySeconds: item),
            );
      },
    );
  }
}
