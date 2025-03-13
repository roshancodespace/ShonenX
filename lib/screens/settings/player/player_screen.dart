import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

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
    // Public method
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
    // final colorScheme = Theme.of(context).colorScheme;
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
            onTap: () {},
            icon: Iconsax.forward,
            title: 'Playback Speed',
            description: 'Set default video playback speed',
            disabled: true,
          ),
        ]),
        SettingsSection(context: context, title: 'Subtitles', items: [
          SettingsItem(
            onTap: () {},
            icon: Iconsax.text,
            title: 'Subtitle Appearance',
            description: 'Font style, size, and colors',
            disabled: true,
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
            PlayerSettingsModel(episodeCompletionThreshold: newThreshold),
          );
    }
  }
}
