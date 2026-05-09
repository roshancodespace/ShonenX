import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(themePrefsProvider.notifier);
    final isDark = themePrefs.themeMode == ThemeMode.dark;

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
                onSelectionChanged: (Set<ThemeMode> s) =>
                    notifier.updateTheme((p) => p.copyWith(themeMode: s.first)),
              ),
              SettingsSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Pure Black',
                subtitle: 'Saves battery on OLED screens',
                value: themePrefs.useAmoled,
                onChanged: themePrefs.themeMode == ThemeMode.light
                    ? null
                    : (v) =>
                          notifier.updateTheme((p) => p.copyWith(useAmoled: v)),
              ),
              SettingsSwitchTile(
                icon: Icons.palette_outlined,
                title: 'Dynamic Color',
                subtitle: 'Uses wallpaper colors',
                value: themePrefs.useDynamic,
                onChanged: (v) => notifier.updateTheme(
                  (p) => p.copyWith(
                    useDynamic: v,
                    clearExclusiveScheme: v,
                  ),
                ),
              ),
            ],
          ),
          if (!themePrefs.useDynamic) ...[
            SettingsSection(
              title: 'Color Schemes',
              children: [
                SettingsActionTile(
                  icon: Icons.colorize,
                  title: 'Standard Color Scheme',
                  subtitle: themePrefs.exclusiveScheme == null
                      ? FlexColor.schemes[themePrefs.flexScheme]?.name ??
                            'Default'
                      : 'Not active',
                  onTap: () => _openSchemePicker(
                    context,
                    themePrefs.flexScheme,
                    (scheme) => notifier.updateTheme(
                      (p) => p.copyWith(
                        flexScheme: scheme,
                        clearExclusiveScheme: true,
                      ),
                    ),
                    isDark,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (themePrefs.exclusiveScheme == null)
                        _SwatchStack(
                          colors: [cs.primary, cs.secondary, cs.tertiary],
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
                SettingsActionTile(
                  icon: Icons.auto_awesome,
                  title: 'Exclusive Scheme',
                  subtitle: themePrefs.exclusiveScheme != null
                      ? exclusiveSchemes[themePrefs.exclusiveScheme]?.name ??
                            'Unknown'
                      : 'Not active',
                  onTap: () => _openExclusiveSchemePicker(
                    context,
                    themePrefs.exclusiveScheme,
                    (key) => notifier.updateTheme(
                      (p) => p.copyWith(exclusiveScheme: key),
                    ),
                    isDark,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (themePrefs.exclusiveScheme != null) ...[
                        _ExclusiveSwatchPreview(
                          schemeKey: themePrefs.exclusiveScheme!,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (themePrefs.useDynamic)
            SettingsSection(
              title: 'Color Scheme',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Color scheme is managed by Dynamic Color.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openSchemePicker(
    BuildContext context,
    FlexScheme currentScheme,
    void Function(FlexScheme) onSchemeSelected,
    bool isDark,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Standard Color Schemes',
      child: _SchemePicker(
        currentScheme: currentScheme,
        isDark: isDark,
        onSelected: (scheme) {
          onSchemeSelected(scheme);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openExclusiveSchemePicker(
    BuildContext context,
    String? currentKey,
    void Function(String) onSelected,
    bool isDark,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Exclusive Color Schemes',
      child: _ExclusiveSchemePicker(
        currentKey: currentKey,
        isDark: isDark,
        onSelected: (key) {
          onSelected(key);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ExclusiveSwatchPreview extends StatelessWidget {
  const _ExclusiveSwatchPreview({
    required this.schemeKey,
    required this.isDark,
  });
  final String schemeKey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final data = exclusiveSchemes[schemeKey];
    if (data == null) return const SizedBox.shrink();
    final colors = isDark ? data.dark : data.light;
    return _SwatchStack(
      colors: [colors.primary, colors.secondary, colors.tertiary],
    );
  }
}

class _SwatchStack extends StatelessWidget {
  const _SwatchStack({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    const size = 18.0;
    const overlap = 10.0;
    final totalWidth = size + (colors.length - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(colors.length, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SchemePicker extends StatelessWidget {
  const _SchemePicker({
    required this.currentScheme,
    required this.isDark,
    required this.onSelected,
  });

  final FlexScheme currentScheme;
  final bool isDark;
  final void Function(FlexScheme) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final schemes = FlexColor.schemes.keys
        .where((s) => s != FlexScheme.custom)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        final data = FlexColor.schemes[scheme]!;
        final primary = isDark ? data.dark.primary : data.light.primary;
        final secondary = isDark ? data.dark.secondary : data.light.secondary;
        final isSelected = currentScheme == scheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: ListTile(
            shape: const StadiumBorder(),
            tileColor: isSelected ? cs.secondaryContainer : Colors.transparent,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, secondary],
                  ),
                ),
              ),
            ),
            title: Text(
              data.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: cs.onSecondaryContainer,
                  )
                : null,
            onTap: () => onSelected(scheme),
          ),
        );
      },
    );
  }
}

class _ExclusiveSchemePicker extends StatelessWidget {
  const _ExclusiveSchemePicker({
    required this.currentKey,
    required this.isDark,
    required this.onSelected,
  });

  final String? currentKey;
  final bool isDark;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = exclusiveSchemes.entries.toList();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final key = entries[index].key;
        final data = entries[index].value;
        final colors = isDark ? data.dark : data.light;
        final isSelected = currentKey == key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: ListTile(
            shape: const StadiumBorder(),
            tileColor: isSelected ? cs.secondaryContainer : Colors.transparent,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.secondary],
                  ),
                ),
              ),
            ),
            title: Text(
              data.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
              ),
            ),
            subtitle: Text(
              data.description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? cs.onSecondaryContainer.withValues(alpha: 0.7)
                    : cs.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: cs.onSecondaryContainer,
                  )
                : null,
            onTap: () => onSelected(key),
          ),
        );
      },
    );
  }
}
