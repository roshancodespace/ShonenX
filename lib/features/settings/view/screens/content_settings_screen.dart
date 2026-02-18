import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/shared/providers/settings/content_settings_notifier.dart';

class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(contentSettingsProvider);
    final notifier = ref.read(contentSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: Text(
          'Content Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: SettingsSection(
          title: 'Content Preferences',
          titleColor: colorScheme.primary,
          children: [
            ToggleableSettingsItem(
              title: 'Show Adult Content (AniList)',
              description: 'Include 18+ content in AniList results',
              icon: Icon(Iconsax.danger, color: colorScheme.primary),
              accent: colorScheme.primary,
              value: settings.showAnilistAdult,
              onChanged: (val) {
                notifier.updateSettings(
                  (s) => s.copyWith(showAnilistAdult: val),
                );
                ref
                    .read(homepageProvider.notifier)
                    .initialize(forceRefresh: true);
              },
            ),
            ToggleableSettingsItem(
              title: 'Show Adult Content (MAL)',
              description: 'Include 18+ content in MyAnimeList results',
              icon: Icon(Iconsax.danger, color: colorScheme.secondary),
              accent: colorScheme.secondary,
              value: settings.showMalAdult,
              onChanged: (val) {
                notifier.updateSettings((s) => s.copyWith(showMalAdult: val));
                ref
                    .read(homepageProvider.notifier)
                    .initialize(forceRefresh: true);
              },
            ),
            ToggleableSettingsItem(
              title: 'Smart Source Persistence',
              description:
                  'Remember and auto-apply the last used source for each anime',
              icon: Icon(Iconsax.flash_1, color: colorScheme.tertiary),
              accent: colorScheme.tertiary,
              value: settings.smartSourceEnabled,
              onChanged: (val) => notifier.updateSettings(
                (s) => s.copyWith(smartSourceEnabled: val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
