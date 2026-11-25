import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/network/doh/doh_provider.dart';
import 'package:shonenx/core/network/doh/doh_resolver.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_input_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/providers/app_lock_provider.dart';
import 'package:shonenx/shared/providers/doh_prefs_provider.dart';
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
    final dohPrefs = ref.watch(dohPrefsProvider);
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final bioCapabilityAsync = ref.watch(biometricCapabilityProvider);

    return AppScaffold(
      title: context.l10n.settingsSecurity,
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
                              ? context.l10n.securityAppLockActive
                              : context.l10n.securityAppLockDisabled,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prefs.isAppLockEnabled
                              ? (isMobile && prefs.useBiometrics
                                    ? context.l10n.securityProtectedPinBio
                                    : context.l10n.securityProtectedPin)
                              : context.l10n.securitySetupPinPrompt,
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
            title: context.l10n.securityAppLockSection,
            children: [
              SettingsSwitchTile(
                icon: Icons.lock_outline_rounded,
                title: context.l10n.securityEnableAppLock,
                subtitle: context.l10n.securityEnableAppLockSubtitle,
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
                      customTitle: context.l10n.securityDisableAppLock,
                      customSubtitle:
                          context.l10n.securityDisableAppLockSubtitle,
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
                  title: context.l10n.securityChangePin,
                  subtitle: context.l10n.securityChangePinSubtitle,
                  onTap: () async {
                    final changed = await PinInputSheet.show(
                      context: context,
                      flowType: PinFlowType.change,
                    );
                    if (changed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.securityPinUpdated),
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
                            title: context.l10n.securityBiometricUnlock,
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
                                            reason: context
                                                .l10n
                                                .securityConfirmBiometricsReason,
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
                              title: context.l10n.securityAutoPromptBiometrics,
                              subtitle: context
                                  .l10n
                                  .securityAutoPromptBiometricsSubtitle,
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
                  title: context.l10n.securityAutoLockTimeout,
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
            title: context.l10n.securityPrivacySection,
            children: [
              SettingsSwitchTile(
                icon: Icons.visibility_off_outlined,
                title: context.l10n.securityIncognitoMode,
                subtitle: context.l10n.securityIncognitoSubtitle,
                value: prefs.incognitoMode,
                onInfoCallback: () {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  final textTheme = theme.textTheme;

                  AppBottomSheet.show(
                    context: context,
                    title: context.l10n.securityIncognitoMode,
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
                                  context.l10n.securityIncognitoSheetHeading,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.securityIncognitoSheetBody,
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
                                    context.l10n.securityIncognitoSheetPauseNote,
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
                            context.l10n.securityIncognitoSheetFooter,
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

          // Network & DNS (DoH) Section
          SettingsSection(
            title: context.l10n.securityNetworkDnsSection,
            children: [
              SettingsDropdownTile<DohProvider>(
                icon: Icons.dns_outlined,
                title: context.l10n.securityDohTitle,
                subtitle: dohPrefs.provider.description,
                value: dohPrefs.provider,
                items: DohProvider.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.title)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(dohPrefsProvider.notifier).setProvider(val);
                  }
                },
                onInfoCallback: () => _showDohInfoSheet(context, ref),
              ),
            ],
          ),

          // Quick Actions Section
          if (prefs.isAppLockEnabled) ...[
            SettingsSection(
              title: context.l10n.securityActionsSection,
              children: [
                SettingsActionTile(
                  icon: Icons.lock_clock_outlined,
                  title: context.l10n.securityLockNow,
                  subtitle: context.l10n.securityLockNowSubtitle,
                  onTap: () {
                    ref.read(appLockProvider.notifier).lock();
                  },
                ),
                SettingsActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: context.l10n.securityResetTitle,
                  subtitle: context.l10n.securityResetSubtitle,
                  isDestructive: true,
                  onTap: () {
                    ConfirmationBottomSheet.show(
                      context,
                      title: context.l10n.securityResetTitle,
                      message: context.l10n.securityResetConfirmMessage,
                      confirmText: context.l10n.commonReset,
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
                              SnackBar(
                                content: Text(
                                  context.l10n.securitySettingsResetSnack,
                                ),
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

  void _showDohInfoSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    AppBottomSheet.show(
      context: context,
      title: l10n.securityDohTitle,
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
                Icon(Icons.dns_rounded, color: cs.primary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.securityDohSheetHeading,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.securityDohSheetBody,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.securityDohCloudflareNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.securityDohGoogleNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.securityDohSystemNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _DohTestWidget(),
          ],
        ),
      ),
    );
  }
}

class _DohTestWidget extends ConsumerStatefulWidget {
  const _DohTestWidget();

  @override
  ConsumerState<_DohTestWidget> createState() => _DohTestWidgetState();
}

class _DohTestWidgetState extends ConsumerState<_DohTestWidget> {
  bool _isTesting = false;
  DohTestResult? _result;

  Future<void> _runTest() async {
    setState(() {
      _isTesting = true;
      _result = null;
    });

    final currentProvider = ref.read(dohPrefsProvider).provider;
    final res = await DohResolver.instance.testLookup(
      provider: currentProvider,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _result = res;
      });
    }
  }

  void _clearDnsCache() {
    DohResolver.instance.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.securityDnsCacheFlushed),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dohPrefs = ref.watch(dohPrefsProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _isTesting ? null : _runTest,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.speed_rounded, size: 18),
                label: Text(
                  _isTesting ? l10n.securityTestingDns : l10n.securityTestDns,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: l10n.securityFlushDnsCache,
              onPressed: _clearDnsCache,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            ),
          ],
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _result!.success
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _result!.success
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _result!.success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: _result!.success ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.success
                            ? '${dohPrefs.provider.title} (${_result!.latencyMs} ms)'
                            : l10n.securityTestFailed,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _result!.success ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _result!.success
                            ? l10n.securityResolvedTo(
                                _result!.addresses.take(3).join(', '),
                              )
                            : (_result!.errorMessage ?? l10n.commonUnknown),
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
