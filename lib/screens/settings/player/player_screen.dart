import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Riverpod provider for player settings
final playerSettingsProvider =
    StateNotifierProvider<PlayerSettingsNotifier, PlayerSettingsState>((ref) {
  return PlayerSettingsNotifier();
});

class PlayerSettingsState {
  final PlayerSettingsModel playerSettings;
  final bool isLoading;

  PlayerSettingsState({required this.playerSettings, this.isLoading = false});

  PlayerSettingsState copyWith(
      {PlayerSettingsModel? playerSettings, bool? isLoading}) {
    return PlayerSettingsState(
      playerSettings: playerSettings ?? this.playerSettings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlayerSettingsNotifier extends StateNotifier<PlayerSettingsState> {
  SettingsBox? _settingsBox;

  PlayerSettingsNotifier()
      : super(PlayerSettingsState(playerSettings: PlayerSettingsModel()));

  Future<void> initializeSettings() async {
    state = state.copyWith(isLoading: true);
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    _loadSettings();
    state = state.copyWith(isLoading: false);
  }

  void _loadSettings() {
    final settings = _settingsBox?.getSettings();
    if (settings != null) {
      state = state.copyWith(playerSettings: settings.playerSettings);
    }
  }

  void updatePlayerSettings(PlayerSettingsModel settings) {
    state = state.copyWith(playerSettings: settings);
    _settingsBox?.updatePlayerSettings(settings);
  }
}

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(playerSettingsProvider);

    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildContent(context, ref);
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final playerSettings = ref.watch(playerSettingsProvider).playerSettings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSection(context: context, title: 'Playback', items: [
          SettingsItem(
            icon: Iconsax.timer_1,
            title: 'Episode Completion',
            description:
                'Mark as watched at ${(playerSettings.episodeCompletionThreshold * 100).toStringAsFixed(0)}% completion',
            onTap: () => _setEpisodeCompletionThreshold(context, ref),
          ),
          SettingsItem(
            icon: Iconsax.forward,
            title: 'Playback Speed',
            description: 'Default speed: 1.0x', // Placeholder
            onTap: () => _setPlaybackSpeed(context, ref),
          ),
        ]),
        SettingsSection(context: context, title: 'Subtitles', items: [
          SettingsItem(
            icon: Iconsax.text,
            title: 'Subtitle Appearance',
            description:
                'Font size: ${playerSettings.subtitleFontSize.round()}px, Color: ${playerSettings.subtitleTextColor.toRadixString(16).substring(2)}',
            onTap: () => _setSubtitleAppearance(context, ref),
          ),
          SettingsItem(
            onTap: () {},
            icon: Iconsax.clock,
            title: 'Subtitle Timing',
            description: 'Adjust subtitle sync and delay',
            disabled: true,
          ),
        ]),
        SettingsSection(context: context, title: 'Quality', items: [
          SettingsItem(
            onTap: () {},
            icon: Iconsax.video_tick,
            title: 'Video Quality',
            description: 'Default streaming quality settings',
            disabled: true,
          ),
        ]),
        const SizedBox(height: 48),
      ],
    );
  }

  void _setEpisodeCompletionThreshold(
      BuildContext context, WidgetRef ref) async {
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;
    double tempValue = playerSettings.episodeCompletionThreshold;
    final colorScheme = Theme.of(context).colorScheme;

    final newThreshold = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempValue),
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );

    if (newThreshold != null &&
        newThreshold != playerSettings.episodeCompletionThreshold) {
      ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
            playerSettings.copyWith(episodeCompletionThreshold: newThreshold),
          );
    }
  }

  void _setPlaybackSpeed(BuildContext context, WidgetRef ref) async {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    double tempSpeed = 1.0; // Placeholder
    final colorScheme = Theme.of(context).colorScheme;

    final newSpeed = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Default Playback Speed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: speeds
                    .map(
                      (speed) => RadioListTile<double>(
                        title: Text('${speed}x'),
                        value: speed,
                        groupValue: tempSpeed,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setDialogState(() {
                            tempSpeed = value!;
                          });
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempSpeed),
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );

    if (newSpeed != null) {
      // Placeholder: Add defaultPlaybackSpeed to PlayerSettingsModel later
    }
  }

  void _setSubtitleAppearance(BuildContext context, WidgetRef ref) async {
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;
    double tempFontSize = playerSettings.subtitleFontSize;
    Color tempTextColor = Color(playerSettings.subtitleTextColor);
    double tempBackgroundOpacity = playerSettings.subtitleBackgroundOpacity;
    bool tempHasShadow = playerSettings.subtitleHasShadow;
    final colorScheme = Theme.of(context).colorScheme;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Subtitle Appearance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: tempBackgroundOpacity),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'This is a subtitle preview',
                        style: TextStyle(
                          fontSize: tempFontSize,
                          color: tempTextColor,
                          fontWeight: FontWeight.bold,
                          shadows: tempHasShadow
                              ? [
                                  const Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 4,
                                    color: Colors.black,
                                  ),
                                ]
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Font Size
                    Text('Font Size: ${tempFontSize.round()}px'),
                    Slider(
                      value: tempFontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: '${tempFontSize.round()}px',
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (value) {
                        setDialogState(() {
                          tempFontSize = value;
                        });
                      },
                    ),
                    // Text Color
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Text Color'),
                        GestureDetector(
                          onTap: () async {
                            final newColor = await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Pick Subtitle Color'),
                                content: SingleChildScrollView(
                                  child: MaterialPicker(
                                    pickerColor: tempTextColor,
                                    onColorChanged: (color) {
                                      Navigator.pop(context, color);
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (newColor != null) {
                              setDialogState(() {
                                tempTextColor = newColor;
                              });
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tempTextColor,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Background Opacity
                    Text(
                        'Background Opacity: ${(tempBackgroundOpacity * 100).round()}%'),
                    Slider(
                      value: tempBackgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: '${(tempBackgroundOpacity * 100).round()}%',
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (value) {
                        setDialogState(() {
                          tempBackgroundOpacity = value;
                        });
                      },
                    ),
                    // Shadow Toggle
                    SwitchListTile(
                      title: const Text('Text Shadow'),
                      value: tempHasShadow,
                      onChanged: (value) {
                        setDialogState(() {
                          tempHasShadow = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
            playerSettings.copyWith(
              subtitleFontSize: tempFontSize,
              subtitleTextColor: tempTextColor.value,
              subtitleBackgroundOpacity: tempBackgroundOpacity,
              subtitleHasShadow: tempHasShadow,
            ),
          );
    }
  }
}
