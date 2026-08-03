import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    AppBottomSheet.show(
      context: context,
      title: 'Customize Idle RPC Status',
      titleIcon: Icons.edit_note_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: activityController,
            decoration: const InputDecoration(
              labelText: 'Activity Name',
              hintText: 'e.g. Glazing ShonenX',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: detailsController,
            decoration: const InputDecoration(
              labelText: 'Details / Subtitle',
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
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    AppDialog.show(
      context: context,
      title: 'Disconnect Discord Account',
      icon: Icon(
        Icons.logout_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: const Text(
        'Are you sure you want to disconnect your Discord account? Your saved account token will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            ref.read(discordProvider.notifier).logout();
            Navigator.of(context).pop();
          },
          child: const Text('Disconnect'),
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

    return AppScaffold(
      title: 'Discord RPC',
      subtitle: 'Send rich presence to Discord',
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
                                      ? CachedNetworkImage(
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
                                          'Discord User',
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
                                              ? 'Active & Synced'
                                              : 'Connected',
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
                                tooltip: 'Refresh Profile',
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
                                tooltip: 'Disconnect',
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
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Discord Rich Presence',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Share your watch & read activity',
                                          style: TextStyle(
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
                                'Desktop users connect automatically via the running Discord app. Signing in with a user token is optional (for mobile/gateway sync).',
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
                                  label: const Text(
                                    'Sign in with Discord Account',
                                    style: TextStyle(
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
                  title: 'Presence Control',
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.discord,
                      title: 'Enable Discord RPC',
                      subtitle:
                          'Broadcast anime watching & manga reading activity',
                      value: rpcState.isEnabled,
                      onChanged: (value) {
                        ref
                            .read(discordRpcProvider.notifier)
                            .toggleEnabled(value);
                      },
                    ),
                    if (rpcState.isEnabled)
                      SettingsActionTile(
                        icon: Icons.edit_note_rounded,
                        title: 'Idle Activity Status',
                        subtitle:
                            '${settings.idleActivity} • ${settings.idleDetails}',
                        onTap: () => _showEditIdleSheet(context, ref, settings),
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
                    title: 'Activity Broadcasting',
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.art_track_rounded,
                        title: 'Show Details Screen Activity',
                        subtitle:
                            'Display "Viewing {Title}" when inspecting anime/manga',
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
                        title: 'Show Video Player Activity',
                        subtitle:
                            'Display "Watching Episode X" while playing anime',
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
                        title: 'Show Manga Reader Activity',
                        subtitle:
                            'Display "Reading Chapter X" while reading manga',
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
              ],
            ),
    );
  }
}
