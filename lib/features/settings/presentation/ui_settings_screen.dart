import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/ui_settings_sheets.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final prefs = ref.watch(uiPrefsProvider);
    final notifier = ref.read(uiPrefsProvider.notifier);

    final themePrefs = ref.watch(themePrefsProvider);
    final themeNotifier = ref.read(themePrefsProvider.notifier);

    return AppScaffold(
      title: 'UI',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsActionTile(
                icon: Icons.tune_rounded,
                title: 'Global UI Customization',
                subtitle: 'Adjust corner radius, widget scale, and text scale',
                onTap: () => showAppearanceSheet(
                  context,
                  ref,
                  themeNotifier,
                  themePrefs,
                  theme,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: 'Media Cards',
            children: [
              SettingsActionTile(
                icon: Icons.style_outlined,
                title: 'Card Style',
                subtitle: 'Style of media cards on Home & Discover',
                trailing: _Chip(label: prefs.cardStyle.displayName, cs: cs),
                onTap: () => showCardStyleSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.play_circle_outline_rounded,
                title: 'Continue Watching Style',
                subtitle: 'Style of cards on the Continue Watching row',
                trailing: _Chip(
                  label: prefs.continueWatchingStyle.displayName,
                  cs: cs,
                ),
                onTap: () =>
                    showContinueWatchingSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.menu_book_rounded,
                title: 'Continue Reading Style',
                subtitle: 'Style of cards on the Continue Reading row',
                trailing: _Chip(
                  label: prefs.continueReadingStyle.displayName,
                  cs: cs,
                ),
                onTap: () =>
                    showContinueReadingSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          SettingsSection(
            title: 'Episodes',
            children: [
              SettingsActionTile(
                icon: Icons.view_list_rounded,
                title: 'Episode/Chapter View mode',
                subtitle: 'Default view mode for episode lists',
                trailing: _Chip(
                  label: prefs.episodeViewMode.displayName,
                  cs: cs,
                ),
                onTap: () =>
                    showEpisodeModeSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          SettingsSection(
            title: 'Navigation',
            children: [
              SettingsActionTile(
                icon: Icons.navigation_rounded,
                title: 'Navigation Bar Style',
                subtitle: 'Style of the bottom navigation bar',
                trailing: _Chip(label: prefs.navBarStyle.displayName, cs: cs),
                onTap: () =>
                    showNavBarStyleSheet(context, ref, notifier, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _Chip({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}
