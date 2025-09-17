import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';
import 'package:shonenx/features/settings/widgets/settings_section.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final experimental = ref.watch(experimentalProvider);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
              onPressed: () => context.pop(), icon: Icon(Iconsax.arrow_left_2)),
          title: const Text('Settings'),
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              SettingsSection(
                  title: 'Account',
                  titleColor: colorScheme.primary,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: Icon(Iconsax.user, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Profile Settings',
                      description: 'AniList integration, account preferences',
                      onTap: () => context.push('/settings/account'),
                    ),
                  ]),
              const SizedBox(height: 10),
              SettingsSection(
                  title: 'Content & Playback',
                  titleColor: colorScheme.primary,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: Icon(Icons.source_outlined,
                          color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Anime Sources',
                      description: 'Manage anime content providers',
                      onTap: () => context.push('/settings/anime-sources'),
                    ),
                    if (experimental.useMangayomiExtensions)
                      SettingsItem(
                        icon: Icon(Icons.extension_outlined,
                            color: colorScheme.primary),
                        accent: colorScheme.primary,
                        title: 'Extensions (💀)',
                        description: 'Manage your extensions',
                        onTap: () => context.push('/settings/extensions'),
                      ),
                    SettingsItem(
                      icon:
                          Icon(Iconsax.video_play, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Video Player',
                      description: 'Manage video player settings',
                      onTap: () => context.push('/settings/player'),
                    ),
                  ]),
              const SizedBox(height: 10),
              SettingsSection(
                  title: 'Appearance',
                  titleColor: colorScheme.primary,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon:
                          Icon(Iconsax.paintbucket, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Theme Settings',
                      description: 'Customize app colors and appearance',
                      onTap: () => context.push('/settings/theme'),
                    ),
                    SettingsItem(
                      icon: Icon(Iconsax.mobile, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'UI Settings',
                      description: 'Customize the interface and layout',
                      onTap: () => context.push('/settings/ui'),
                    ),
                  ]),
              const SizedBox(height: 10),
              SettingsSection(
                  title: 'Support',
                  titleColor: colorScheme.primary,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon:
                          Icon(Iconsax.info_circle, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'About',
                      description: 'App information and licenses',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ]),
              const SizedBox(height: 20),
              SettingsSection(
                  title: 'Misc',
                  titleColor: colorScheme.primary,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon:
                          Icon(Iconsax.info_circle, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Experimental',
                      description: 'Few extra features',
                      onTap: () => context.push('/settings/experimental'),
                    ),
                  ]),
            ],
          ),
        ));
  }
}
