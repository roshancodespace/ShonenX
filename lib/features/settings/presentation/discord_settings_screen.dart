import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/discord/models/discord_rpc_custom_settings.dart';
import 'package:shonenx/features/discord/presentation/discord_login_page.dart';
import 'package:shonenx/features/discord/presentation/widgets/discord_rpc_preview_card.dart';
import 'package:shonenx/features/discord/providers/discord_provider.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DiscordSettingsScreen extends ConsumerWidget {
  const DiscordSettingsScreen({super.key});

  void _showEditIdleSheet(
    BuildContext context,
    WidgetRef ref,
    DiscordRpcCustomSettings settings,
  ) {
    final activityController = TextEditingController(
      text: settings.idleActivity,
    );
    final detailsController = TextEditingController(text: settings.idleDetails);
    final l10n = context.l10n;

    AppBottomSheet.show(
      context: context,
      title: l10n.discordEditIdleTitle,
      titleIcon: Icons.edit_note_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: activityController,
            decoration: InputDecoration(
              labelText: l10n.discordActivityName,
              hintText: 'e.g. Glazing ShonenX',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: detailsController,
            decoration: InputDecoration(
              labelText: l10n.discordDetailsSubtitle,
              hintText: 'e.g. Browsing Catalog',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final newActivity = activityController.text.trim();
              final newDetails = detailsController.text.trim();
              ref
                  .read(discordRpcProvider.notifier)
                  .updateCustomSettings(
                    settings.copyWith(
                      idleActivity: newActivity.isNotEmpty
                          ? newActivity
                          : 'Glazing ShonenX',
                      idleDetails: newDetails.isNotEmpty
                          ? newDetails
                          : 'Browsing Catalog',
                    ),
                  );
              Navigator.of(context).pop();
            },
            child: Text(l10n.discordSaveChanges),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    AppDialog.show(
      context: context,
      title: l10n.discordDisconnectTitle,
      icon: Icon(
        Icons.logout_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(l10n.discordDisconnectMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            ref.read(discordProvider.notifier).logout();
            Navigator.of(context).pop();
          },
          child: Text(l10n.discordDisconnectAction),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discordState = ref.watch(discordProvider);
    final rpcState = ref.watch(discordRpcProvider);
    final settings = rpcState.customSettings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsDiscordRpc,
      subtitle: l10n.settingsDiscordRpcSubtitle,
      body: discordState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                if (discordState.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: cs.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              discordState.error!,
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: discordState.isLoggedIn
                        ? Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF5865F2),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: discordState.user?.avatarUrl != null
                                      ? SmartImage(
                                          imageUrl:
                                              discordState.user!.avatarUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.person),
                                        )
                                      : const Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      discordState.user?.displayName ??
                                          l10n.discordUserFallback,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${discordState.user?.username ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: rpcState.isConnected
                                                ? const Color(0xFF23A55A)
                                                : Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          rpcState.isConnected
                                              ? l10n.discordActiveSynced
                                              : l10n.discordConnected,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF23A55A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: l10n.discordRefreshProfile,
                                onPressed: () {
                                  if (discordState.token != null) {
                                    ref
                                        .read(discordProvider.notifier)
                                        .loginWithToken(discordState.token!);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.logout_rounded,
                                  color: cs.error,
                                ),
                                tooltip: l10n.discordDisconnectAction,
                                onPressed: () =>
                                    _confirmDisconnect(context, ref),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF5865F2,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.discord,
                                      color: Color(0xFF5865F2),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.discordRichPresenceTitle,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          l10n.discordShareActivity,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.discordDesktopAutoConnectNote,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5865F2),
                                    side: const BorderSide(
                                      color: Color(0xFF5865F2),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.key_rounded, size: 18),
                                  label: Text(
                                    l10n.discordSignInButton,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.showDiscordLogin((token) async {
                                      await ref
                                          .read(discordProvider.notifier)
                                          .loginWithToken(token);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SettingsSection(
                  title: l10n.discordPresenceControl,
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.discord,
                      title: l10n.discordEnableRpc,
                      subtitle: l10n.discordEnableRpcSubtitle,
                      value: rpcState.isEnabled,
                      onChanged: (value) {
                        ref
                            .read(discordRpcProvider.notifier)
                            .toggleEnabled(value);
                      },
                    ),
                  ],
                ),

                if (rpcState.isEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DiscordRpcPreviewCard(
                      user: discordState.user,
                      settings: settings,
                    ),
                  ),

                if (rpcState.isEnabled)
                  SettingsSection(
                    title: l10n.discordActivityBroadcasting,
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.art_track_rounded,
                        title: l10n.discordShowDetailsActivity,
                        subtitle: l10n.discordShowDetailsActivitySubtitle(
                          '{Title}',
                        ),
                        value: settings.enableDetailsPresence,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(enableDetailsPresence: val),
                              );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.play_circle_outline_rounded,
                        title: l10n.discordShowPlayerActivity,
                        subtitle: l10n.discordShowPlayerActivitySubtitle,
                        value: settings.enablePlayerPresence,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(enablePlayerPresence: val),
                              );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.menu_book_rounded,
                        title: l10n.discordShowReaderActivity,
                        subtitle: l10n.discordShowReaderActivitySubtitle,
                        value: settings.enableReaderPresence,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(enableReaderPresence: val),
                              );
                        },
                      ),
                    ],
                  ),

                if (rpcState.isEnabled)
                  SettingsSection(
                    title: l10n.discordPresenceCustomization,
                    children: [
                      SettingsActionTile(
                        icon: Icons.edit_note_rounded,
                        title: l10n.discordIdleActivityStatus,
                        subtitle:
                            '${settings.idleActivity} • ${settings.idleDetails}',
                        onTap: () => _showEditIdleSheet(context, ref, settings),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.numbers_rounded,
                        title: l10n.discordShowEpisodeNumbers,
                        subtitle: l10n.discordShowEpisodeNumbersSubtitle,
                        value: settings.showEpisodeNumber,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(showEpisodeNumber: val),
                              );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.timer_outlined,
                        title: l10n.discordShowProgress,
                        subtitle: l10n.discordShowProgressSubtitle,
                        value: settings.showProgress,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(showProgress: val),
                              );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.image_outlined,
                        title: l10n.discordShowMediaImages,
                        subtitle: l10n.discordShowMediaImagesSubtitle,
                        value: settings.showMediaImage,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(showMediaImage: val),
                              );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.smart_button_rounded,
                        title: l10n.discordShowViewButtons,
                        subtitle: l10n.discordShowViewButtonsSubtitle,
                        value: settings.showButtons,
                        onChanged: (val) {
                          ref
                              .read(discordRpcProvider.notifier)
                              .updateCustomSettings(
                                settings.copyWith(showButtons: val),
                              );
                        },
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
