import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/main.dart';

class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Tracking & Sync'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsSection(
            title: 'Services',
            titleColor: colorScheme.primary,
            children: [
              ToggleableSettingsItem(
                icon: Icon(Iconsax.archive_book, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'AniList',
                description: 'Sync progress with AniList',
                value: sharedPrefs.getBool('tracking_sync_anilist') ?? true,
                onChanged: (val) {
                  setState(() {
                    sharedPrefs.setBool('tracking_sync_anilist', val);
                  });
                },
              ),
              ToggleableSettingsItem(
                icon: Icon(Iconsax.book, color: colorScheme.secondary),
                accent: colorScheme.secondary,
                title: 'MyAnimeList',
                description: 'Sync progress with MyAnimeList',
                value: sharedPrefs.getBool('tracking_sync_mal') ?? true,
                onChanged: (val) {
                  setState(() {
                    sharedPrefs.setBool('tracking_sync_mal', val);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Preferences',
            titleColor: colorScheme.primary,
            children: [
              ToggleableSettingsItem(
                icon: Icon(
                  Iconsax.message_question,
                  color: colorScheme.primary,
                ),
                accent: colorScheme.primary,
                title: 'Update prompt',
                description: 'Always ask before syncing progress',
                value:
                    sharedPrefs.getBool('tracking_ask_update_on_start') ??
                    false,
                onChanged: (val) {
                  setState(() {
                    sharedPrefs.setBool('tracking_ask_update_on_start', val);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
