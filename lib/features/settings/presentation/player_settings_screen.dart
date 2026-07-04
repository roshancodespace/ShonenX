import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/gesture_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerPrefs = ref.watch(playerPrefsProvider);
    final prefsNotifier = ref.read(playerPrefsProvider.notifier);

    final aniskipPrefs = ref.watch(aniskipPrefsProvider);
    final aniskipPrefsNotifier = ref.read(aniskipPrefsProvider.notifier);

    return AppScaffold(
      title: 'Player',
      body: ListView(
        children: [
          SettingsSection(
            title: 'Aniskip',
            children: SkipType.values
                .map(
                  (s) => SettingsDropdownTile(
                    icon: _icon(s),
                    title: _capitalize(s.name),
                    value: aniskipPrefs.mode(s),
                    items: SkipMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(_capitalize(m.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        aniskipPrefsNotifier.setMode(s, value);
                      }
                    },
                  ),
                )
                .toList(),
          ),
          SettingsSection(
            title: 'Video Engine & Preferences',
            children: [
              SettingsSelectionTile(
                title: 'Media Kit (MPV)',
                subtitle:
                    'Standalone player engine with advanced subtitle & shader support',
                isSelected: playerPrefs.playerType == PlayerType.mediakit,
                onSelect: () => prefsNotifier.changePlayer(PlayerType.mediakit),
                customizeLabel: 'Settings',
                customizeIcon: Icons.settings_outlined,
                onCustomize: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const MediaKitSettings(),
                  );
                },
              ),
              if (Platform.isAndroid)
                SettingsSelectionTile(
                  title: 'Video Player (ExoPlayer)',
                  subtitle: 'Official Android native video rendering engine',
                  isSelected: playerPrefs.playerType == PlayerType.videoPlayer,
                  onSelect: () =>
                      prefsNotifier.changePlayer(PlayerType.videoPlayer),
                ),
            ],
          ),
          SettingsSection(
            title: 'Subtitles & Gestures',
            children: [
              SettingsActionTile(
                icon: Icons.subtitles_rounded,
                title: 'Subtitle Preferences',
                subtitle: 'Customize subtitle appearance and rendering engine',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const SubtitleSettingsSheet(),
                  );
                },
              ),
              SettingsActionTile(
                icon: Icons.gesture_rounded,
                title: 'Gesture Area',
                subtitle: 'Customize active zones for volume and brightness',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    constraints: const BoxConstraints(maxWidth: 1200),
                    isScrollControlled: true,
                    builder: (context) => const GestureSettingsSheet(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _icon(SkipType type) {
    switch (type) {
      case SkipType.opening:
        return Icons.skip_next_outlined;
      case SkipType.ending:
        return Icons.skip_next_outlined;
      case SkipType.mixedOpening:
        return Icons.skip_next_outlined;
      case SkipType.mixedEnding:
        return Icons.skip_next_outlined;
      case SkipType.recap:
        return Icons.skip_next_outlined;
    }
  }

  String _capitalize(String str) {
    return str.replaceFirst(
      str.substring(0, 1),
      str.substring(0, 1).toUpperCase(),
    );
  }
}
