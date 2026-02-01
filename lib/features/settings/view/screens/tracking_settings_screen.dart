import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
  }

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
              ValueListenableBuilder(
                valueListenable: _settingsBox.listenable(
                  keys: ['tracking_sync_anilist'],
                ),
                builder: (context, box, _) {
                  final enabled = box.get(
                    'tracking_sync_anilist',
                    defaultValue: true,
                  );
                  return ToggleableSettingsItem(
                    icon: Icon(
                      Iconsax.archive_book,
                      color: colorScheme.primary,
                    ),
                    accent: colorScheme.primary,
                    title: 'AniList',
                    description: 'Sync progress with AniList',
                    value: enabled,
                    onChanged: (val) {
                      box.put('tracking_sync_anilist', val);
                    },
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _settingsBox.listenable(
                  keys: ['tracking_sync_mal'],
                ),
                builder: (context, box, _) {
                  final enabled = box.get(
                    'tracking_sync_mal',
                    defaultValue: true,
                  );
                  return ToggleableSettingsItem(
                    icon: Icon(Iconsax.book, color: colorScheme.secondary),
                    accent: colorScheme.secondary,
                    title: 'MyAnimeList',
                    description: 'Sync progress with MyAnimeList',
                    value: enabled,
                    onChanged: (val) {
                      box.put('tracking_sync_mal', val);
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Preferences',
            titleColor: colorScheme.primary,
            children: [
              ValueListenableBuilder(
                valueListenable: _settingsBox.listenable(
                  keys: ['tracking_ask_update_on_start'],
                ),
                builder: (context, box, _) {
                  final askUpdate = box.get(
                    'tracking_ask_update_on_start',
                    defaultValue: false,
                  );
                  return ToggleableSettingsItem(
                    icon: Icon(
                      Iconsax.message_question,
                      color: colorScheme.primary,
                    ),
                    accent: colorScheme.primary,
                    title: 'Update prompt',
                    description: 'Always ask before syncing progress',
                    value: askUpdate,
                    onChanged: (val) {
                      box.put('tracking_ask_update_on_start', val);
                    },
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
