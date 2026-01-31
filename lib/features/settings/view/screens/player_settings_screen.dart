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
    final playerNotifier = ref.read(playerSettingsProvider.notifier);

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
                  onChanged: (value) => playerNotifier.updateSettings(
                    (prev) => prev.copyWith(defaultQuality: value!),
                  ),
                ),
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.microphone),
                  title: 'Prefer Dub',
                  description: 'Do you prefer dubbed over subbed?',
                  value: playerSettings.preferDub,
                  onChanged: (value) => playerNotifier.updateSettings(
                    (prev) => prev.copyWith(preferDub: value),
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
                  onChanged: (value) => playerNotifier.updateSettings(
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
                      playerNotifier.updateSettings(
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
            SettingsSection(
              title: 'Controls Overlay',
              titleColor: colorScheme.primary,
              children: [
                SliderSettingsItem(
                  icon: Icon(
                    Iconsax.forward_10_seconds,
                    color: colorScheme.primary,
                  ),
                  accent: colorScheme.primary,
                  title: 'Seek Duration',
                  description: '${playerSettings.seekDuration}s',
                  value: playerSettings.seekDuration.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  onChanged: (val) => playerNotifier.updateSettings(
                    (prev) => prev.copyWith(seekDuration: val.toInt()),
                  ),
                ),
                SliderSettingsItem(
                  icon: Icon(Iconsax.timer_pause, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Auto Hide Timeout',
                  description: '${playerSettings.autoHideDuration}s',
                  value: playerSettings.autoHideDuration.toDouble(),
                  min: 2,
                  max: 10,
                  onChanged: (val) => playerNotifier.updateSettings(
                    (prev) => prev.copyWith(autoHideDuration: val.toInt()),
                  ),
                ),
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.previous, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Show Next/Prev Buttons',
                  description: 'Show next and previous episode buttons',
                  value: playerSettings.showNextPrevButtons,
                  onChanged: (val) => playerNotifier.updateSettings(
                    (prev) => prev.copyWith(showNextPrevButtons: val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
