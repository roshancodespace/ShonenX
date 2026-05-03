import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final notifier = ref.read(themePrefsProvider.notifier);

    return AppScaffold(
      title: 'Appearance',
      body: ListView(
        children: [
          SettingsSection(
            title: 'Display',
            children: [
              SettingsSegmentedTile<ThemeMode>(
                title: 'Theme Mode',
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themePrefs.themeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  notifier.updateTheme(
                    (s) => s.copyWith(themeMode: selection.first),
                  );
                },
              ),
              SettingsSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Pure Black Dark Mode',
                subtitle: 'Saves battery on OLED screens',
                value: themePrefs.useAmoled,
                onChanged: themePrefs.themeMode == ThemeMode.light
                    ? null
                    : (val) => notifier.updateTheme(
                        (s) => s.copyWith(useAmoled: val),
                      ),
              ),
              SettingsSwitchTile(
                icon: Icons.palette_outlined,
                title: 'Dynamic Color',
                subtitle: 'Uses wallpaper colors',
                value: themePrefs.useDynamic,
                onChanged: (val) =>
                    notifier.updateTheme((s) => s.copyWith(useDynamic: val)),
              ),
            ],
          ),
          SettingsSection(
            title: 'Color Scheme',
            children: [
              ...FlexScheme.values.map(
                (scheme) => SettingsRadioTile<FlexScheme>(
                  title: scheme.name.toUpperCase(),
                  value: scheme,
                  groupValue: themePrefs.flexScheme,
                  onChanged: (val) =>
                      notifier.updateTheme((s) => s.copyWith(flexScheme: val)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
