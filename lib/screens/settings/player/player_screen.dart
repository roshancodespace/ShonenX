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

class PlayerSettingsScreen extends ConsumerStatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  ConsumerState<PlayerSettingsScreen> createState() =>
      _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends ConsumerState<PlayerSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings when the screen is first loaded
    Future.microtask(() {
      ref.read(playerSettingsProvider.notifier).initializeSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(playerSettingsProvider);

    if (settingsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final playerSettings = ref.watch(playerSettingsProvider).playerSettings;
    // A comprehensive list of languages with their native names and language codes
    final List<LanguageOption> allLanguages = [
      LanguageOption(code: 'af', name: 'Afrikaans', nativeName: 'Afrikaans'),
      LanguageOption(code: 'sq', name: 'Albanian', nativeName: 'Shqip'),
      LanguageOption(code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
      LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
      LanguageOption(code: 'hy', name: 'Armenian', nativeName: 'Հայերեն'),
      LanguageOption(
          code: 'az', name: 'Azerbaijani', nativeName: 'Azərbaycan dili'),
      LanguageOption(code: 'eu', name: 'Basque', nativeName: 'Euskara'),
      LanguageOption(code: 'be', name: 'Belarusian', nativeName: 'Беларуская'),
      LanguageOption(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
      LanguageOption(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski'),
      LanguageOption(code: 'bg', name: 'Bulgarian', nativeName: 'Български'),
      LanguageOption(code: 'ca', name: 'Catalan', nativeName: 'Català'),
      LanguageOption(code: 'ceb', name: 'Cebuano', nativeName: 'Cebuano'),
      LanguageOption(
          code: 'zh', name: 'Chinese (Simplified)', nativeName: '简体中文'),
      LanguageOption(
          code: 'zh-TW', name: 'Chinese (Traditional)', nativeName: '繁體中文'),
      LanguageOption(code: 'co', name: 'Corsican', nativeName: 'Corsu'),
      LanguageOption(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski'),
      LanguageOption(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
      LanguageOption(code: 'da', name: 'Danish', nativeName: 'Dansk'),
      LanguageOption(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
      LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
      LanguageOption(code: 'eo', name: 'Esperanto', nativeName: 'Esperanto'),
      LanguageOption(code: 'et', name: 'Estonian', nativeName: 'Eesti'),
      LanguageOption(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
      LanguageOption(code: 'fr', name: 'French', nativeName: 'Français'),
      LanguageOption(code: 'fy', name: 'Frisian', nativeName: 'Frysk'),
      LanguageOption(code: 'gl', name: 'Galician', nativeName: 'Galego'),
      LanguageOption(code: 'ka', name: 'Georgian', nativeName: 'ქართული'),
      LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch'),
      LanguageOption(code: 'el', name: 'Greek', nativeName: 'Ελληνικά'),
      LanguageOption(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
      LanguageOption(
          code: 'ht', name: 'Haitian Creole', nativeName: 'Kreyòl Ayisyen'),
      LanguageOption(code: 'ha', name: 'Hausa', nativeName: 'هَوُسَ'),
      LanguageOption(
          code: 'haw', name: 'Hawaiian', nativeName: 'ʻŌlelo Hawaiʻi'),
      LanguageOption(code: 'he', name: 'Hebrew', nativeName: 'עברית'),
      LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
      LanguageOption(code: 'hmn', name: 'Hmong', nativeName: 'Hmong'),
      LanguageOption(code: 'hu', name: 'Hungarian', nativeName: 'Magyar'),
      LanguageOption(code: 'is', name: 'Icelandic', nativeName: 'Íslenska'),
      LanguageOption(code: 'ig', name: 'Igbo', nativeName: 'Igbo'),
      LanguageOption(
          code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
      LanguageOption(code: 'ga', name: 'Irish', nativeName: 'Gaeilge'),
      LanguageOption(code: 'it', name: 'Italian', nativeName: 'Italiano'),
      LanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語'),
      LanguageOption(code: 'jv', name: 'Javanese', nativeName: 'Basa Jawa'),
      LanguageOption(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
      LanguageOption(code: 'kk', name: 'Kazakh', nativeName: 'Қазақ тілі'),
      LanguageOption(code: 'km', name: 'Khmer', nativeName: 'ភាសាខ្មែរ'),
      LanguageOption(
          code: 'rw', name: 'Kinyarwanda', nativeName: 'Kinyarwanda'),
      LanguageOption(code: 'ko', name: 'Korean', nativeName: '한국어'),
      LanguageOption(code: 'ku', name: 'Kurdish', nativeName: 'Kurdî'),
      LanguageOption(code: 'ky', name: 'Kyrgyz', nativeName: 'Кыргызча'),
      LanguageOption(code: 'lo', name: 'Lao', nativeName: 'ພາສາລາວ'),
      LanguageOption(code: 'la', name: 'Latin', nativeName: 'Latina'),
      LanguageOption(code: 'lv', name: 'Latvian', nativeName: 'Latviešu'),
      LanguageOption(code: 'lt', name: 'Lithuanian', nativeName: 'Lietuvių'),
      LanguageOption(
          code: 'lb', name: 'Luxembourgish', nativeName: 'Lëtzebuergesch'),
      LanguageOption(code: 'mk', name: 'Macedonian', nativeName: 'Македонски'),
      LanguageOption(code: 'mg', name: 'Malagasy', nativeName: 'Malagasy'),
      LanguageOption(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
      LanguageOption(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
      LanguageOption(code: 'mt', name: 'Maltese', nativeName: 'Malti'),
      LanguageOption(code: 'mi', name: 'Maori', nativeName: 'te reo Māori'),
      LanguageOption(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
      LanguageOption(code: 'mn', name: 'Mongolian', nativeName: 'Монгол'),
      LanguageOption(
          code: 'my', name: 'Myanmar (Burmese)', nativeName: 'ဗမာစာ'),
      LanguageOption(code: 'ne', name: 'Nepali', nativeName: 'नेपाली'),
      LanguageOption(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
      LanguageOption(
          code: 'ny', name: 'Nyanja (Chichewa)', nativeName: 'Chichewa'),
      LanguageOption(code: 'or', name: 'Odia (Oriya)', nativeName: 'ଓଡ଼ିଆ'),
      LanguageOption(code: 'ps', name: 'Pashto', nativeName: 'پښتو'),
      LanguageOption(code: 'fa', name: 'Persian', nativeName: 'فارسی'),
      LanguageOption(code: 'pl', name: 'Polish', nativeName: 'Polski'),
      LanguageOption(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
      LanguageOption(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
      LanguageOption(code: 'ro', name: 'Romanian', nativeName: 'Română'),
      LanguageOption(code: 'ru', name: 'Russian', nativeName: 'Русский'),
      LanguageOption(
          code: 'sm', name: 'Samoan', nativeName: 'Gagana fa\'a Sāmoa'),
      LanguageOption(code: 'gd', name: 'Scots Gaelic', nativeName: 'Gàidhlig'),
      LanguageOption(code: 'sr', name: 'Serbian', nativeName: 'Српски'),
      LanguageOption(code: 'st', name: 'Sesotho', nativeName: 'Sesotho'),
      LanguageOption(code: 'sn', name: 'Shona', nativeName: 'chiShona'),
      LanguageOption(code: 'sd', name: 'Sindhi', nativeName: 'سنڌي'),
      LanguageOption(code: 'si', name: 'Sinhala', nativeName: 'සිංහල'),
      LanguageOption(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina'),
      LanguageOption(code: 'sl', name: 'Slovenian', nativeName: 'Slovenščina'),
      LanguageOption(code: 'so', name: 'Somali', nativeName: 'Soomaali'),
      LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español'),
      LanguageOption(code: 'su', name: 'Sundanese', nativeName: 'Basa Sunda'),
      LanguageOption(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili'),
      LanguageOption(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
      LanguageOption(
          code: 'tl', name: 'Tagalog (Filipino)', nativeName: 'Tagalog'),
      LanguageOption(code: 'tg', name: 'Tajik', nativeName: 'Тоҷикӣ'),
      LanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
      LanguageOption(code: 'tt', name: 'Tatar', nativeName: 'Татар теле'),
      LanguageOption(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
      LanguageOption(code: 'th', name: 'Thai', nativeName: 'ไทย'),
      LanguageOption(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
      LanguageOption(code: 'tk', name: 'Turkmen', nativeName: 'Türkmen'),
      LanguageOption(code: 'uk', name: 'Ukrainian', nativeName: 'Українська'),
      LanguageOption(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
      LanguageOption(code: 'ug', name: 'Uyghur', nativeName: 'ئۇيغۇرچە'),
      LanguageOption(code: 'uz', name: 'Uzbek', nativeName: 'zbek'),
      LanguageOption(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
      LanguageOption(code: 'cy', name: 'Welsh', nativeName: 'Cymraeg'),
      LanguageOption(code: 'xh', name: 'Xhosa', nativeName: 'isiXhosa'),
      LanguageOption(code: 'yi', name: 'Yiddish', nativeName: 'ייִדיש'),
      LanguageOption(code: 'yo', name: 'Yoruba', nativeName: 'Yorùbá'),
      LanguageOption(code: 'zu', name: 'Zulu', nativeName: 'isiZulu'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      children: [
        // Playback Settings Section
        SettingsSection(
          compact:true,
          context: context,
          title: 'Playback',
          items: [
            // Episode Completion Threshold
            SettingsSlider(
              icon: Iconsax.timer_1,
              title: 'Episode Completion',
              description: 'Mark as watched at',
              value: playerSettings.episodeCompletionThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              valueDisplay: (value) => '${(value * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
                      playerSettings.copyWith(
                          episodeCompletionThreshold: value),
                    );
              },
              compact: true,
            ),

            // Playback Speed
            SettingsItem(
              icon: Iconsax.forward,
              title: 'Playback Speed',
              description:
                  'Default speed: ${playerSettings.defaultPlaybackSpeed}x',
              onTap: () => _setPlaybackSpeed(context, ref),
              compact: true,
            ),

            // Auto Play Next Episode
            SettingsSwitch(
              icon: Iconsax.play_circle,
              title: 'Auto Play Next Episode',
              description: 'Automatically play the next episode',
              value: playerSettings.autoPlayNextEpisode,
              onChanged: (value) {
                ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
                      playerSettings.copyWith(autoPlayNextEpisode: value),
                    );
              },
              compact: true,
            ),

            // Skip Intro
            SettingsSwitch(
              icon: Iconsax.forward,
              title: 'Skip Intro',
              description: 'Automatically skip anime intros when detected',
              value: playerSettings.skipIntro,
              onChanged: (value) {
                ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
                      playerSettings.copyWith(skipIntro: value),
                    );
              },
              compact: true,
            ),

            // Skip Outro
            SettingsSwitch(
              icon: Iconsax.forward,
              title: 'Skip Outro',
              description: 'Automatically skip anime outros when detected',
              value: playerSettings.skipOutro,
              onChanged: (value) {
                ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
                      playerSettings.copyWith(skipOutro: value),
                    );
              },
              compact: true,
            ),
          ],
        ),

        // Subtitle Settings Section
        SettingsSection(
          compact:true,
          context: context,
          title: 'Subtitles',
          items: [
            // Prefer Subtitles
            SettingsSwitch(
              icon: Iconsax.subtitle,
              title: 'Prefer Subtitles',
              description: 'Default to subtitled version when available',
              value: playerSettings.preferSubtitles,
              onChanged: (value) {
                ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
                      playerSettings.copyWith(preferSubtitles: value),
                    );
              },
              compact: true,
            ),

            // Subtitle Appearance
            SettingsItem(
              icon: Iconsax.text,
              title: 'Subtitle Appearance',
              description:
                  'Font size: ${playerSettings.subtitleFontSize.round()}px, Color: #${playerSettings.subtitleTextColor.toRadixString(16).substring(2).toUpperCase()}',
              onTap: () => _setSubtitleAppearance(context, ref),
              compact: true,
            ),
          ],
        ),

        // // Language Settings Section
        // SettingsSection(
        //   context: context,
        //   title: 'Language',
        //   compact: true,
        //   items: [
        //     SettingsItemDropdown<String>(
        //       icon: Iconsax.language_square,
        //       title: "Preferred Language",
        //       description: "Set default audio/subtitle language",
        //       options: allLanguages.map((language) => language.name).toList(),
        //       selectedOption: "English",
        //       itemDisplay: (language) => language,
        //       onChanged: (newLanguage) {
        //         // Language preference will be implemented in a future update
        //       },
        //     ),
        //   ],
        // ),

        // Quality Settings Section
        SettingsSection(
          compact:true,
          context: context,
          title: 'Quality',
          items: [
            SettingsItem(
              onTap: () {},
              icon: Iconsax.video_tick,
              title: 'Video Quality',
              description: 'Default streaming quality settings',
              disabled: true,
              compact: true,
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // This method is no longer needed as we're using SettingsSlider directly

  void _setPlaybackSpeed(BuildContext context, WidgetRef ref) async {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;
    double tempSpeed = playerSettings.defaultPlaybackSpeed;
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

    if (newSpeed != null && newSpeed != playerSettings.defaultPlaybackSpeed) {
      ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
            playerSettings.copyWith(defaultPlaybackSpeed: newSpeed),
          );
    }
  }

  void _setSubtitleAppearance(BuildContext context, WidgetRef ref) async {
    final playerSettings = ref.read(playerSettingsProvider).playerSettings;
    double tempFontSize = playerSettings.subtitleFontSize;
    Color tempTextColor = Color(playerSettings.subtitleTextColor);
    double tempBackgroundOpacity = playerSettings.subtitleBackgroundOpacity;
    bool tempHasShadow = playerSettings.subtitleHasShadow;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Predefined color options for better UX
    final List<Color> colorOptions = [
      Colors.white,
      Colors.yellow,
      Colors.lightGreenAccent,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
    ];

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
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: tempBackgroundOpacity),
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/subtitle_preview_bg.jpg'),
                          fit: BoxFit.cover,
                          opacity: 0.7,
                        ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Font Size', style: theme.textTheme.bodyMedium),
                        Text(
                          '${tempFontSize.round()}px',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: tempFontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 12,
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.surfaceContainerHighest,
                        onChanged: (value) {
                          setDialogState(() {
                            tempFontSize = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Text Color
                    Text('Text Color', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...colorOptions.map((color) => GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  tempTextColor = color;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: tempTextColor == color
                                        ? colorScheme.primary
                                        : Colors.grey,
                                    width: tempTextColor == color ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )),
                        // Custom color option
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
                              color: theme.colorScheme.surface,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Background Opacity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Background Opacity',
                            style: theme.textTheme.bodyMedium),
                        Text(
                          '${(tempBackgroundOpacity * 100).round()}%',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: tempBackgroundOpacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.surfaceContainerHighest,
                        onChanged: (value) {
                          setDialogState(() {
                            tempBackgroundOpacity = value;
                          });
                        },
                      ),
                    ),

                    // Shadow Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Text Shadow',
                          style: theme.textTheme.bodyMedium),
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
      // Convert color to int manually to avoid using deprecated .value
      final int colorValue = (tempTextColor.alpha << 24) |
          (tempTextColor.red << 16) |
          (tempTextColor.green << 8) |
          tempTextColor.blue;

      ref.read(playerSettingsProvider.notifier).updatePlayerSettings(
            playerSettings.copyWith(
              subtitleFontSize: tempFontSize,
              subtitleTextColor: colorValue,
              subtitleBackgroundOpacity: tempBackgroundOpacity,
              subtitleHasShadow: tempHasShadow,
            ),
          );
    }
  }
}

// Language option class to store language information
class LanguageOption {
  final String code; // ISO 639-1 language code
  final String name; // English name
  final String nativeName; // Name in its own language

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  @override
  String toString() => '$name ($nativeName)';
}
