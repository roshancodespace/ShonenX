import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view/widgets/settings_items/toggleable_settings_item.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';

class ContentSettingsSection extends ConsumerWidget {
  const ContentSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(contentSettingsProvider);
    final notifier = ref.read(contentSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
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
            ref.read(homepageProvider.notifier).initialize(forceRefresh: true);
          },
        ),
        ToggleableSettingsItem(
          title: 'Show Adult Content (MAL)',
          description: 'Include 18+ content in MyAnimeList results',
          icon: Icon(Iconsax.danger, color: colorScheme.secondary),
          accent: colorScheme.secondary,
          value: settings.showMalAdult,
          onChanged: (val) {
            notifier.updateSettings(
              (s) => s.copyWith(showMalAdult: val),
            );
            ref.read(homepageProvider.notifier).initialize(forceRefresh: true);
          },
        ),
      ],
    );
  }
}
