import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/localization/cantonese_localizations_delegate.dart';
import 'package:shonenx/core/theme/app_theme.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/standard_schemes.dart';
import 'package:shonenx/features/settings/presentation/theme_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_mode_colors_tab.dart';
import 'package:shonenx/l10n/generated/app_localizations.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

const delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  CantoneseMaterialLocalizationsDelegate(),
  CantoneseCupertinoLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const splitFiles = <String>[
  'lib/features/settings/presentation/theme_settings_screen.dart',
  'lib/features/settings/presentation/widgets/theme_mode_colors_tab.dart',
  'lib/features/settings/presentation/widgets/theme_effects_tab.dart',
  'lib/features/settings/presentation/widgets/theme_wallpaper_tab.dart',
  'lib/features/settings/presentation/widgets/theme_color_pickers.dart',
  'lib/features/settings/presentation/widgets/wallpaper_customization_sheet.dart',
  'lib/features/settings/presentation/widgets/wallpaper_color_schemes_selector.dart',
];

int occurrences(String needle) => splitFiles.fold<int>(
  0,
  (sum, path) => sum + File(path).readAsStringSync().split(needle).length - 1,
);

class _FixedPrefs extends ThemePrefsNotifier {
  _FixedPrefs(this.value);
  final ThemePrefsState value;

  @override
  ThemePrefsState build() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('theme screen keeps the three-tab contract', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late AppLocalizations l10n;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            l10n = AppLocalizations.of(context)!;
            return const ThemeSettingsScreen();
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(const ThemePrefsState(), null),
        ),
      ),
    );

    final controller = tester.widget<DefaultTabController>(
      find.byType(DefaultTabController),
    );
    expect(controller.length, 3);

    expect(find.text(l10n.settingsThemes), findsOneWidget);
    expect(find.text(l10n.settingsEffects), findsOneWidget);
    expect(find.text(l10n.settingsWallpaper), findsOneWidget);

    final view = tester.widget<TabBarView>(find.byType(TabBarView));
    expect(view.children.length, 3);

    for (final label in [
      l10n.settingsThemes,
      l10n.settingsEffects,
      l10n.settingsWallpaper,
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  test('theme screen shell has no inline tile or picker code', () {
    final source = File(splitFiles.first).readAsStringSync();
    for (final pattern in [
      'SettingsSection(',
      'SettingsSliderTile(',
      'SettingsSwitchTile(',
      'SettingsActionTile(',
      'SettingsDropdownTile<',
      'ThemePaletteShelf(',
      'AppBottomSheet.show',
      'FilePicker.platform',
      'processBackgroundImage(',
      'WallpaperProcessor',
      '_SchemePicker',
      '_buildPresetGalleryBanner',
    ]) {
      expect(
        source.contains(pattern),
        isFalse,
        reason: 'found $pattern in shell',
      );
    }
  });

  test('write-path totals survive the split', () {
    expect(occurrences('updateTheme('), 18);
    expect(occurrences('copyWith('), 18);
    expect(occurrences('setExclusiveScheme('), 2);
    expect(occurrences('setStandardScheme('), 2);
    expect(occurrences('clearExclusiveScheme'), 1);
    expect(occurrences('clearWallpaperSettings'), 2);
  });

  Future<AppLocalizations> pumpColorsTab(
    WidgetTester tester,
    ThemePrefsState prefs,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [themePrefsProvider.overrideWith(() => _FixedPrefs(prefs))],
        child: MaterialApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(prefs, null),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return const ThemeModeColorsTab();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return l10n;
  }

  String readoutText(WidgetTester tester, int sectionIndex) {
    final sections = tester.widgetList<SettingsSection>(
      find.byType(SettingsSection),
    );
    final readout = sections.elementAt(sectionIndex).children.first as Padding;
    return (readout.child! as Text).data!;
  }

  testWidgets('mode and color source sections are ordered without new controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const defaultPrefs = ThemePrefsState();
    final l10n = await pumpColorsTab(tester, defaultPrefs);

    final sections = tester.widgetList<SettingsSection>(
      find.byType(SettingsSection),
    );
    expect(sections.map((s) => s.title).toList(), [
      l10n.settingsMode,
      l10n.settingsPresets,
      l10n.settingsColorSource,
      l10n.settingsColorTweaks,
    ]);

    final modeChildren = sections.elementAt(0).children;
    expect(modeChildren.length, 2);
    expect(modeChildren[0], isA<SettingsSegmentedTile<ThemeMode>>());
    expect(modeChildren[1], isA<SettingsSwitchTile>());
    expect((modeChildren[1] as SettingsSwitchTile).title, l10n.settingsAmoled);

    final sourceChildren = sections.elementAt(2).children;
    expect(sourceChildren.length, 3);
    final readout = sourceChildren.first as Padding;
    expect(readout.child, isA<Text>());
    expect(readout.child, isNot(isA<SettingsSwitchTile>()));
    expect(readout.child, isNot(isA<SettingsActionTile>()));
    expect(
      readoutText(tester, 2),
      '${l10n.settingsColorSource}: ${AppScheme.deepBlue.displayName}',
    );
    expect(sourceChildren[1], isA<SettingsSwitchTile>());
    expect(
      (sourceChildren[1] as SettingsSwitchTile).title,
      l10n.settingsDynamicColor,
    );
    expect(sourceChildren.last, isA<SettingsActionTile>());
    expect(
      (sourceChildren.last as SettingsActionTile).title,
      l10n.settingsThemeVariantTitle,
    );

    final tweaks = sections.elementAt(3).children;
    expect(tweaks.length, 1);
    expect(
      (tweaks.single as SettingsSwitchTile).title,
      l10n.settingsSwapColors,
    );

    expect(
      tester
          .widgetList<SettingsSwitchTile>(find.byType(SettingsSwitchTile))
          .length,
      3,
    );
    expect(
      tester
          .widgetList<SettingsActionTile>(find.byType(SettingsActionTile))
          .length,
      1,
    );
    expect(
      tester
          .widgetList<SettingsSegmentedTile<ThemeMode>>(
            find.byType(SettingsSegmentedTile<ThemeMode>),
          )
          .length,
      1,
    );

    await pumpColorsTab(tester, defaultPrefs.copyWith(useDynamic: true));
    expect(
      readoutText(tester, 2),
      '${l10n.settingsColorSource}: ${l10n.settingsDynamicColor}',
    );
    expect(
      tester.widgetList<SettingsSection>(find.byType(SettingsSection)).length,
      4,
    );
    expect(
      tester
          .widgetList<SettingsSwitchTile>(find.byType(SettingsSwitchTile))
          .length,
      3,
    );

    await pumpColorsTab(
      tester,
      defaultPrefs.copyWith(exclusiveScheme: 'netflix'),
    );
    expect(
      readoutText(tester, 2),
      '${l10n.settingsColorSource}: ${exclusiveSchemes['netflix']!.name}',
    );
    expect(
      tester.widgetList<SettingsSection>(find.byType(SettingsSection)).length,
      4,
    );
    expect(
      tester
          .widgetList<SettingsSwitchTile>(find.byType(SettingsSwitchTile))
          .length,
      3,
    );

    const seed = Color(0xFF3D5AFE);
    final seededPrimary = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).primary;
    final seedHex =
        '#${(seededPrimary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    await pumpColorsTab(
      tester,
      defaultPrefs.copyWith(colorSeed: seed.toARGB32()),
    );
    expect(readoutText(tester, 2), '${l10n.settingsColorSource}: $seedHex');
    expect(
      tester
          .widgetList<SettingsSwitchTile>(find.byType(SettingsSwitchTile))
          .length,
      3,
    );
  });
}
