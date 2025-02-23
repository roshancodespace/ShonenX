import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      ThemeSettingsScreenState();
}

class ThemeSettingsScreenState
    extends ConsumerState<ThemeSettingsScreen> {
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

  // Expansion states
  final Map<String, bool> _expandedSections = {
    'Theme': true,
    'Material Design': false,
    'Colors': false,
    'Components': false,
    'Typography': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    final settings = _settingsBox?.getSettings()?.themeSettings;
    setState(() {
      _isDarkMode = settings?.themeMode != 'light';
      _useAmoledBlack = settings?.amoled ?? false;
      _flexScheme = settings?.flexSchemeEnum ?? FlexScheme.red;
      _useMaterial3 = settings?.useMaterial3 ?? true;
      _useSubThemes = settings?.useSubThemes ?? true;
      _surfaceModeLight = settings?.surfaceModeLight ?? 0;
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
    _settingsBox?.updateThemeSettings(
      ThemeSettingsModel(
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_1, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExpandableSection('Theme', _buildThemeSection()),
          _buildExpandableSection('Material Design', _buildMaterialSection()),
          _buildExpandableSection('Colors', _buildColorsSection()),
          _buildExpandableSection('Components', _buildComponentsSection()),
          _buildExpandableSection('Typography', _buildTypographySection()),
          _buildColorSchemeTile(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedSections[title] ?? false;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          1,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _expandedSections[title] = expanded);
        },
        childrenPadding: const EdgeInsets.all(8),
        children: [content],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      children: [
        _SettingsSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Switch to dark theme',
          icon: Iconsax.moon,
          value: _isDarkMode,
          onChanged: (value) {
            _isDarkMode = value;
            _updateAppearanceSettings();
          },
        ),
        if (_isDarkMode)
          _SettingsSwitchTile(
            title: 'AMOLED Dark',
            subtitle: 'Use pure black for dark mode',
            icon: Iconsax.colorfilter,
            value: _useAmoledBlack,
            onChanged: (value) {
              _useAmoledBlack = value;
              _updateAppearanceSettings();
            },
          ),
      ],
    );
  }

  Widget _buildMaterialSection() {
    return Column(
      children: [
        _SettingsSwitchTile(
          title: 'Material 3',
          subtitle: 'Enable Material 3 design',
          icon: Iconsax.designtools,
          value: _useMaterial3,
          onChanged: (value) {
            _useMaterial3 = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSwitchTile(
          title: 'Sub-themes',
          subtitle: 'Apply theme to all components',
          icon: Iconsax.brush_2,
          value: _useSubThemes,
          onChanged: (value) {
            _useSubThemes = value;
            _updateAppearanceSettings();
          },
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    return Column(
      children: [
        _SettingsSwitchTile(
          title: 'Use Key Colors',
          subtitle: 'Apply key colors to surfaces',
          icon: Iconsax.color_swatch,
          value: _useKeyColors,
          onChanged: (value) {
            _useKeyColors = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSwitchTile(
          title: 'Use Tertiary Colors',
          subtitle: 'Enable tertiary color palette',
          icon: Iconsax.colorfilter,
          value: _useTertiary,
          onChanged: (value) {
            _useTertiary = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSwitchTile(
          title: 'Swap Light Colors',
          subtitle: 'Swap primary/secondary in light mode',
          icon: Iconsax.arrange_square,
          value: _swapLightColors,
          onChanged: (value) {
            _swapLightColors = value;
            _updateAppearanceSettings();
          },
        ),
        if (_isDarkMode)
          _SettingsSwitchTile(
            title: 'Swap Dark Colors',
            subtitle: 'Swap primary/secondary in dark mode',
            icon: Iconsax.arrange_square,
            value: _swapDarkColors,
            onChanged: (value) {
              _swapDarkColors = value;
              _updateAppearanceSettings();
            },
          ),
        _SettingsSliderTile(
          title: 'Color Blend Level',
          value: _blendLevel.toDouble(),
          min: 0,
          max: 40,
          divisions: 40,
          suffix: '',
          onChanged: (value) {
            _blendLevel = value.toInt();
            _updateAppearanceSettings();
          },
        ),
      ],
    );
  }

  Widget _buildComponentsSection() {
    return Column(
      children: [
        _SettingsSwitchTile(
          title: 'Colored App Bar',
          subtitle: 'Apply theme colors to app bar',
          icon: Iconsax.arrow_circle_up,
          value: _useAppbarColors,
          onChanged: (value) {
            _useAppbarColors = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSliderTile(
          title: 'App Bar Opacity',
          value: _appBarOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          suffix: '%',
          onChanged: (value) {
            _appBarOpacity = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSwitchTile(
          title: 'Transparent Status Bar',
          subtitle: 'Make status bar transparent',
          icon: Iconsax.status,
          value: _transparentStatusBar,
          onChanged: (value) {
            _transparentStatusBar = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSliderTile(
          title: 'Border Radius',
          value: _defaultRadius,
          min: 0,
          max: 24,
          divisions: 24,
          suffix: 'dp',
          onChanged: (value) {
            _defaultRadius = value;
            _updateAppearanceSettings();
          },
        ),
        _SettingsSwitchTile(
          title: 'Tooltip Background',
          subtitle: 'Match tooltips to background',
          icon: Iconsax.message_question,
          value: _tooltipsMatchBackground,
          onChanged: (value) {
            _tooltipsMatchBackground = value;
            _updateAppearanceSettings();
          },
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    return Column(
      children: [
        _SettingsSwitchTile(
          title: 'Custom Typography',
          subtitle: 'Use custom text theme',
          icon: Iconsax.text,
          value: _useTextTheme,
          onChanged: (value) {
            _useTextTheme = value;
            _updateAppearanceSettings();
          },
        ),
      ],
    );
  }

  Widget _buildColorSchemeTile() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Iconsax.colorfilter,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('Color Scheme',
            style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Iconsax.arrow_right_3,
            color: Theme.of(context).colorScheme.onSurface),
        onTap: _showColorSchemeModal,
      ),
    );
  }

  void _showColorSchemeModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
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
                isSelected: _flexScheme == scheme,
                onSelected: (selectedScheme) {
                  _flexScheme = selectedScheme;
                  _updateAppearanceSettings();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
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
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SettingsSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(1)}$suffix',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceVariant,
            onChanged: onChanged,
          ),
        ],
      ),
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
                      color: colorScheme.primary.withOpacity(0.2),
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
