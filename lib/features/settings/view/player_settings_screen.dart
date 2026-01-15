import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final playerSettings = ref.watch(playerSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Video Player'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            SettingsSection(
              title: 'Quality',
              titleColor: colorScheme.primary,
              children: [
                DropdownSettingsItem(
                  icon: Icon(Iconsax.video_tick, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Video Quality',
                  description: 'Current: ${playerSettings.defaultQuality}',
                  value: playerSettings.defaultQuality,
                  items: const [
                    DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                    DropdownMenuItem(value: '1080p', child: Text('1080p')),
                    DropdownMenuItem(value: '720p', child: Text('720p')),
                    DropdownMenuItem(value: '480p', child: Text('480p')),
                    DropdownMenuItem(value: '360p', child: Text('360p')),
                  ],
                  onChanged: (value) => ref
                      .read(playerSettingsProvider.notifier)
                      .updateSettings(
                        (prev) => prev.copyWith(defaultQuality: value!),
                      ),
                ),
              ],
            ),
            SettingsSection(
              title: 'AniSkip',
              titleColor: colorScheme.primary,
              children: [
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.timer_1, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Enable AniSkip',
                  description: 'Skip intro and outro automatically or manually',
                  value: playerSettings.enableAniSkip,
                  onChanged: (value) => ref
                      .read(playerSettingsProvider.notifier)
                      .updateSettings(
                        (prev) => prev.copyWith(enableAniSkip: value),
                      ),
                ),
                ToggleableSettingsItem(
                  icon: Icon(
                    Iconsax.autobrightness,
                    color: colorScheme.primary,
                  ),
                  accent: colorScheme.primary,
                  title: 'Auto Skip',
                  description: 'Automatically skip intro/outro without asking',
                  value: playerSettings.enableAutoSkip,
                  onChanged: (value) {
                    if (playerSettings.enableAniSkip) {
                      ref
                          .read(playerSettingsProvider.notifier)
                          .updateSettings(
                            (prev) => prev.copyWith(enableAutoSkip: value),
                          );
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'Subtitle',
              titleColor: colorScheme.primary,
              children: [
                NormalSettingsItem(
                  icon: Icon(Iconsax.subtitle, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Subtitle Customization',
                  description: 'Customize subtitle appearance',
                  onTap: () => context.push('/settings/player/subtitles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
