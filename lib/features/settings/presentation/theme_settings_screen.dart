import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_effects_tab.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_mode_colors_tab.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_wallpaper_tab.dart';
import 'package:shonenx/shared/providers/preset_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: context.l10n.settingsAppearance,
        barBottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorAnimation: TabIndicatorAnimation.linear,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: context.l10n.settingsThemes),
              Tab(text: context.l10n.settingsEffects),
              Tab(text: context.l10n.settingsWallpaper),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: context.l10n.settingsResetDefaults,
            onPressed: () {
              ref
                  .read(themePrefsProvider.notifier)
                  .updateTheme((_) => const ThemePrefsState());
              ref.read(presetProvider.notifier).clearActivePresetMark();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.settingsThemeResetSuccess),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        body: TabBarView(
          children: [
            const ThemeModeColorsTab(),
            const ThemeEffectsTab(),
            const ThemeWallpaperTab(),
          ],
        ),
      ),
    );
  }
}
