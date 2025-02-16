import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  late final Box settingsBox;
  late int episodeCompletionThreshold;

  @override
  void initState() {
    super.initState();
    episodeCompletionThreshold = 70;
  }

  Future<void> _setEpisodeCompletionThreshold() async {
    int tempValue = episodeCompletionThreshold;

    final newThreshold = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Episode Completion Threshold'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempValue.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '$tempValue%',
                    onChanged: (value) {
                      setDialogState(() {
                        tempValue = value.toInt();
                      });
                    },
                  ),
                  Text(
                    'Threshold: $tempValue%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempValue),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newThreshold != null && newThreshold != episodeCompletionThreshold) {
      setState(() {
        episodeCompletionThreshold = newThreshold;
      });
      await settingsBox.put('episodeCompletionThreshold', newThreshold);
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String subtitle,
    bool notAvailable = false,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: notAvailable ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: notAvailable
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'Video Player Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _sectionTitle(context, 'Playback'),
          _buildSettingsTile(
            context,
            title: 'Episode Completion',
            icon: Iconsax.timer_1,
            subtitle: 'Mark as watched at $episodeCompletionThreshold% completion',
            onTap: _setEpisodeCompletionThreshold,
          ),
          _buildSettingsTile(
            context,
            title: 'Playback Speed',
            icon: Iconsax.forward,
            subtitle: 'Set default video playback speed',
            notAvailable: true,
            onTap: () {},
          ),
          const Divider(height: 1),
          
          _sectionTitle(context, 'Subtitles'),
          _buildSettingsTile(
            context,
            title: 'Subtitle Appearance',
            icon: Iconsax.text,
            subtitle: 'Font style, size, and colors',
            notAvailable: true,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            title: 'Subtitle Timing',
            icon: Iconsax.clock,
            subtitle: 'Adjust subtitle sync and delay',
            notAvailable: true,
            onTap: () {},
          ),
          const Divider(height: 1),

          _sectionTitle(context, 'Quality'),
          _buildSettingsTile(
            context,
            title: 'Video Quality',
            icon: Iconsax.video_tick,
            subtitle: 'Default streaming quality settings',
            notAvailable: true,
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}