import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

// Riverpod provider for theme settings
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>((ref) {
  return ThemeSettingsNotifier();
});

class ThemeSettingsState {
  final ThemeSettingsModel themeSettings;
  final bool isLoading;

  ThemeSettingsState({required this.themeSettings, this.isLoading = false});

  ThemeSettingsState copyWith(
      {ThemeSettingsModel? themeSettings, bool? isLoading}) {
    return ThemeSettingsState(
      themeSettings: themeSettings ?? this.themeSettings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsState> {
  SettingsBox? _settingsBox;

  ThemeSettingsNotifier()
      : super(ThemeSettingsState(themeSettings: ThemeSettingsModel()));

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
      state = state.copyWith(themeSettings: settings.themeSettings);
    }
  }

  void updateThemeSettings(ThemeSettingsModel settings) {
    state = state.copyWith(themeSettings: settings);
    _settingsBox?.updateThemeSettings(settings);
  }
}

// Section configuration model
class SectionConfig {
  final String title;
  final List<SettingItemConfig> items;

  SectionConfig({required this.title, required this.items});
}

class SettingItemConfig {
  final String title;
  final String description;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSlider;
  final double? sliderValue;
  final double? sliderMin;
  final double? sliderMax;
  final int? sliderDivisions;
  final String? sliderSuffix;
  final ValueChanged<double>? onSliderChanged;

  SettingItemConfig({
    required this.title,
    required this.description,
    required this.icon,
    this.trailing,
    this.onTap,
    this.isSlider = false,
    this.sliderValue,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
    this.sliderSuffix,
    this.onSliderChanged,
  });
}

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    final sections =
        _buildSectionConfigs(context, settingsState.themeSettings, notifier);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == sections.length) {
          return SizedBox(height: MediaQuery.of(context).size.height * 0.15);
        }
        return SettingsSection(
          title: sections[index].title,
          items: sections[index].items,
        );
      },
    );
  }

  List<SectionConfig> _buildSectionConfigs(BuildContext context,
      ThemeSettingsModel settings, ThemeSettingsNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SectionConfig(
        title: 'Theme',
        items: [
          SettingItemConfig(
            title: 'Dark Mode',
            description: 'Switch to dark theme',
            icon: Iconsax.moon,
            trailing: Switch(
              value: settings.themeMode != 'light',
              onChanged: (value) => notifier.updateThemeSettings(
                  settings.copyWith(themeMode: value ? 'dark' : 'light')),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          if (settings.themeMode != 'light')
            SettingItemConfig(
              title: 'AMOLED Dark',
              description: 'Use pure black for dark mode',
              icon: Iconsax.colorfilter,
              trailing: Switch(
                value: settings.amoled,
                onChanged: (value) => notifier
                    .updateThemeSettings(settings.copyWith(amoled: value)),
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withOpacity(0.5),
              ),
            ),
        ],
      ),
      SectionConfig(
        title: 'Material Design',
        items: [
          SettingItemConfig(
            title: 'Material 3',
            description: 'Enable Material 3 design',
            icon: Iconsax.designtools,
            trailing: Switch(
              value: settings.useMaterial3,
              onChanged: (value) => notifier
                  .updateThemeSettings(settings.copyWith(useMaterial3: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          SettingItemConfig(
            title: 'Sub-themes',
            description: 'Apply theme to all components',
            icon: Iconsax.brush_2,
            trailing: Switch(
              value: settings.useSubThemes,
              onChanged: (value) => notifier
                  .updateThemeSettings(settings.copyWith(useSubThemes: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
      SectionConfig(
        title: 'Colors',
        items: [
          SettingItemConfig(
            title: 'Swap Light Colors',
            description: 'Swap primary/secondary in light mode',
            icon: Iconsax.arrange_square,
            trailing: Switch(
              value: settings.swapLightColors,
              onChanged: (value) => notifier.updateThemeSettings(
                  settings.copyWith(swapLightColors: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          if (settings.themeMode != 'light')
            SettingItemConfig(
              title: 'Swap Dark Colors',
              description: 'Swap primary/secondary in dark mode',
              icon: Iconsax.arrange_square,
              trailing: Switch(
                value: settings.swapDarkColors,
                onChanged: (value) => notifier.updateThemeSettings(
                    settings.copyWith(swapDarkColors: value)),
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withOpacity(0.5),
              ),
            ),
          SettingItemConfig(
            title: 'Color Blend Level',
            description: '${settings.blendLevel.toStringAsFixed(1)}',
            icon: Iconsax.slider,
            isSlider: true,
            sliderValue: settings.blendLevel.toDouble(),
            sliderMin: 0,
            sliderMax: 40,
            sliderDivisions: 40,
            sliderSuffix: '',
            onSliderChanged: (value) => notifier.updateThemeSettings(
                settings.copyWith(blendLevel: value.toInt())),
          ),
        ],
      ),
      SectionConfig(
        title: 'Components',
        items: [
          SettingItemConfig(
            title: 'App Bar Opacity',
            description:
                '${(settings.appBarOpacity * 100).toStringAsFixed(1)}%',
            icon: Iconsax.slider,
            isSlider: true,
            sliderValue: settings.appBarOpacity,
            sliderMin: 0,
            sliderMax: 1,
            sliderDivisions: 20,
            sliderSuffix: '%',
            onSliderChanged: (value) => notifier
                .updateThemeSettings(settings.copyWith(appBarOpacity: value)),
          ),
          SettingItemConfig(
            title: 'Transparent Status Bar',
            description: 'Make status bar transparent',
            icon: Iconsax.status,
            trailing: Switch(
              value: settings.transparentStatusBar,
              onChanged: (value) => notifier.updateThemeSettings(
                  settings.copyWith(transparentStatusBar: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          SettingItemConfig(
            title: 'Border Radius',
            description: '${settings.defaultRadius.toStringAsFixed(1)}dp',
            icon: Iconsax.slider,
            isSlider: true,
            sliderValue: settings.defaultRadius,
            sliderMin: 0,
            sliderMax: 24,
            sliderDivisions: 24,
            sliderSuffix: 'dp',
            onSliderChanged: (value) => notifier
                .updateThemeSettings(settings.copyWith(defaultRadius: value)),
          ),
          SettingItemConfig(
            title: 'Tooltip Background',
            description: 'Match tooltips to background',
            icon: Iconsax.message_question,
            trailing: Switch(
              value: settings.tooltipsMatchBackground,
              onChanged: (value) => notifier.updateThemeSettings(
                  settings.copyWith(tooltipsMatchBackground: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
      SectionConfig(
        title: 'Typography',
        items: [
          SettingItemConfig(
            title: 'Custom Typography',
            description: 'Use custom text theme',
            icon: Iconsax.text,
            trailing: Switch(
              value: settings.useTextTheme,
              onChanged: (value) => notifier
                  .updateThemeSettings(settings.copyWith(useTextTheme: value)),
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
      SectionConfig(
        title: 'Color Scheme',
        items: [
          SettingItemConfig(
            title: 'Color Scheme',
            description: 'Select a color scheme',
            icon: Iconsax.colorfilter,
            onTap: () => _showColorSchemeModal(context, settings, notifier),
          ),
        ],
      ),
    ];
  }

  void _showColorSchemeModal(BuildContext context, ThemeSettingsModel settings,
      ThemeSettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text('Select Color Scheme',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: FlexScheme.values.length,
                  itemBuilder: (context, index) {
                    final scheme = FlexScheme.values[index];
                    return _SimpleColorSchemeCard(
                      scheme: scheme,
                      isSelected: settings.flexSchemeEnum == scheme,
                      onSelected: (selectedScheme) {
                        notifier.updateThemeSettings(settings.copyWith(
                            colorScheme: selectedScheme.name));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingItemConfig> items;

  const SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        initiallyExpanded: title == 'Theme',
        childrenPadding: const EdgeInsets.all(16),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: items.map((item) => _buildItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildItem(BuildContext context, SettingItemConfig config) {
    final colorScheme = Theme.of(context).colorScheme;

    if (config.isSlider) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsItem(
            icon: config.icon,
            title: config.title,
            description: config.description,
            onTap: config.onTap ?? () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
              ),
              child: Slider(
                value: config.sliderValue!,
                min: config.sliderMin!,
                max: config.sliderMax!,
                divisions: config.sliderDivisions!,
                onChanged: config.onSliderChanged!,
              ),
            ),
          ),
        ],
      );
    }

    return SettingsItem(
      icon: config.icon,
      title: config.title,
      description: config.description,
      trailing: config.trailing,
      onTap: () => config.onTap ?? (config.trailing != null ? () {} : null),
    );
  }
}

class _SimpleColorSchemeCard extends StatelessWidget {
  final FlexScheme scheme;
  final bool isSelected;
  final ValueChanged<FlexScheme> onSelected;

  const _SimpleColorSchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.onSelected,
  });

  String _formatSchemeName(String name) {
    return name
        .splitMapJoin(
          RegExp(r'(?=[A-Z])'),
          onMatch: (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final schemeData = FlexThemeData.light(scheme: scheme).colorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onSelected(scheme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 6)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: schemeData.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: schemeData.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatSchemeName(scheme.name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
