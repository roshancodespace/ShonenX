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
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('Video Player'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SettingsSection(
              title: 'Quality',
              titleColor: colorScheme.primary,
              children: [
                NormalSettingsItem(
                  icon: Icon(Iconsax.video_tick, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Video Quality',
                  description:
                      'Current: ${playerSettings.defaultQuality}',
                  onTap: () => _showQualitySettingsDialog(context, ref),
                ),
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

  void _showQualitySettingsDialog(BuildContext context, WidgetRef ref) async {
    final qualities = ['Auto', '1080p', '720p', '480p', '360p'];
    final colorScheme = Theme.of(context).colorScheme;
    final playerSettings = ref.read(playerSettingsProvider);
    String tempQuality = playerSettings.defaultQuality;

    await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Video Quality'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: qualities
                    .map((quality) => RadioListTile<String>(
                          title: Text(quality),
                          value: quality,
                          groupValue: tempQuality,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => tempQuality = value);
                            }
                          },
                        ))
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: colorScheme.onSurface)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(playerSettingsProvider.notifier).updateSettings(
                          (prev) =>
                              prev.copyWith(defaultQuality: tempQuality),
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  child: Text('Save',
                      style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}