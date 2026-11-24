import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/appearance_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/card_style_picker.dart';
import 'package:shonenx/features/settings/presentation/widgets/episode_mode_picker.dart';
import 'package:shonenx/features/settings/presentation/widgets/home_header_style_picker.dart';
import 'package:shonenx/features/settings/presentation/widgets/nav_bar_style_picker.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/sheet_physics_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final prefs = ref.watch(uiPrefsProvider);
    final notifier = ref.read(uiPrefsProvider.notifier);

    final themePrefs = ref.watch(themePrefsProvider);
    final themeNotifier = ref.read(themePrefsProvider.notifier);

    final sheetPhysicsLabel = prefs.sheetPhysics
        ? l10n.uiSettingsSheetPhysicsHammer
        : l10n.uiSettingsSheetPhysicsSlideUp;

    return AppScaffold(
      title: context.l10n.settingsUi,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: l10n.uiSettingsExperimental,
            children: [
              SettingsSwitchTile(
                icon: Icons.tv_rounded,
                title: l10n.uiSettingsExperimentalTvTitle,
                subtitle: l10n.uiSettingsExperimentalTvSubtitle,
                value: prefs.useNewUi,
                onChanged: (val) => notifier.setUseNewUi(val),
              ),
            ],
          ),

          SettingsSection(
            title: l10n.uiSettingsLayoutMotion,
            subtitle: l10n.uiSettingsLayoutMotionSubtitle,
            children: [
              SettingsActionTile(
                icon: Icons.tune_rounded,
                title: l10n.uiSettingsSizingTitle,
                subtitle: l10n.uiSettingsSizingSubtitle,
                onTap: () => showAppearanceSheet(
                  context,
                  ref,
                  themeNotifier,
                  themePrefs,
                  theme,
                ),
              ),
              SettingsActionTile(
                icon: Icons.animation_rounded,
                title: l10n.uiSettingsSheetPhysicsTitle,
                subtitle: l10n.uiSettingsSheetPhysicsSubtitle,
                trailing: SettingsValueChip(label: sheetPhysicsLabel),
                onTap: () => showSheetPhysicsSheet(context, ref),
              ),
            ],
          ),

          SettingsSection(
            title: l10n.uiSettingsHomeScreen,
            children: [
              SettingsActionTile(
                icon: Icons.view_headline_rounded,
                title: l10n.uiSettingsHeaderStyleTitle,
                subtitle: l10n.uiSettingsHeaderStyleSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.homeHeaderStyle.displayName,
                ),
                onTap: () =>
                    showHomeHeaderStyleSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          SettingsSection(
            title: l10n.uiSettingsMediaCards,
            children: [
              SettingsActionTile(
                icon: Icons.style_outlined,
                title: l10n.uiSettingsCardStyleTitle,
                subtitle: l10n.uiSettingsCardStyleSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.cardStyle.displayName,
                ),
                onTap: () => showCardStyleSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.play_circle_outline_rounded,
                title: l10n.uiSettingsContinueWatchingTitle,
                subtitle: l10n.uiSettingsContinueWatchingSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.continueWatchingStyle.displayName,
                ),
                onTap: () =>
                    showContinueWatchingSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.menu_book_rounded,
                title: l10n.uiSettingsContinueReadingTitle,
                subtitle: l10n.uiSettingsContinueReadingSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.continueReadingStyle.displayName,
                ),
                onTap: () =>
                    showContinueReadingSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          SettingsSection(
            title: l10n.uiSettingsEpisodes,
            children: [
              SettingsActionTile(
                icon: Icons.view_list_rounded,
                title: l10n.uiSettingsEpisodeViewTitle,
                subtitle: l10n.uiSettingsEpisodeViewSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.episodeViewMode.displayName,
                ),
                onTap: () =>
                    showEpisodeModeSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          SettingsSection(
            title: l10n.uiSettingsNavigationBar,
            children: [
              SettingsActionTile(
                icon: Icons.navigation_rounded,
                title: l10n.uiSettingsNavBarTitle,
                subtitle: l10n.uiSettingsNavBarSubtitle,
                trailing: SettingsValueChip(
                  label: prefs.navBarStyle.displayName,
                ),
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
