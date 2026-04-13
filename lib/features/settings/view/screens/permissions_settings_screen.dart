import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/shared/providers/permissions_provider.dart';

class PermissionsSettingsScreen extends ConsumerWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final permissionsState = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Permissions'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ListView(
          children: [
            SettingsSection(
              title: 'Access Management',
              titleColor: colorScheme.primary,
              onTap: () {},
              children: [
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.folder_open, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Storage Access',
                  description: 'Allow access to storage to download anime.',
                  value: permissionsState.storage,
                  onChanged: (val) async {
                    if (val == false) return;
                    await ref
                        .read(permissionsProvider.notifier)
                        .requestStoragePermission();
                  },
                ),
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.notification, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Notification Access',
                  description:
                      'Allow access to notifications to get notified about new anime news.',
                  value: permissionsState.notification,
                  onChanged: (val) async {
                    if (val == false) return;
                    await ref
                        .read(permissionsProvider.notifier)
                        .requestNotificationPermission();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
