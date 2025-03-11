import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

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

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExpandableSection(
          context,
          'Theme',
          _buildThemeSection(context, settingsState.themeSettings, notifier),
        ),
        _buildExpandableSection(
          context,
          'Material Design',
          _buildMaterialSection(context, settingsState.themeSettings, notifier),
        ),
        _buildExpandableSection(
          context,
          'Colors',
          _buildColorsSection(context, settingsState.themeSettings, notifier),
        ),
        _buildExpandableSection(
          context,
          'Components',
          _buildComponentsSection(
              context, settingsState.themeSettings, notifier),
        ),
        _buildExpandableSection(
          context,
          'Typography',
          _buildTypographySection(
              context, settingsState.themeSettings, notifier),
        ),
        _buildColorSchemeTile(context, settingsState.themeSettings, notifier),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildExpandableSection(
      BuildContext context, String title, Widget content) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        initiallyExpanded: title == 'Theme', // Only 'Theme' expanded by default
        childrenPadding: const EdgeInsets.all(8),
        children: [content],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeSettingsModel settings,
      ThemeSettingsNotifier notifier) {
    return Column(
      children: [
        _buildSwitchItem(
          context,
          'Dark Mode',
          'Switch to dark theme',
          Iconsax.moon,
          settings.themeMode != 'light',
          (value) => notifier.updateThemeSettings(
              settings.copyWith(themeMode: value ? 'dark' : 'light')),
        ),
        if (settings.themeMode != 'light')
          _buildSwitchItem(
            context,
            'AMOLED Dark',
            'Use pure black for dark mode',
            Iconsax.colorfilter,
            settings.amoled,
            (value) =>
                notifier.updateThemeSettings(settings.copyWith(amoled: value)),
          ),
      ],
    );
  }

  Widget _buildMaterialSection(BuildContext context,
      ThemeSettingsModel settings, ThemeSettingsNotifier notifier) {
    return Column(
      children: [
        _buildSwitchItem(
          context,
          'Material 3',
          'Enable Material 3 design',
          Iconsax.designtools,
          settings.useMaterial3,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(useMaterial3: value)),
        ),
        _buildSwitchItem(
          context,
          'Sub-themes',
          'Apply theme to all components',
          Iconsax.brush_2,
          settings.useSubThemes,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(useSubThemes: value)),
        ),
      ],
    );
  }

  Widget _buildColorsSection(BuildContext context, ThemeSettingsModel settings,
      ThemeSettingsNotifier notifier) {
    return Column(
      children: [
        _buildSwitchItem(
          context,
          'Use Key Colors',
          'Apply key colors to surfaces',
          Iconsax.color_swatch,
          settings.useKeyColors,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(useKeyColors: value)),
        ),
        _buildSwitchItem(
          context,
          'Use Tertiary Colors',
          'Enable tertiary color palette',
          Iconsax.colorfilter,
          settings.useTertiary,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(useTertiary: value)),
        ),
        _buildSwitchItem(
          context,
          'Swap Light Colors',
          'Swap primary/secondary in light mode',
          Iconsax.arrange_square,
          settings.swapLightColors,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(swapLightColors: value)),
        ),
        if (settings.themeMode != 'light')
          _buildSwitchItem(
            context,
            'Swap Dark Colors',
            'Swap primary/secondary in dark mode',
            Iconsax.arrange_square,
            settings.swapDarkColors,
            (value) => notifier
                .updateThemeSettings(settings.copyWith(swapDarkColors: value)),
          ),
        _buildSliderItem(
          context,
          'Color Blend Level',
          settings.blendLevel.toDouble(),
          0,
          40,
          40,
          '',
          (value) => notifier.updateThemeSettings(
              settings.copyWith(blendLevel: value.toInt())),
        ),
      ],
    );
  }

  Widget _buildComponentsSection(BuildContext context,
      ThemeSettingsModel settings, ThemeSettingsNotifier notifier) {
    return Column(
      children: [
        _buildSwitchItem(
          context,
          'Colored App Bar',
          'Apply theme colors to app bar',
          Iconsax.arrow_circle_up,
          settings.useAppbarColors,
          (value) => notifier
              .updateThemeSettings(settings.copyWith(useAppbarColors: value)),
        ),
        _buildSliderItem(
          context,
          'App Bar Opacity',
          settings.appBarOpacity,
          0,
          1,
          20,
          '%',
          (value) => notifier
              .updateThemeSettings(settings.copyWith(appBarOpacity: value)),
        ),
        _buildSwitchItem(
          context,
          'Transparent Status Bar',
          'Make status bar transparent',
          Iconsax.status,
          settings.transparentStatusBar,
          (value) => notifier.updateThemeSettings(
              settings.copyWith(transparentStatusBar: value)),
        ),
        _buildSliderItem(
          context,
          'Border Radius',
          settings.defaultRadius,
          0,
          24,
          24,
          'dp',
          (value) => notifier
              .updateThemeSettings(settings.copyWith(defaultRadius: value)),
        ),
        _buildSwitchItem(
          context,
          'Tooltip Background',
          'Match tooltips to background',
          Iconsax.message_question,
          settings.tooltipsMatchBackground,
          (value) => notifier.updateThemeSettings(
              settings.copyWith(tooltipsMatchBackground: value)),
        ),
      ],
    );
  }

  Widget _buildTypographySection(BuildContext context,
      ThemeSettingsModel settings, ThemeSettingsNotifier notifier) {
    return _buildSwitchItem(
      context,
      'Custom Typography',
      'Use custom text theme',
      Iconsax.text,
      settings.useTextTheme,
      (value) =>
          notifier.updateThemeSettings(settings.copyWith(useTextTheme: value)),
    );
  }

  Widget _buildColorSchemeTile(BuildContext context,
      ThemeSettingsModel settings, ThemeSettingsNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SettingsItem(
        icon: Iconsax.colorfilter,
        title: 'Color Scheme',
        description: 'Select a color scheme',
        onTap: () => _showColorSchemeModal(context, settings, notifier),
      ),
    );
  }

  void _showColorSchemeModal(BuildContext context, ThemeSettingsModel settings,
      ThemeSettingsNotifier notifier) {
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
                isSelected: settings.flexSchemeEnum == scheme,
                onSelected: (selectedScheme) {
                  notifier.updateThemeSettings(
                      settings.copyWith(colorScheme: selectedScheme.name));
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSwitchItem(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsItem(
      icon: icon,
      title: title,
      description: description,
      onTap: () => onChanged(!value),
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildSliderItem(
      BuildContext context,
      String title,
      double value,
      double min,
      double max,
      int divisions,
      String suffix,
      ValueChanged<double> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          icon: Iconsax.slider,
          title: title,
          description: '${value.toStringAsFixed(1)}$suffix',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceContainerHighest,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Reused SettingsItem from previous screens
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool disabled;
  final Widget? child;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.disabled = false,
    this.child,
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
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// _SimpleColorSchemeCard remains unchanged
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
