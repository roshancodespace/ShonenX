import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/core/theme/app_theme.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/theme_color_resolver.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_variant_swatch_preview.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

ResolvedThemeColors resolveFor(
  ThemePrefsState prefs, {
  Brightness brightness = Brightness.dark,
  ColorScheme? dynamic,
}) =>
    resolveThemeColors(
      prefs,
      brightness: brightness,
      dynamicColorScheme: dynamic,
    );

void expectKeys(
  ResolvedThemeColors result,
  Color primary,
  Color secondary,
  Color tertiary,
) {
  expect(result.primaryKey, primary);
  expect(result.secondaryKey, secondary);
  expect(result.tertiaryKey, tertiary);
}

class _FixedPrefs extends ThemePrefsNotifier {
  _FixedPrefs(this.value);
  final ThemePrefsState value;

  @override
  ThemePrefsState build() => value;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('resolveThemeColors source branches', () {
    for (final brightness in Brightness.values) {
      final tag = brightness == Brightness.dark ? 'dark' : 'light';
      final flex = FlexColor.schemes[FlexScheme.deepBlue]!;
      final flexColors = brightness == Brightness.dark ? flex.dark : flex.light;
      final netflix = exclusiveSchemes['netflix']!;
      final netflixColors =
          brightness == Brightness.dark ? netflix.dark : netflix.light;

      test('dynamic argument wins at $tag brightness', () {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF112233),
          brightness: brightness,
        );
        final result = resolveFor(
          const ThemePrefsState(),
          brightness: brightness,
          dynamic: scheme,
        );
        expect(result.source, ThemeColorSource.dynamic);
        expect(result.colorScheme, scheme);
        expect(result.customColors, isNull);
        expect(result.exclusive, isNull);
        expectKeys(result, scheme.primary, scheme.secondary, scheme.tertiary);
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('wallpaper image seed at $tag brightness', () {
        const state = ThemePrefsState(
          useImageColors: true,
          wallpaperSettings: WallpaperSettings(
            imagePath: 'wall.jpg',
            imageColorSeed: 0xFF445566,
          ),
        );
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF445566),
          brightness: brightness,
        );
        final result = resolveFor(state, brightness: brightness);
        expect(result.source, ThemeColorSource.wallpaperImageSeed);
        expect(result.colorScheme, scheme);
        expect(result.customColors, isNull);
        expect(result.exclusive, isNull);
        expectKeys(result, scheme.primary, scheme.secondary, scheme.tertiary);
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('custom seed at $tag brightness', () {
        const state = ThemePrefsState(colorSeed: 0xFF778899);
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF778899),
          brightness: brightness,
        );
        final result = resolveFor(state, brightness: brightness);
        expect(result.source, ThemeColorSource.customSeed);
        expect(result.colorScheme, scheme);
        expect(result.customColors, isNull);
        expectKeys(result, scheme.primary, scheme.secondary, scheme.tertiary);
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('custom primary with generated fallbacks at $tag brightness', () {
        const state = ThemePrefsState(primaryColor: 0xFFAABBCC);
        final result = resolveFor(state, brightness: brightness);
        final fallback = FlexSchemeColor.from(
          primary: const Color(0xFFAABBCC),
          brightness: brightness,
        );
        expect(result.source, ThemeColorSource.customPrimary);
        expect(result.colorScheme, isNull);
        expect(result.customColors, isNotNull);
        expectKeys(
          result,
          const Color(0xFFAABBCC),
          fallback.secondary,
          fallback.tertiary,
        );
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('custom primary with explicit secondary and tertiary at $tag brightness', () {
        const state = ThemePrefsState(
          primaryColor: 0xFFAABBCC,
          secondaryColor: 0xFFDDEEFF,
          tertiaryColor: 0xFF102030,
        );
        final result = resolveFor(state, brightness: brightness);
        expect(result.source, ThemeColorSource.customPrimary);
        expectKeys(
          result,
          const Color(0xFFAABBCC),
          const Color(0xFFDDEEFF),
          const Color(0xFF102030),
        );
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('exclusive scheme at $tag brightness', () {
        const state = ThemePrefsState(exclusiveScheme: 'netflix');
        final result = resolveFor(state, brightness: brightness);
        expect(result.source, ThemeColorSource.exclusive);
        expect(result.colorScheme, isNull);
        expect(result.customColors, netflixColors);
        expect(result.exclusive, netflix);
        expectKeys(
          result,
          netflixColors.primary,
          netflixColors.secondary,
          netflixColors.tertiary,
        );
        expect(result.usesConfiguredFlexScheme, isFalse);
      });

      test('flex fallback at $tag brightness', () {
        const state = ThemePrefsState();
        final result = resolveFor(state, brightness: brightness);
        expect(result.source, ThemeColorSource.flexScheme);
        expect(result.colorScheme, isNull);
        expect(result.customColors, isNull);
        expect(result.exclusive, isNull);
        expectKeys(
          result,
          flexColors.primary,
          flexColors.secondary,
          flexColors.tertiary,
        );
        expect(result.usesConfiguredFlexScheme, isTrue);
      });
    }

    test('precedence follows the order used by AppTheme', () {
      const all = ThemePrefsState(
        useImageColors: true,
        wallpaperSettings: WallpaperSettings(
          imagePath: 'wall.jpg',
          imageColorSeed: 0xFF111111,
        ),
        colorSeed: 0xFF222222,
        primaryColor: 0xFF333333,
        exclusiveScheme: 'netflix',
      );
      final dynamic = ColorScheme.fromSeed(
        seedColor: const Color(0xFF444444),
        brightness: Brightness.dark,
      );
      expect(resolveFor(all, dynamic: dynamic).source, ThemeColorSource.dynamic);
      expect(resolveFor(all).source, ThemeColorSource.wallpaperImageSeed);
      expect(
        resolveFor(all.copyWith(useImageColors: false)).source,
        ThemeColorSource.customSeed,
      );
      expect(
        resolveFor(
          const ThemePrefsState(
            primaryColor: 0xFF333333,
            exclusiveScheme: 'netflix',
          ),
        ).source,
        ThemeColorSource.customPrimary,
      );
      expect(
        resolveFor(const ThemePrefsState(exclusiveScheme: 'netflix')).source,
        ThemeColorSource.exclusive,
      );
      expect(resolveFor(const ThemePrefsState()).source, ThemeColorSource.flexScheme);
    });

    test('useDynamic without a supplied scheme falls through', () {
      const state = ThemePrefsState(useDynamic: true, colorSeed: 0xFF778899);
      final result = resolveFor(state);
      expect(result.source, ThemeColorSource.customSeed);
      expect(result.colorScheme, isNotNull);
      final light = resolveFor(state, brightness: Brightness.light);
      expect(light.source, ThemeColorSource.customSeed);
      expect(light.colorScheme, isNotNull);
    });

    test('non-color preferences never change resolver keys', () {
      const base = ThemePrefsState(colorSeed: 0xFF123456);
      final changed = base.copyWith(
        blendLevel: 40,
        swapColors: true,
        useAmoled: true,
        uiRoundness: 24.0,
      );
      final before = resolveFor(base);
      final after = resolveFor(changed);
      expect(after.source, before.source);
      expectKeys(after, before.primaryKey, before.secondaryKey, before.tertiaryKey);
      expect(
        AppTheme.dark(changed, null).scaffoldBackgroundColor,
        const Color(0xFF000000),
      );
      expect(
        AppTheme.dark(base, null).scaffoldBackgroundColor,
        isNot(const Color(0xFF000000)),
      );
    });

    test('stored app_theme_data round-trips without changing resolution', () {
      const state = ThemePrefsState(
        useAmoled: true,
        blendLevel: 25,
        useGradients: true,
        gradientStyle: BackgroundGradientStyle.radial,
        gradientDirection: BackgroundGradientDirection.vertical,
        gradientColorPair: BackgroundGradientColorPair.vibrantMix,
        gradientIntensity: 0.8,
        useNoiseOverlay: true,
        noiseOpacity: 0.2,
        uiRoundness: 18.0,
        fontScaleFactor: 1.2,
        uiScaleFactor: 1.1,
        wallpaperSettings: WallpaperSettings(
          imagePath: 'wall.jpg',
          blur: 4.0,
          opacity: 0.7,
          saturation: 1.4,
          brightness: 0.9,
          imageColorSeed: 0xFF556677,
        ),
        useImageColors: true,
        colorSeed: 0xFF123456,
      );
      final restored = ThemePrefsState.fromJson(state.toJson());
      for (final brightness in Brightness.values) {
        final before = resolveFor(state, brightness: brightness);
        final after = resolveFor(restored, brightness: brightness);
        expect(after.source, before.source);
        expectKeys(
          after,
          before.primaryKey,
          before.secondaryKey,
          before.tertiaryKey,
        );
      }
    });

    testWidgets('classic swatch gradient matches resolver and applied theme', (
      tester,
    ) async {
      const state = ThemePrefsState(colorSeed: 0xFF3F51B5);
      final resolved = resolveFor(state, brightness: Brightness.dark);
      final theme = AppTheme.dark(state, null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themePrefsProvider.overrideWith(() => _FixedPrefs(state)),
          ],
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: ThemeVariantSwatchPreview(
                variant: AppThemeVariant.classic,
                isDark: true,
              ),
            ),
          ),
        ),
      );

      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);
      final containers = find.descendant(
        of: avatar,
        matching: find.byType(Container),
      );
      final container = containers.evaluate().firstWhere((element) {
        final decoration = (element.widget as Container).decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
      }).widget as Container;
      final decoration = container.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(
        gradient.colors,
        [resolved.primaryKey, resolved.secondaryKey, resolved.tertiaryKey],
      );
      expect(theme.colorScheme.primary, resolved.primaryKey);
      expect(theme.colorScheme.secondary, resolved.secondaryKey);
      expect(theme.colorScheme.tertiary, resolved.tertiaryKey);
    });
  });
}
