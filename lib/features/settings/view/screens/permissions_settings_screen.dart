import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/utils/permissions.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class PermissionsSettingsScreen extends ConsumerStatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  ConsumerState<PermissionsSettingsScreen> createState() =>
      _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState
    extends ConsumerState<PermissionsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                if (Platform.isAndroid)
                  ToggleableSettingsItem(
                    icon: Icon(Iconsax.folder_open, color: colorScheme.primary),
                    accent: colorScheme.primary,
                    title: 'Storage Access',
                    description: 'Allow access to storage to download anime.',
                    value: Permissions.storage,
                    onChanged: (val) async {
                      if (val == false) return;
                      await Permissions.requestStoragePermission();
                      setState(() {});
                    },
                  ),
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.notification, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Notification Access',
                  description:
                      'Allow access to notifications to get notified about new anime news.',
                  value: Permissions.notification,
                  onChanged: (val) async {
                    if (val == false) return;
                    await Permissions.requestNotificationPermission();
                    setState(() {});
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
