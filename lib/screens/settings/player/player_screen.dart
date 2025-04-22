import 'package:cached_network_image/cached_network_image.dart';
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
    double tempShadowOpacity = playerSettings.subtitleShadowOpacity ?? 0.8;
    double tempShadowBlur = playerSettings.subtitleShadowBlur ?? 4.0;
    String tempFontFamily = playerSettings.subtitleFontFamily ?? 'Default';
    int tempPosition = playerSettings.subtitlePosition == 'bottom'
        ? 2
        : playerSettings.subtitlePosition == 'top'
            ? 0
            : 1; // 0=top, 1=middle, 2=bottom
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
      Colors.redAccent,
      Colors.purpleAccent,
    ];

    final fontFamilies = [
      'Default',
      'Roboto',
      'Open Sans',
      'Montserrat',
      'Comic Sans MS',
    ];

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar at top
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtitle Appearance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Reset button
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempFontSize = 16.0;
                                  tempTextColor = Colors.white;
                                  tempBackgroundOpacity = 0.3;
                                  tempHasShadow = true;
                                  tempShadowOpacity = 0.8;
                                  tempShadowBlur = 4.0;
                                  tempFontFamily = 'Default';
                                  tempPosition = 2;
                                });
                              },
                              icon: const Icon(Icons.restart_alt),
                              tooltip: 'Reset to defaults',
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Preview section
                  Container(
                    height: 140,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: CachedNetworkImageProvider(
                            'https://m.media-amazon.com/images/M/MV5BNGUxMDU1MDUtODI5My00NmY4LTkxYTMtZjZlMzU3YTYwNGUzXkEyXkFqcGc@._V1_QL75_UX500_CR0,0,500,281_.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Positioned based on selected position
                        Positioned(
                          bottom: tempPosition == 2 ? 16 : null,
                          top: tempPosition == 0 ? 16 : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withOpacity(tempBackgroundOpacity),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'This is how your subtitles will look',
                              style: TextStyle(
                                fontSize: tempFontSize,
                                color: tempTextColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: tempFontFamily != 'Default'
                                    ? tempFontFamily
                                    : null,
                                shadows: tempHasShadow
                                    ? [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: tempShadowBlur,
                                          color: Colors.black
                                              .withOpacity(tempShadowOpacity),
                                        ),
                                      ]
                                    : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Settings Content with TabBar
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: const [
                              Tab(text: 'Basic'),
                              Tab(text: 'Advanced'),
                              Tab(text: 'Presets'),
                            ],
                            labelColor: colorScheme.primary,
                            unselectedLabelColor: colorScheme.onSurfaceVariant,
                            indicatorColor: colorScheme.primary,
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Basic Settings Tab
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Font Size
                                      _settingHeader(
                                        'Font Size',
                                        '${tempFontSize.round()}px',
                                        theme,
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 8),
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        child: Slider(
                                          value: tempFontSize,
                                          min: 12.0,
                                          max: 28.0,
                                          divisions: 16,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              tempFontSize = value;
                                            });
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Text Color
                                      Text(
                                        'Text Color',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          ...colorOptions
                                              .map((color) => _colorOption(
                                                    color: color,
                                                    isSelected:
                                                        tempTextColor == color,
                                                    onTap: () {
                                                      setDialogState(() {
                                                        tempTextColor = color;
                                                      });
                                                    },
                                                    colorScheme: colorScheme,
                                                  )),
                                          _customColorButton(
                                            context: context,
                                            onColorSelected: (color) {
                                              setDialogState(() {
                                                tempTextColor = color;
                                              });
                                            },
                                            theme: theme,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Background Opacity
                                      _settingHeader(
                                        'Background Opacity',
                                        '${(tempBackgroundOpacity * 100).round()}%',
                                        theme,
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 8),
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        child: Slider(
                                          value: tempBackgroundOpacity,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 20,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              tempBackgroundOpacity = value;
                                            });
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Position
                                      Text(
                                        'Subtitle Position',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _positionButton(
                                            label: 'Top',
                                            isSelected: tempPosition == 0,
                                            onTap: () {
                                              setDialogState(() {
                                                tempPosition = 0;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                          ),
                                          _positionButton(
                                            label: 'Middle',
                                            isSelected: tempPosition == 1,
                                            onTap: () {
                                              setDialogState(() {
                                                tempPosition = 1;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                          ),
                                          _positionButton(
                                            label: 'Bottom',
                                            isSelected: tempPosition == 2,
                                            onTap: () {
                                              setDialogState(() {
                                                tempPosition = 2;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Text Shadow Toggle
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Text Shadow',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        subtitle: Text(
                                          'Improves readability on bright scenes',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        value: tempHasShadow,
                                        activeColor: colorScheme.primary,
                                        onChanged: (value) {
                                          setDialogState(() {
                                            tempHasShadow = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Advanced Settings Tab
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Font Family
                                      Text(
                                        'Font Family',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: colorScheme.outline),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          value: tempFontFamily,
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                          items:
                                              fontFamilies.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontFamily: value != 'Default'
                                                      ? value
                                                      : null,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() {
                                                tempFontFamily = newValue;
                                              });
                                            }
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Shadow Settings (only if shadow is enabled)
                                      if (tempHasShadow) ...[
                                        _settingHeader(
                                          'Shadow Opacity',
                                          '${(tempShadowOpacity * 100).round()}%',
                                          theme,
                                        ),
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 8),
                                            activeTrackColor:
                                                colorScheme.primary,
                                            inactiveTrackColor: colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                          child: Slider(
                                            value: tempShadowOpacity,
                                            min: 0.0,
                                            max: 1.0,
                                            divisions: 10,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                tempShadowOpacity = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _settingHeader(
                                          'Shadow Blur',
                                          '${tempShadowBlur.toStringAsFixed(1)}px',
                                          theme,
                                        ),
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 8),
                                            activeTrackColor:
                                                colorScheme.primary,
                                            inactiveTrackColor: colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                          child: Slider(
                                            value: tempShadowBlur,
                                            min: 1.0,
                                            max: 10.0,
                                            divisions: 18,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                tempShadowBlur = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 24),

                                      // Advanced toggles
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Bold Text',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        value: true,
                                        activeColor: colorScheme.primary,
                                        onChanged: (value) {
                                          // Add handler for this setting
                                        },
                                      ),

                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Force Uppercase',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        value: false,
                                        activeColor: colorScheme.primary,
                                        onChanged: (value) {
                                          // Add handler for this setting
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Presets Tab
                                ListView(
                                  padding: const EdgeInsets.all(20),
                                  children: [
                                    _presetCard(
                                      title: 'Standard',
                                      description:
                                          'White text with subtle background',
                                      fontSize: 16.0,
                                      textColor: Colors.white,
                                      backgroundOpacity: 0.3,
                                      hasShadow: true,
                                      isActive: tempFontSize == 16.0 &&
                                          tempTextColor == Colors.white &&
                                          tempBackgroundOpacity == 0.3 &&
                                          tempHasShadow == true,
                                      onTap: () {
                                        setDialogState(() {
                                          tempFontSize = 16.0;
                                          tempTextColor = Colors.white;
                                          tempBackgroundOpacity = 0.3;
                                          tempHasShadow = true;
                                          tempShadowOpacity = 0.8;
                                          tempShadowBlur = 4.0;
                                        });
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    _presetCard(
                                      title: 'High Contrast',
                                      description:
                                          'Yellow text with dark background',
                                      fontSize: 18.0,
                                      textColor: Colors.yellow,
                                      backgroundOpacity: 0.6,
                                      hasShadow: true,
                                      isActive: tempFontSize == 18.0 &&
                                          tempTextColor == Colors.yellow &&
                                          tempBackgroundOpacity == 0.6 &&
                                          tempHasShadow == true,
                                      onTap: () {
                                        setDialogState(() {
                                          tempFontSize = 18.0;
                                          tempTextColor = Colors.yellow;
                                          tempBackgroundOpacity = 0.6;
                                          tempHasShadow = true;
                                          tempShadowOpacity = 0.9;
                                          tempShadowBlur = 3.0;
                                        });
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    _presetCard(
                                      title: 'Minimalist',
                                      description:
                                          'White text with no background',
                                      fontSize: 16.0,
                                      textColor: Colors.white,
                                      backgroundOpacity: 0.0,
                                      hasShadow: true,
                                      isActive: tempFontSize == 16.0 &&
                                          tempTextColor == Colors.white &&
                                          tempBackgroundOpacity == 0.0 &&
                                          tempHasShadow == true,
                                      onTap: () {
                                        setDialogState(() {
                                          tempFontSize = 16.0;
                                          tempTextColor = Colors.white;
                                          tempBackgroundOpacity = 0.0;
                                          tempHasShadow = true;
                                          tempShadowOpacity = 1.0;
                                          tempShadowBlur = 6.0;
                                        });
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    _presetCard(
                                      title: 'Large & Clear',
                                      description:
                                          'Large text with solid background',
                                      fontSize: 22.0,
                                      textColor: Colors.white,
                                      backgroundOpacity: 0.8,
                                      hasShadow: false,
                                      isActive: tempFontSize == 22.0 &&
                                          tempTextColor == Colors.white &&
                                          tempBackgroundOpacity == 0.8 &&
                                          tempHasShadow == false,
                                      onTap: () {
                                        setDialogState(() {
                                          tempFontSize = 22.0;
                                          tempTextColor = Colors.white;
                                          tempBackgroundOpacity = 0.8;
                                          tempHasShadow = false;
                                        });
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    _presetCard(
                                      title: 'Netflix Style',
                                      description:
                                          'White text with minimal shadow',
                                      fontSize: 18.0,
                                      textColor: Colors.white,
                                      backgroundOpacity: 0.0,
                                      hasShadow: true,
                                      isActive: tempFontSize == 18.0 &&
                                          tempTextColor == Colors.white &&
                                          tempBackgroundOpacity == 0.0 &&
                                          tempHasShadow == true,
                                      onTap: () {
                                        setDialogState(() {
                                          tempFontSize = 18.0;
                                          tempTextColor = Colors.white;
                                          tempBackgroundOpacity = 0.0;
                                          tempHasShadow = true;
                                          tempShadowOpacity = 0.9;
                                          tempShadowBlur = 2.0;
                                        });
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Update settings if changed
    if (updated == true) {
      ref
          .read(playerSettingsProvider.notifier)
          .updatePlayerSettings(playerSettings.copyWith(
            subtitleFontSize: tempFontSize,
            subtitleTextColor: tempTextColor.value,
            subtitleBackgroundOpacity: tempBackgroundOpacity,
            subtitleHasShadow: tempHasShadow,
            subtitleShadowOpacity: tempShadowOpacity,
            subtitleShadowBlur: tempShadowBlur,
            subtitleFontFamily: tempFontFamily,
            subtitlePosition: tempPosition,
          ));
    }
  }

// Helper widgets
  Widget _settingHeader(String title, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _colorOption({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  Widget _customColorButton({
    required BuildContext context,
    required ValueChanged<Color> onColorSelected,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () async {
        final newColor = await showDialog<Color>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pick Custom Color'),
            content: SingleChildScrollView(
              child: MaterialPicker(
                pickerColor: Colors.white,
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
          onColorSelected(newColor);
        }
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _positionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _presetCard({
    required String title,
    required String description,
    required double fontSize,
    required Color textColor,
    required double backgroundOpacity,
    required bool hasShadow,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Preview circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(backgroundOpacity),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: fontSize * 0.75,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      shadows: hasShadow
                          ? [
                              const Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 4,
                                color: Colors.black,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isActive)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
