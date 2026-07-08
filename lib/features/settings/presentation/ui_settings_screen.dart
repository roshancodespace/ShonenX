import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  static final _previewHistoryEntry = WatchHistoryEntry()
    ..animeId = '1'
    ..animeTitle = 'One Piece'
    ..episodeNumber = 7
    ..episodeTitle = 'Orewa Kaizoku Ou Ni Naru!'
    ..positionInMilliseconds = 720000
    ..durationInMilliseconds = 1200000
    ..thumbnailUrl =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

  static final _previewReadHistoryEntry = ReadHistoryEntry()
    ..mangaId = '2'
    ..mangaTitle = 'One Piece'
    ..chapterNumber = 236
    ..chapterTitle = 'Orewa Kaizoku Ou Ni Naru!'
    ..positionPage = 14
    ..totalPages = 20
    ..cover =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

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
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsActionTile(
                icon: Icons.tune_rounded,
                title: 'Global UI Customization',
                subtitle: 'Adjust corner radius, widget scale, and text scale',
                onTap: () => _showAppearanceSheet(
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
                onTap: () => _showCardStyleSheet(context, ref, notifier, theme),
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
                    _showContinueWatchingSheet(context, ref, notifier, theme),
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
                    _showContinueReadingSheet(context, ref, notifier, theme),
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
                  label: _episodeModeLabel(prefs.episodeViewMode),
                  cs: cs,
                ),
                onTap: () =>
                    _showEpisodeModeSheet(context, ref, notifier, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppearanceSheet(
    BuildContext context,
    WidgetRef ref,
    ThemePrefsNotifier themeNotifier,
    ThemePrefsState initialThemePrefs,
    ThemeData theme,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Global UI Customization',
      child: Consumer(
        builder: (_, r, __) {
          final currentPrefs = r.watch(themePrefsProvider);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlobalUiPreview(
                  theme,
                  currentPrefs.uiRoundness,
                  currentPrefs.fontScaleFactor,
                  currentPrefs.uiScaleFactor,
                ),
                SettingsSliderTile(
                  title: 'Border Roundness',
                  subtitle: 'Corner roundness across the app',
                  value: currentPrefs.uiRoundness,
                  min: 0.0,
                  max: 32.0,
                  divisions: 32,
                  label: currentPrefs.uiRoundness.toStringAsFixed(1),
                  icon: Icons.rounded_corner_outlined,
                  onChanged: (v) => themeNotifier.updateTheme(
                    (s) => s.copyWith(uiRoundness: v),
                  ),
                ),
                SettingsSliderTile(
                  title: 'Font Scale',
                  subtitle: 'Scale text size globally',
                  value: currentPrefs.fontScaleFactor,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(currentPrefs.fontScaleFactor * 100).toInt()}%',
                  icon: Icons.format_size_outlined,
                  onChanged: (v) => themeNotifier.updateTheme(
                    (s) => s.copyWith(fontScaleFactor: v),
                  ),
                ),
                SettingsSliderTile(
                  title: 'Widget Scale',
                  subtitle: 'Scale media cards & navigation bar',
                  value: currentPrefs.uiScaleFactor,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(currentPrefs.uiScaleFactor * 100).toInt()}%',
                  icon: Icons.aspect_ratio_outlined,
                  onChanged: (v) => themeNotifier.updateTheme(
                    (s) => s.copyWith(uiScaleFactor: v),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalUiPreview(
    ThemeData theme,
    double roundness,
    double fontScale,
    double uiScale,
  ) {
    final cs = theme.colorScheme;
    return Container(
      height: 120,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedScale(
        scale: uiScale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Builder(
          builder: (context) {
            final currentTextScale = MediaQuery.of(
              context,
            ).textScaler.scale(1.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(currentTextScale / uiScale),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: 220,
                height: 84,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(roundness),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(roundness * 0.6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ShonenX UI',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Radius ${roundness.round()}px • ${(uiScale * 100).round()}%',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCardStyleSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Card Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(uiPrefsProvider.select((s) => s.cardStyle));

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: current.layout.width,
                    height: current.layout.height,
                    child: MediaCard(
                      title: 'Demon Slayer: Kimetsu No Yaiba',
                      tag: 'ui-card-preview',
                      format: 'TV',
                      imageUrl:
                          'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
                      onTap: () {},
                      style: current,
                    ),
                  ),
                ),

                if (current == MediaCardStyle.experimentalLiquid) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExperimentalEditorSheet(
                        context,
                        ref,
                        notifier,
                        theme,
                      );
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Customize & Optimize for Device'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                ...MediaCardStyle.values.map(
                  (style) => _SelectionTile(
                    selected: current == style,
                    icon: Icons.style_outlined,
                    title: style.displayName,
                    subtitle: _cardStyleDesc(style),
                    selectedColor: cs.primary,
                    onTap: () => notifier.updateCardStyle(style),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExperimentalEditorSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Liquid Glass Live Editor',
      child: Consumer(
        builder: (_, r, _) {
          final config = r.watch(
            uiPrefsProvider.select((s) => s.experimentalConfig),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Preview (Pinned)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => notifier.resetExperimentalConfig(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Reset to Defaults',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Center(
                child: SizedBox(
                  width: MediaCardStyle.experimentalLiquid.layout.width,
                  height: MediaCardStyle.experimentalLiquid.layout.height,
                  child: MediaCard(
                    title: 'Demon Slayer: Kimetsu No Yaiba',
                    tag: 'ui-editor-preview',
                    format: 'TV',
                    imageUrl:
                        'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
                    onTap: () {},
                    style: MediaCardStyle.experimentalLiquid,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section 1: Glass Optics & Refraction
                      _buildEditorSectionHeader(
                        'Glass Optics & Refraction',
                        Icons.water_drop_rounded,
                        theme.colorScheme.primary,
                      ),
                      SettingsSliderTile(
                        icon: Icons.water_drop_outlined,
                        title: 'Refraction Distortion',
                        subtitle: 'Intensity of glass light bending effect',
                        value:
                            (config['distortion'] as num?)?.toDouble() ?? 0.15,
                        min: 0.0,
                        max: 0.40,
                        divisions: 20,
                        label:
                            ((config['distortion'] as num?)?.toDouble() ?? 0.15)
                                .toStringAsFixed(2),
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'distortion': val,
                        }),
                      ),
                      SettingsSliderTile(
                        icon: Icons.zoom_in_rounded,
                        title: 'Lens Magnification',
                        subtitle: 'Zoom effect through the glass lens',
                        value:
                            (config['magnification'] as num?)?.toDouble() ??
                            1.06,
                        min: 1.0,
                        max: 1.25,
                        divisions: 25,
                        label:
                            '${(((config['magnification'] as num?)?.toDouble() ?? 1.06) - 1.0) * 100 ~/ 1}%',
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'magnification': val,
                        }),
                      ),
                      SettingsSliderTile(
                        icon: Icons.lens_blur_rounded,
                        title: 'Chromatic Aberration',
                        subtitle:
                            'RGB color splitting on lens refraction edges',
                        value:
                            (config['chromaticAberration'] as num?)
                                ?.toDouble() ??
                            0.006,
                        min: 0.0,
                        max: 0.02,
                        divisions: 20,
                        label:
                            ((config['chromaticAberration'] as num?)
                                        ?.toDouble() ??
                                    0.006)
                                .toStringAsFixed(3),
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'chromaticAberration': val,
                        }),
                      ),
                      SettingsSliderTile(
                        icon: Icons.invert_colors_rounded,
                        title: 'Card Tint Opacity',
                        subtitle: 'Frosted white glass body transparency',
                        value:
                            (config['cardTintOpacity'] as num?)?.toDouble() ??
                            0.10,
                        min: 0.0,
                        max: 0.35,
                        divisions: 35,
                        label:
                            '${(((config['cardTintOpacity'] as num?)?.toDouble() ?? 0.10) * 100).round()}%',
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'cardTintOpacity': val,
                        }),
                      ),
                      SettingsSliderTile(
                        icon: Icons.blur_linear_rounded,
                        title: 'Lens Appearance Tint',
                        subtitle: 'Floating lenses background opacity',
                        value:
                            (config['lensAppearanceTint'] as num?)
                                ?.toDouble() ??
                            0.13,
                        min: 0.0,
                        max: 0.35,
                        divisions: 35,
                        label:
                            '${(((config['lensAppearanceTint'] as num?)?.toDouble() ?? 0.13) * 100).round()}%',
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'lensAppearanceTint': val,
                        }),
                      ),

                      const Divider(height: 1),

                      // Section 2: Border & Luminous Effects
                      _buildEditorSectionHeader(
                        'Border & Luminous Effects',
                        Icons.auto_awesome_rounded,
                        theme.colorScheme.primary,
                      ),
                      SettingsSwitchTile(
                        icon: Icons.flare_rounded,
                        title: 'Enable Luminous Border',
                        subtitle: 'Clean glowing border overlay on card edges',
                        value: config['enableLuminousBorder'] != false,
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'enableLuminousBorder': val,
                        }),
                      ),
                      if (config['enableLuminousBorder'] != false) ...[
                        SettingsSliderTile(
                          icon: Icons.line_weight_rounded,
                          title: 'Luminous Border Width',
                          subtitle: 'Thickness of the active glass edge border',
                          value:
                              (config['borderWidth'] as num?)?.toDouble() ??
                              2.0,
                          min: 1.0,
                          max: 4.0,
                          divisions: 15,
                          label:
                              '${((config['borderWidth'] as num?)?.toDouble() ?? 2.0).toStringAsFixed(1)}px',
                          onChanged: (val) => notifier.updateExperimentalConfig(
                            {'borderWidth': val},
                          ),
                        ),
                        SettingsSliderTile(
                          icon: Icons.brightness_high_rounded,
                          title: 'Border Glow Intensity',
                          subtitle: 'Brightness and opacity of the border glow',
                          value:
                              (config['borderGlowIntensity'] as num?)
                                  ?.toDouble() ??
                              0.65,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          label:
                              '${(((config['borderGlowIntensity'] as num?)?.toDouble() ?? 0.65) * 100).round()}%',
                          onChanged: (val) => notifier.updateExperimentalConfig(
                            {'borderGlowIntensity': val},
                          ),
                        ),
                      ],
                      SettingsSliderTile(
                        icon: Icons.highlight_outlined,
                        title: 'Optical Border Saturation',
                        subtitle: 'Vibrancy saturation along the glass outline',
                        value:
                            (config['borderSaturation'] as num?)?.toDouble() ??
                            1.6,
                        min: 0.0,
                        max: 3.0,
                        divisions: 30,
                        label:
                            '${(((config['borderSaturation'] as num?)?.toDouble() ?? 1.6) * 100).round()}%',
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'borderSaturation': val,
                        }),
                      ),

                      const Divider(height: 1),

                      // Section 3: Interactive Physics & Lenses
                      _buildEditorSectionHeader(
                        'Interactive Physics & Lenses',
                        Icons.track_changes_rounded,
                        theme.colorScheme.primary,
                      ),
                      SettingsSwitchTile(
                        icon: Icons.bubble_chart_rounded,
                        title: 'Enable Metaball Orb',
                        subtitle:
                            'Floating liquid lens orb appears on hover or touch',
                        value: config['enableMetaball'] != false,
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'enableMetaball': val,
                        }),
                      ),
                      if (config['enableMetaball'] != false) ...[
                        SettingsSwitchTile(
                          icon: Icons.touch_app_rounded,
                          title: 'Interactive Tracking Orb',
                          subtitle:
                              'Floating metaball tracks pointer and touch position',
                          value: config['interactiveOrb'] != false,
                          onChanged: (val) => notifier.updateExperimentalConfig(
                            {'interactiveOrb': val},
                          ),
                        ),
                        SettingsSliderTile(
                          icon: Icons.blur_on_rounded,
                          title: 'Metaball Smoothness (Performance)',
                          subtitle:
                              'Lower for better GPU performance on older devices',
                          value:
                              (config['smoothness'] as num?)?.toDouble() ??
                              46.0,
                          min: 15.0,
                          max: 75.0,
                          divisions: 12,
                          label:
                              ((config['smoothness'] as num?)?.toDouble() ??
                                      46.0)
                                  .round()
                                  .toString(),
                          onChanged: (val) => notifier.updateExperimentalConfig(
                            {'smoothness': val},
                          ),
                        ),
                      ],
                      SettingsSwitchTile(
                        icon: Icons.crop_rotate,
                        title: '3D Hover Tilt Perspective',
                        subtitle:
                            'Card tilts in 3D space on mouse hover or touch',
                        value: config['enable3dTilt'] != false,
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'enable3dTilt': val,
                        }),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.center_focus_weak_rounded,
                        title: 'Glass Lenses on Badges',
                        subtitle:
                            'Wrap top badge indicators in liquid glass lenses',
                        value: config['enableBadgeLens'] != false,
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'enableBadgeLens': val,
                        }),
                      ),

                      const Divider(height: 1),

                      // Section 4: Background & Shadows
                      _buildEditorSectionHeader(
                        'Background & Shadows',
                        Icons.layers_outlined,
                        theme.colorScheme.primary,
                      ),
                      SettingsSwitchTile(
                        icon: Icons.add_box,
                        title: 'Enable Card Elevation Shadow',
                        subtitle:
                            'Add drop shadow (disabled by default so only border suffices)',
                        value: config['enableCardShadow'] == true,
                        onChanged: (val) => notifier.updateExperimentalConfig({
                          'enableCardShadow': val,
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditorSectionHeader(
    String title,
    IconData icon,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showContinueWatchingSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Continue Watching Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.continueWatchingStyle),
          );

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ContinueWatchingItem(
                    style: current,
                    progress: 0.72,
                    entry: _previewHistoryEntry,
                  ),
                ),

                const SizedBox(height: 10),

                ...ContinueWatchingStyle.values.map(
                  (style) => _SelectionTile(
                    selected: current == style,
                    icon: _cwStyleIcon(style),
                    title: style.displayName,
                    subtitle: _cwStyleDesc(style),
                    selectedColor: cs.primary,
                    onTap: () => notifier.updateContinueWatchingStyle(style),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showContinueReadingSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Continue Reading Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.continueReadingStyle),
          );

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ContinueReadingItem(
                    style: current,
                    progress: 0.7,
                    entry: _previewReadHistoryEntry,
                  ),
                ),

                const SizedBox(height: 10),

                ...ContinueReadingStyle.values.map(
                  (style) => _SelectionTile(
                    selected: current == style,
                    icon: _crStyleIcon(style),
                    title: style.displayName,
                    subtitle: _crStyleDesc(style),
                    selectedColor: cs.primary,
                    onTap: () => notifier.updateContinueReadingStyle(style),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEpisodeModeSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Episode View Mode',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _EpisodeViewModePreview(mode: current),
                ),

                const SizedBox(height: 10),

                ...EpisodeViewMode.values.map(
                  (mode) => _SelectionTile(
                    selected: current == mode,
                    icon: _episodeModeIcon(mode),
                    title: _episodeModeLabel(mode),
                    subtitle: _episodeModeDesc(mode),
                    selectedColor: cs.primary,
                    onTap: () => notifier.updateEpisodeViewMode(mode),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _cardStyleDesc(MediaCardStyle s) => switch (s) {
    MediaCardStyle.classic => 'Standard poster with title below',
    MediaCardStyle.minimal => 'Compact with subtle overlay',
    MediaCardStyle.expressive => 'Tall card with bold typography',
    MediaCardStyle.material => 'Material You elevated card',
    MediaCardStyle.liquidGlass => 'Frosted glass finish',
    MediaCardStyle.experimentalLiquid =>
      'iOS 26 Liquid Glass with real-time metaball refraction & lens physics',
  };

  static String _cwStyleDesc(ContinueWatchingStyle s) => switch (s) {
    ContinueWatchingStyle.classic => 'Square cards with progress bar',
    ContinueWatchingStyle.wideBanner => 'Wide horizontal banner cards',
  };

  static IconData _cwStyleIcon(ContinueWatchingStyle s) => switch (s) {
    ContinueWatchingStyle.classic => Icons.view_module_outlined,
    ContinueWatchingStyle.wideBanner => Icons.view_day_outlined,
  };

  static String _crStyleDesc(ContinueReadingStyle s) => switch (s) {
    ContinueReadingStyle.classic => 'Vertical manga cover cards',
    ContinueReadingStyle.wideBanner => 'Wide horizontal banner cards',
  };

  static IconData _crStyleIcon(ContinueReadingStyle s) => switch (s) {
    ContinueReadingStyle.classic => Icons.view_module_outlined,
    ContinueReadingStyle.wideBanner => Icons.view_day_outlined,
  };

  static String _episodeModeLabel(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => 'Classic',
    EpisodeViewMode.grid => 'Grid',
    EpisodeViewMode.box => 'Box',
    EpisodeViewMode.compact => 'Compact',
    EpisodeViewMode.cover => 'Cover',
  };

  static String _episodeModeDesc(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => 'Detailed list with episode art and title',
    EpisodeViewMode.grid => 'Thumbnail grid with episode numbers',
    EpisodeViewMode.box => 'Compact numbered boxes — great for long anime',
    EpisodeViewMode.compact =>
      'Clean text rows without thumbnails for fast browsing',
    EpisodeViewMode.cover => 'Cinematic wide cards with prominent action bar',
  };

  static IconData _episodeModeIcon(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => Icons.view_agenda_outlined,
    EpisodeViewMode.grid => Icons.grid_view_outlined,
    EpisodeViewMode.box => Icons.tag_outlined,
    EpisodeViewMode.compact => Icons.format_list_bulleted_rounded,
    EpisodeViewMode.cover => Icons.movie_creation_outlined,
  };
}

class _SelectionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color selectedColor;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? selectedColor : cs.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: selectedColor)
          : null,
      onTap: onTap,
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

class _EpisodeViewModePreview extends StatelessWidget {
  final EpisodeViewMode mode;

  const _EpisodeViewModePreview({required this.mode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roundness = GlobalUI.uiRoundness.clamp(8.0, 20.0);

    return AnimatedSize(
      duration: Durations.short4,
      curve: Curves.easeOutCubic,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: switch (mode) {
          EpisodeViewMode.classic => Column(
            key: const ValueKey('classic_flat'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlatClassicRow(
                cs,
                roundness,
                num: '1',
                title: 'Pilot',
                time: '24m',
                isActive: true,
              ),
              const SizedBox(height: 6),
              _buildFlatClassicRow(
                cs,
                roundness,
                num: '2',
                title: 'The Journey Begins',
                time: '24m',
                isActive: false,
              ),
            ],
          ),

          EpisodeViewMode.grid => Row(
            key: const ValueKey('grid_flat'),
            children: [
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '1',
                  title: 'Pilot',
                  isActive: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '2',
                  title: 'Journey',
                  isActive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '3',
                  title: 'Encounter',
                  isActive: false,
                ),
              ),
            ],
          ),

          EpisodeViewMode.box => Wrap(
            key: const ValueKey('box_flat'),
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (i) {
              final active = i == 2;
              final watched = i < 2;
              return Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? cs.primary
                      : watched
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(roundness * 0.6),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: active
                        ? cs.onPrimary
                        : watched
                        ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                        : cs.onSurface,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }),
          ),

          EpisodeViewMode.compact => Column(
            key: const ValueKey('compact_flat'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '1',
                title: 'Pilot',
                isActive: true,
              ),
              const SizedBox(height: 6),
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '2',
                title: 'The Journey Begins',
                isActive: false,
              ),
              const SizedBox(height: 6),
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '3',
                title: 'First Encounter',
                isActive: false,
              ),
            ],
          ),

          EpisodeViewMode.cover => _buildFlatCoverCard(cs, roundness),
        },
      ),
    );
  }

  Widget _buildFlatClassicRow(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required String time,
    required bool isActive,
  }) {
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.25)
            : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(roundness),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 10,
                color: isActive ? cs.primary.withValues(alpha: 0.3) : dimColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Icon(
                  isActive
                      ? Icons.play_circle_fill_rounded
                      : Icons.check_circle,
                  size: 26,
                  color: isActive ? cs.primary : dimColor,
                ),
              ),
              Container(
                width: 2,
                height: 10,
                color: isActive ? cs.primary.withValues(alpha: 0.3) : dimColor,
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ep $num',
                  style: TextStyle(
                    color: isActive ? cs.primary : dimColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatGridItem(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required bool isActive,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(roundness * 0.8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.6, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    num,
                    style: TextStyle(
                      color: isActive ? cs.primary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOW',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatCompactRow(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required bool isActive,
  }) {
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(roundness * 0.7),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? cs.primary : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: TextStyle(
                color: isActive ? cs.onPrimary : cs.onSurface,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? cs.primary : cs.onSurface,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Icon(Icons.play_circle_fill_rounded, size: 18, color: cs.primary)
          else
            Icon(Icons.check_circle_rounded, size: 16, color: dimColor),
        ],
      ),
    );
  }

  Widget _buildFlatCoverCard(ColorScheme cs, double roundness) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        key: const ValueKey('cover_flat'),
        width: double.maxFinite,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(roundness),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.65, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: cs.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Episode 1',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'The Beginning of a Legend',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
