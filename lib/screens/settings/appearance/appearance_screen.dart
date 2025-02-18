import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  late SettingsBox? _settingsBox;
  bool _isDarkMode = false;
  bool _useAmoledBlack = false;
  bool _useMaterial3 = true;
  FlexScheme _flexScheme = FlexScheme.deepPurple;
  bool _useSubThemes = true;
  double _surfaceModeLight = 0;
  double _surfaceModeDark = 0;
  bool _useKeyColors = true;
  bool _useAppbarColors = false;
  bool _isColorSchemesExpanded = false;

  // New settings
  bool _swapLightColors = false;
  bool _swapDarkColors = false;
  bool _useTertiary = true;
  int _blendLevel = 0;
  double _appBarOpacity = 1.0;
  bool _transparentStatusBar = false;
  double _tabBarOpacity = 1.0;
  double _bottomBarOpacity = 1.0;
  bool _tooltipsMatchBackground = false;
  double _defaultRadius = 12.0;
  bool _useTextTheme = true;
  FlexTabBarStyle _tabBarStyle = FlexTabBarStyle.forBackground;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    final settings = _settingsBox?.getSettings()?.appearanceSettings;
    setState(() {
      _isDarkMode = settings?.themeMode != 'light';
      _useAmoledBlack = settings?.amoled ?? false;
      _flexScheme = settings?.flexSchemeEnum ?? FlexScheme.red;
      _useMaterial3 = settings?.useMaterial3 ?? true;
      _useSubThemes = settings?.useSubThemes ?? true;
      _surfaceModeLight = settings?.surfaceModeDark ?? 0;
      _surfaceModeDark = settings?.surfaceModeDark ?? 0;
      _useKeyColors = settings?.useKeyColors ?? true;
      _useAppbarColors = settings?.useAppbarColors ?? false;
      _swapLightColors = settings?.swapLightColors ?? false;
      _swapDarkColors = settings?.swapDarkColors ?? false;
      _useTertiary = settings?.useTertiary ?? true;
      _blendLevel = settings?.blendLevel ?? 0;
      _appBarOpacity = settings?.appBarOpacity ?? 1.0;
      _transparentStatusBar = settings?.transparentStatusBar ?? false;
      _tabBarOpacity = settings?.tabBarOpacity ?? 1.0;
      _bottomBarOpacity = settings?.bottomBarOpacity ?? 1.0;
      _tooltipsMatchBackground = settings?.tooltipsMatchBackground ?? false;
      _defaultRadius = settings?.defaultRadius ?? 12.0;
      _useTextTheme = settings?.useTextTheme ?? true;
      _tabBarStyle =
          settings?.flexTabBarStyleEnum ?? FlexTabBarStyle.forBackground;
    });
  }

  void _updateAppearanceSettings() {
    setState(() {});
    _settingsBox?.updateAppearanceSettings(
      AppearanceSettingsModel(
        themeMode: _isDarkMode ? 'dark' : 'light',
        amoled: _useAmoledBlack,
        colorScheme: _flexScheme.name,
        useMaterial3: _useMaterial3,
        useSubThemes: _useSubThemes,
        surfaceModeLight: _surfaceModeLight,
        surfaceModeDark: _surfaceModeDark,
        useKeyColors: _useKeyColors,
        useAppbarColors: _useAppbarColors,
        swapLightColors: _swapLightColors,
        swapDarkColors: _swapDarkColors,
        useTertiary: _useTertiary,
        blendLevel: _blendLevel,
        appBarOpacity: _appBarOpacity,
        transparentStatusBar: _transparentStatusBar,
        tabBarOpacity: _tabBarOpacity,
        bottomBarOpacity: _bottomBarOpacity,
        tooltipsMatchBackground: _tooltipsMatchBackground,
        defaultRadius: _defaultRadius,
        useTextTheme: _useTextTheme,
        tabBarStyle: _tabBarStyle.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text('Appearance',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          _buildThemeSection(),
          _buildColorSchemeSection(),
          _buildMaterialSection(),
          _buildColorsSection(),
          _buildComponentsSection(),
          _buildTypographySection(),
          SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Theme'),
        _SettingsSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Use dark theme',
          icon: Iconsax.moon,
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
              _updateAppearanceSettings();
            });
          },
        ),
        if (_isDarkMode)
          _SettingsSwitchTile(
            title: 'AMOLED Dark',
            subtitle: 'Use pure black theme',
            icon: Iconsax.colorfilter,
            value: _useAmoledBlack,
            onChanged: (value) {
              setState(() {
                _useAmoledBlack = value;
                _updateAppearanceSettings();
              });
            },
          ),
      ],
    );
  }

  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Material Design'),
        _SettingsSwitchTile(
          title: 'Material 3',
          subtitle: 'Use Material 3 design',
          icon: Iconsax.designtools,
          value: _useMaterial3,
          onChanged: (value) {
            setState(() {
              _useMaterial3 = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSwitchTile(
          title: 'Sub-themes',
          subtitle: 'Apply theme to all components',
          icon: Iconsax.brush_2,
          value: _useSubThemes,
          onChanged: (value) {
            setState(() {
              _useSubThemes = value;
              _updateAppearanceSettings();
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Colors'),
        _SettingsSwitchTile(
          title: 'Use Key Colors',
          subtitle: 'Use key colors for surfaces',
          icon: Iconsax.color_swatch,
          value: _useKeyColors,
          onChanged: (value) {
            setState(() {
              _useKeyColors = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSwitchTile(
          title: 'Use Tertiary Colors',
          subtitle: 'Enable tertiary color variations',
          icon: Iconsax.colorfilter,
          value: _useTertiary,
          onChanged: (value) {
            setState(() {
              _useTertiary = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSwitchTile(
          title: 'Swap Light Colors',
          subtitle: 'Swap primary and secondary in light mode',
          icon: Iconsax.arrange_square,
          value: _swapLightColors,
          onChanged: (value) {
            setState(() {
              _swapLightColors = value;
              _updateAppearanceSettings();
            });
          },
        ),
        if (_isDarkMode)
          _SettingsSwitchTile(
            title: 'Swap Dark Colors',
            subtitle: 'Swap primary and secondary in dark mode',
            icon: Iconsax.arrange_square,
            value: _swapDarkColors,
            onChanged: (value) {
              setState(() {
                _swapDarkColors = value;
                _updateAppearanceSettings();
              });
            },
          ),
        _SettingsSliderTile(
          title: 'Color Blend Level',
          value: _blendLevel.toDouble(),
          min: 0,
          max: 40,
          divisions: 40,
          onChanged: (value) {
            setState(() {
              _blendLevel = value.toInt();
              _updateAppearanceSettings();
            });
          },
        ),
      ],
    );
  }

  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Components'),
        _SettingsSwitchTile(
          title: 'Colored App Bar',
          subtitle: 'Use theme colors for app bar',
          icon: Iconsax.arrow_circle_up,
          value: _useAppbarColors,
          onChanged: (value) {
            setState(() {
              _useAppbarColors = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSliderTile(
          title: 'App Bar Opacity',
          value: _appBarOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() {
              _appBarOpacity = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSwitchTile(
          title: 'Transparent Status Bar',
          subtitle: 'Make status bar transparent',
          icon: Iconsax.status,
          value: _transparentStatusBar,
          onChanged: (value) {
            setState(() {
              _transparentStatusBar = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSliderTile(
          title: 'Border Radius',
          value: _defaultRadius,
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: (value) {
            setState(() {
              _defaultRadius = value;
              _updateAppearanceSettings();
            });
          },
        ),
        _SettingsSwitchTile(
          title: 'Tooltip Background',
          subtitle: 'Match tooltips with background color',
          icon: Iconsax.message_question,
          value: _tooltipsMatchBackground,
          onChanged: (value) {
            setState(() {
              _tooltipsMatchBackground = value;
              _updateAppearanceSettings();
            });
          },
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Typography'),
        _SettingsSwitchTile(
          title: 'Custom Typography',
          subtitle: 'Use custom text theme',
          icon: Iconsax.text,
          value: _useTextTheme,
          onChanged: (value) {
            setState(() {
              _useTextTheme = value;
              _updateAppearanceSettings();
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorSchemeSection() {
    return ListTile(
      title: const Text('Color Scheme'),
      leading: Icon(Iconsax.colorfilter, color: Theme.of(context).colorScheme.primary),
      trailing: Icon(Iconsax.arrow_right_3, color: Theme.of(context).colorScheme.primary),
      onTap: () => _showColorSchemeModal(),
    );
  }

  void _showColorSchemeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: FlexScheme.values.length,
            itemBuilder: (context, index) {
              final scheme = FlexScheme.values[index];
              return _SimpleColorSchemeCard(
                scheme: scheme,
                isSelected: _flexScheme == scheme,
                onSelected: (selectedScheme) {
                  setState(() {
                    _flexScheme = selectedScheme;
                    _updateAppearanceSettings();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onChanged(!value),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SettingsSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(scheme),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? schemeData.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: schemeData.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: schemeData.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatSchemeName(scheme.name),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
