import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_2, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Customize Your Experience',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                SettingsSection(
                  context: context,
                  title: 'Account',
                  items: [
                    SettingsItem(
                      icon: Iconsax.user,
                      title: 'Profile Settings',
                      description: 'AniList integration, account preferences',
                      onTap: () => context.push('/settings/profile'),
                    ),
                  ],
                ),
                SettingsSection(
                  context: context,
                  title: 'Content & Playback',
                  items: [
                    SettingsItem(
                      icon: Iconsax.video_play,
                      title: 'Video Player',
                      description: 'Playback settings, subtitles configuration',
                      onTap: () => context.push('/settings/player'),
                    ),
                    SettingsItem(
                      icon: Iconsax.play,
                      title: 'Anime Sources',
                      description: 'Manage content providers',
                      onTap: () => context.push('/settings/providers'),
                    ),
                  ],
                ),
                SettingsSection(
                  context: context,
                  title: 'Appearance',
                  items: [
                    SettingsItem(
                      icon: Iconsax.brush_2,
                      title: 'Theme Settings',
                      description: 'Customize app colors and appearance',
                      onTap: () => context.push('/settings/theme'),
                    ),
                    SettingsItem(
                      icon: Iconsax.square,
                      title: 'UI Settings',
                      description: 'Customize the interface and layout',
                      onTap: () => context.push('/settings/ui'),
                    ),
                  ],
                ),
                SettingsSection(
                  context: context,
                  title: 'Support',
                  items: [
                    SettingsItem(
                      icon: Iconsax.message_question,
                      title: 'Help Center',
                      description: 'FAQs and support resources',
                      onTap: () => context.push('/settings/support'),
                    ),
                    SettingsItem(
                      icon: Iconsax.info_circle,
                      title: 'About',
                      description: 'App information and licenses',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  
}
