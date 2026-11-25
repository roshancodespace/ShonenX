import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/gesture_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_translation_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/core/utils/stream_cleaner.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerPrefs = ref.watch(playerPrefsProvider);
    final prefsNotifier = ref.read(playerPrefsProvider.notifier);

    final aniskipPrefs = ref.watch(aniskipPrefsProvider);
    final aniskipPrefsNotifier = ref.read(aniskipPrefsProvider.notifier);

    final cleanQuality = StreamCleaner.sanitizeDefaultQuality(
      playerPrefs.defaultQuality,
    );
    if (cleanQuality != playerPrefs.defaultQuality) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prefsNotifier.setDefaultQuality(cleanQuality);
      });
    }

    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsPlayer,
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
            title: l10n.playerVideoEngineSection,
            children: [
              SettingsSelectionTile(
                title: l10n.playerMediaKitTitle,
                subtitle: l10n.playerMediaKitSubtitle,
                isSelected: playerPrefs.playerType == PlayerType.mediakit,
                onSelect: () => prefsNotifier.changePlayer(PlayerType.mediakit),
                customizeLabel: l10n.settingsAdvancedSettings,
                customizeIcon: Icons.settings_outlined,
                onCustomize: () {
                  AppBottomSheet.show(
                    context: context,
                    title: l10n.playerMediaKitTitle,
                    titleIcon: Icons.tune_rounded,
                    child: const MediaKitAdvancedSettings(),
                  );
                },
              ),
              if (Platform.isAndroid)
                SettingsSelectionTile(
                  title: l10n.playerBetterPlayerTitle,
                  subtitle: l10n.playerBetterPlayerSubtitle,
                  isSelected: playerPrefs.playerType == PlayerType.betterPlayer,
                  onSelect: () =>
                      prefsNotifier.changePlayer(PlayerType.betterPlayer),
                ),
            ],
          ),
          SettingsSection(
            title: l10n.playerPlaybackDefaultsSection,
            children: [
              SettingsDropdownTile<ServerType>(
                icon: Icons.translate_rounded,
                title: l10n.playerDefaultServerType,
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
                              t == ServerType.unknown
                                  ? l10n.playerServerAny
                                  : t.displayName,
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
                title: l10n.playerDefaultVideoQuality,
                value: cleanQuality,
                items: [
                  ..._kQualityOptions.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
                  if (!_kQualityOptions.containsKey(cleanQuality))
                    DropdownMenuItem(
                      value: cleanQuality,
                      child: Text(cleanQuality),
                    ),
                  DropdownMenuItem(
                    value: '__custom__',
                    child: Text(l10n.playerCustomOption),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__custom__') {
                    _showCustomInputDialog(
                      context,
                      title: l10n.playerCustomVideoQualityTitle,
                      hint: l10n.playerCustomVideoQualityHint,
                      initialValue: cleanQuality,
                      onSubmitted: (q) => prefsNotifier.setDefaultQuality(
                        StreamCleaner.sanitizeDefaultQuality(q),
                      ),
                    );
                  } else if (val != null) {
                    prefsNotifier.setDefaultQuality(
                      StreamCleaner.sanitizeDefaultQuality(val),
                    );
                  }
                },
              ),
              SettingsDropdownTile<String>(
                icon: Icons.audiotrack_rounded,
                title: l10n.playerDefaultAudioLang,
                value: playerPrefs.defaultAudioLang,
                items: [
                  ..._kAudioLangOptions.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
                  if (!_kAudioLangOptions.containsKey(
                    playerPrefs.defaultAudioLang,
                  ))
                    DropdownMenuItem(
                      value: playerPrefs.defaultAudioLang,
                      child: Text(playerPrefs.defaultAudioLang.toUpperCase()),
                    ),
                  DropdownMenuItem(
                    value: '__custom__',
                    child: Text(l10n.playerCustomOption),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__custom__') {
                    _showCustomInputDialog(
                      context,
                      title: l10n.playerCustomAudioLangTitle,
                      hint: l10n.playerCustomAudioLangHint,
                      initialValue: playerPrefs.defaultAudioLang,
                      onSubmitted: (l) => prefsNotifier.setDefaultAudioLang(l),
                    );
                  } else if (val != null) {
                    prefsNotifier.setDefaultAudioLang(val);
                  }
                },
              ),
              SettingsDropdownTile<String>(
                icon: Icons.subtitles_rounded,
                title: l10n.playerDefaultSubtitleLang,
                value: playerPrefs.defaultSubtitleLang,
                items: [
                  ..._kSubtitleLangOptions.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
                  if (!_kSubtitleLangOptions.containsKey(
                    playerPrefs.defaultSubtitleLang,
                  ))
                    DropdownMenuItem(
                      value: playerPrefs.defaultSubtitleLang,
                      child: Text(
                        playerPrefs.defaultSubtitleLang.toUpperCase(),
                      ),
                    ),
                  DropdownMenuItem(
                    value: '__custom__',
                    child: Text(l10n.playerCustomOption),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__custom__') {
                    _showCustomInputDialog(
                      context,
                      title: l10n.playerCustomSubtitleLangTitle,
                      hint: l10n.playerCustomSubtitleLangHint,
                      initialValue: playerPrefs.defaultSubtitleLang,
                      onSubmitted: (l) =>
                          prefsNotifier.setDefaultSubtitleLang(l),
                    );
                  } else if (val != null) {
                    prefsNotifier.setDefaultSubtitleLang(val);
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: l10n.playerAutoNextQuickSkipSection,
            children: [
              SettingsSwitchTile(
                icon: Icons.skip_next_rounded,
                title: l10n.playerAutoSwitchNextEpisode,
                subtitle: l10n.playerAutoSwitchNextEpisodeSubtitle,
                value: playerPrefs.autoNext,
                onChanged: (val) => prefsNotifier.setAutoNext(val),
              ),
              SettingsDropdownTile<int>(
                icon: Icons.timer_outlined,
                title: l10n.playerNextEpisodePromptThreshold,
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
                        child: Text(l10n.playerSecondsBeforeEnd(s.toString())),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) prefsNotifier.setNextEpisodeThreshold(val);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.fast_forward_rounded,
                title: l10n.playerShowQuickSkip,
                subtitle: l10n.playerShowQuickSkipSubtitle,
                value: playerPrefs.showSkipButton,
                onChanged: (val) => prefsNotifier.setShowSkipButton(val),
              ),
              if (playerPrefs.showSkipButton)
                SettingsDropdownTile<int>(
                  icon: Icons.forward_10_rounded,
                  title: l10n.playerQuickSkipDuration,
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
            title: l10n.playerSubtitlesGesturesSection,
            children: [
              SettingsActionTile(
                icon: Icons.subtitles_rounded,
                title: l10n.playerSubtitlePreferences,
                subtitle: l10n.playerSubtitlePreferencesSubtitle,
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
                icon: Icons.translate_rounded,
                title: l10n.playerSubtitleTranslation,
                subtitle: l10n.playerSubtitleTranslationSubtitle,
                onTap: () {
                  SubtitleTranslationSettingsSheet.show(context);
                },
              ),
              SettingsActionTile(
                icon: Icons.gesture_rounded,
                title: l10n.playerGestureArea,
                subtitle: l10n.playerGestureAreaSubtitle,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    constraints: const BoxConstraints(maxWidth: 1200),
                    isScrollControlled: true,
                    builder: (context) => const GestureSettingsSheet(),
                  );
                },
              ),
              SettingsSwitchTile(
                icon: Icons.touch_app_rounded,
                title: l10n.playerEnableGestures,
                subtitle: l10n.playerEnableGesturesSubtitle,
                value: playerPrefs.gesturePrefs.enableGestures,
                onChanged: (val) {
                  prefsNotifier.updateGesturePrefs(
                    playerPrefs.gesturePrefs.copyWith(enableGestures: val),
                  );
                },
              ),
              if (playerPrefs.gesturePrefs.enableGestures)
                SettingsSwitchTile(
                  icon: Icons.swap_horiz_rounded,
                  title: l10n.playerSwapVolumeBrightness,
                  subtitle: l10n.playerSwapVolumeBrightnessSubtitle,
                  value: playerPrefs.gesturePrefs.swapVolumeAndBrightness,
                  onChanged: (val) {
                    prefsNotifier.updateGesturePrefs(
                      playerPrefs.gesturePrefs.copyWith(
                        swapVolumeAndBrightness: val,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onSubmitted,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await AppDialog.show(
      context: context,
      title: title,
      maxWidth: 420,
      child: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (val) {
          final trimmed = val.trim();
          if (trimmed.isNotEmpty) {
            onSubmitted(trimmed);
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = controller.text.trim();
            if (trimmed.isNotEmpty) {
              onSubmitted(trimmed);
              Navigator.of(context).pop();
            }
          },
          child: Text(context.l10n.commonSave),
        ),
      ],
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

const Map<String, String> _kQualityOptions = {
  'Auto': 'Auto',
  '4K': '4K',
  '1440p': '1440p',
  '1080p': '1080p',
  '720p': '720p',
  '480p': '480p',
  '360p': '360p',
  '240p': '240p',
};

const Map<String, String> _kAudioLangOptions = {
  'Auto': 'Auto',
  'eng': 'ENG',
  'jpn': 'JPN',
  'spa': 'SPA',
  'fre': 'FRE',
  'ger': 'GER',
  'por': 'POR',
  'ita': 'ITA',
  'rus': 'RUS',
  'ara': 'ARA',
  'hin': 'HIN',
  'ind': 'IND',
  'tur': 'TUR',
  'vie': 'VIE',
  'tha': 'THA',
  'chi': 'CHI',
  'kor': 'KOR',
};

const Map<String, String> _kSubtitleLangOptions = {
  'Off': 'OFF (Disabled)',
  'eng': 'ENG (English)',
  'en': 'ENG (English)',
  'spa': 'SPA (Spanish)',
  'es': 'SPA (Spanish)',
  'fre': 'FRE (French)',
  'fr': 'FRE (French)',
  'ger': 'GER (German)',
  'de': 'GER (German)',
  'por': 'POR (Portuguese)',
  'pt': 'POR (Portuguese)',
  'ita': 'ITA (Italian)',
  'it': 'ITA (Italian)',
  'rus': 'RUS (Russian)',
  'ru': 'RUS (Russian)',
  'ara': 'ARA (Arabic)',
  'ar': 'ARA (Arabic)',
  'hin': 'HIN (Hindi)',
  'hi': 'HIN (Hindi)',
  'ind': 'IND (Indonesian)',
  'id': 'IND (Indonesian)',
  'tur': 'TUR (Turkish)',
  'tr': 'TUR (Turkish)',
  'vie': 'VIE (Vietnamese)',
  'vi': 'VIE (Vietnamese)',
  'tha': 'THA (Thai)',
  'th': 'THA (Thai)',
  'pol': 'POL (Polish)',
  'pl': 'POL (Polish)',
  'chi': 'CHI (Chinese)',
  'zh': 'CHI (Chinese)',
  'yue': 'YUE (Cantonese)',
  'kor': 'KOR (Korean)',
  'ko': 'KOR (Korean)',
  'ja': 'JPN (Japanese)',
  'nl': 'DUT (Dutch)',
  'fil': 'TGL (Filipino)',
  'ms': 'MAY (Malay)',
  'sv': 'SWE (Swedish)',
  'uk': 'UKR (Ukrainian)',
  'ro': 'RON (Romanian)',
  'el': 'ELL (Greek)',
  'hu': 'HUN (Hungarian)',
  'cs': 'CES (Czech)',
  'da': 'DAN (Danish)',
  'fi': 'FIN (Finnish)',
  'no': 'NOR (Norwegian)',
  'he': 'HEB (Hebrew)',
  'bn': 'BEN (Bengali)',
  'ta': 'TAM (Tamil)',
  'te': 'TEL (Telugu)',
  'fa': 'FAS (Persian)',
  'ur': 'URD (Urdu)',
};
