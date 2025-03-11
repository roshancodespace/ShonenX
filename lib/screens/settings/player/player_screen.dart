import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

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
      state = state.copyWith(
          playerSettings: settings.playerSettings ?? PlayerSettingsModel());
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
    final colorScheme = Theme.of(context).colorScheme;
    final playerSettings = ref.watch(playerSettingsProvider).playerSettings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(context, 'Playback', [
          SettingsItem(
            icon: Iconsax.timer_1,
            title: 'Episode Completion',
            description:
                'Mark as watched at ${(playerSettings.episodeCompletionThreshold * 100).toStringAsFixed(0)}% completion',
            onTap: () => _setEpisodeCompletionThreshold(context, ref),
          ),
          const SettingsItem(
            icon: Iconsax.forward,
            title: 'Playback Speed',
            description: 'Set default video playback speed',
            disabled: true,
          ),
        ]),
        _buildSettingsSection(context, 'Subtitles', [
          const SettingsItem(
            icon: Iconsax.text,
            title: 'Subtitle Appearance',
            description: 'Font style, size, and colors',
            disabled: true,
          ),
          const SettingsItem(
            icon: Iconsax.clock,
            title: 'Subtitle Timing',
            description: 'Adjust subtitle sync and delay',
            disabled: true,
          ),
        ]),
        _buildSettingsSection(context, 'Quality', [
          const SettingsItem(
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

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> items) {
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
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
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

// Reusing the SettingsItem from UISettingsScreen
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool disabled;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: disabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.primary,
                size: 24,
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
                      color: disabled
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: disabled
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
