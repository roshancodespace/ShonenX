import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  late final SettingsBox settingsBox;
  double episodeCompletionThreshold = 0.9;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    settingsBox = SettingsBox();
    await settingsBox.init();
    final settings = settingsBox.getSettings();
    if (settings != null) {
      final playerSettings = settings.playerSettings;
      setState(() {
        episodeCompletionThreshold = playerSettings.episodeCompletionThreshold ?? 0.9;
      });
    }
  }

  Future<void> _setEpisodeCompletionThreshold() async {
    double tempValue = episodeCompletionThreshold;

    final newThreshold = await showDialog<double>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Episode Completion Threshold',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempValue,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    label: '${(tempValue * 100).toStringAsFixed(0)}%',
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceContainerHighest,
                    onChanged: (value) {
                      setDialogState(() {
                        tempValue = value;
                      });
                    },
                  ),
                  Text(
                    'Mark as watched at ${(tempValue * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempValue),
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );

    if (newThreshold != null && newThreshold != episodeCompletionThreshold) {
      setState(() {
        episodeCompletionThreshold = newThreshold;
      });
      await settingsBox.updatePlayerSettings(PlayerSettingsModel(
        episodeCompletionThreshold: episodeCompletionThreshold,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left_1, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: const Text(
          'Video Player Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(context, 'Playback', [
            _SettingsItem(
              icon: Iconsax.timer_1,
              title: 'Episode Completion',
              description: 'Mark as watched at ${(episodeCompletionThreshold * 100).toStringAsFixed(0)}% completion',
              onTap: _setEpisodeCompletionThreshold,
            ),
            _SettingsItem(
              icon: Iconsax.forward,
              title: 'Playback Speed',
              description: 'Set default video playback speed',
              disabled: true,
              onTap: () {},
            ),
          ]),
          _buildSettingsSection(context, 'Subtitles', [
            _SettingsItem(
              icon: Iconsax.text,
              title: 'Subtitle Appearance',
              description: 'Font style, size, and colors',
              disabled: true,
              onTap: () {},
            ),
            _SettingsItem(
              icon: Iconsax.clock,
              title: 'Subtitle Timing',
              description: 'Adjust subtitle sync and delay',
              disabled: true,
              onTap: () {},
            ),
          ]),
          _buildSettingsSection(context, 'Quality', [
            _SettingsItem(
              icon: Iconsax.video_tick,
              title: 'Video Quality',
              description: 'Default streaming quality settings',
              disabled: true,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shadowColor: colorScheme.shadow.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: items.asMap().entries.map((entry) {
                // final index = entry.key;
                final item = entry.value;
                return item;
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(widget.disabled ? 0.05 : 0.2),
                      colorScheme.primary.withOpacity(widget.disabled ? 0.03 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.disabled
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.disabled
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.3 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.2 : 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}