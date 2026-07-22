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
import 'package:shonenx/shared/models/video_server.dart';
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
        padding: const EdgeInsets.only(bottom: 50),
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
            title: 'Playback Defaults',
            children: [
              SettingsDropdownTile<ServerType>(
                icon: Icons.translate_rounded,
                title: 'Default Server Type (Sub / Dub)',
                value: playerPrefs.defaultServerType,
                items:
                    [
                          ServerType.sub,
                          ServerType.dub,
                          ServerType.raw,
                          ServerType.unknown,
                        ]
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t == ServerType.unknown ? 'Any' : t.displayName,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setDefaultServerType(val);
                },
              ),
              SettingsDropdownTile<String>(
                icon: Icons.high_quality_rounded,
                title: 'Default Video Quality',
                value:
                    {
                      'Auto',
                      '1080p',
                      '720p',
                      '480p',
                      '360p',
                      playerPrefs.defaultQuality,
                    }.contains(playerPrefs.defaultQuality)
                    ? playerPrefs.defaultQuality
                    : '1080p',
                items:
                    {
                          'Auto',
                          '1080p',
                          '720p',
                          '480p',
                          '360p',
                          playerPrefs.defaultQuality,
                        }
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setDefaultQuality(val);
                },
              ),
              SettingsDropdownTile<String>(
                icon: Icons.audiotrack_rounded,
                title: 'Default Audio Language',
                value: playerPrefs.defaultAudioLang,
                items: {'eng', 'jpn', 'Auto', playerPrefs.defaultAudioLang}
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(
                          a == 'eng'
                              ? 'English (eng)'
                              : a == 'jpn'
                              ? 'Japanese (jpn)'
                              : a == 'Auto'
                              ? 'Auto'
                              : a.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setDefaultAudioLang(val);
                },
              ),
              SettingsDropdownTile<String>(
                icon: Icons.subtitles_rounded,
                title: 'Default Subtitle Language',
                value: playerPrefs.defaultSubtitleLang,
                items:
                    {
                          'eng',
                          'Off',
                          'spa',
                          'fre',
                          'ger',
                          'por',
                          'ita',
                          'rus',
                          'ara',
                          'hin',
                          playerPrefs.defaultSubtitleLang,
                        }
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == 'eng'
                                  ? 'English (eng)'
                                  : s == 'Off'
                                  ? 'Off'
                                  : s.toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setDefaultSubtitleLang(val);
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Auto-Next & Quick Skip',
            children: [
              SettingsSwitchTile(
                icon: Icons.skip_next_rounded,
                title: 'Auto-Switch to Next Episode',
                subtitle:
                    'Automatically load next episode when countdown finishes or video ends',
                value: playerPrefs.autoNext,
                onChanged: (val) => prefsNotifier.setAutoNext(val),
              ),
              SettingsDropdownTile<int>(
                icon: Icons.timer_outlined,
                title: 'Next Episode Prompt Threshold',
                value:
                    [
                      30,
                      45,
                      60,
                      85,
                      90,
                      120,
                    ].contains(playerPrefs.nextEpisodeThreshold)
                    ? playerPrefs.nextEpisodeThreshold
                    : 85,
                items: [30, 45, 60, 85, 90, 120]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}s before end'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setNextEpisodeThreshold(val);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.fast_forward_rounded,
                title: 'Show Quick Skip Button',
                subtitle: 'Display quick seek button (+Xs) during playback',
                value: playerPrefs.showSkipButton,
                onChanged: (val) => prefsNotifier.setShowSkipButton(val),
              ),
              if (playerPrefs.showSkipButton)
                SettingsDropdownTile<int>(
                  icon: Icons.forward_10_rounded,
                  title: 'Quick Skip Duration',
                  value:
                      [
                        15,
                        30,
                        45,
                        60,
                        85,
                        90,
                        120,
                      ].contains(playerPrefs.skipDuration)
                      ? playerPrefs.skipDuration
                      : 85,
                  items: [15, 30, 45, 60, 85, 90, 120]
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: Text('+${s}s')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) prefsNotifier.setSkipDuration(val);
                  },
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
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
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
