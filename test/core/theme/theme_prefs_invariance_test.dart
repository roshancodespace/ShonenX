import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/theme/standard_schemes.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late Directory tempDir;
  late String wallpaperPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('shonenx_theme_prefs_');
    wallpaperPath = '${tempDir.path}/wallpaper.png';
    await File(wallpaperPath).writeAsBytes(const <int>[0]);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer openContainer() {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'every appearance preference reloads unchanged from app_theme_data',
    () async {
      final container = openContainer();
      final state = ThemePrefsState(
        useAmoled: true,
        useGradients: true,
        useNoiseOverlay: true,
        blendLevel: 24,
        gradientStyle: BackgroundGradientStyle.radial,
        gradientDirection: BackgroundGradientDirection.horizontal,
        gradientColorPair: BackgroundGradientColorPair.vibrantMix,
        gradientIntensity: 0.72,
        noiseOpacity: 0.11,
        wallpaperSettings: WallpaperSettings(
          imagePath: wallpaperPath,
          processedPath: wallpaperPath,
          blur: 6.5,
          opacity: 0.78,
          saturation: 1.4,
          brightness: 1.2,
          imageColorSeed: 0xFF336699,
        ),
        useImageColors: true,
        uiRoundness: 18.0,
        fontScaleFactor: 1.15,
        uiScaleFactor: 0.92,
      );

      container.read(themePrefsProvider.notifier).updateTheme((_) => state);

      final stored = prefs.getString('app_theme_data');
      expect(stored, isNotNull);
      for (final key in <String>[
        'useAmoled',
        'useGradients',
        'useNoiseOverlay',
        'blendLevel',
        'gradientStyle',
        'gradientDirection',
        'gradientColorPair',
        'gradientIntensity',
        'noiseOpacity',
        'uiRoundness',
        'fontScaleFactor',
        'uiScaleFactor',
        'wallpaperSettings',
        'useImageColors',
      ]) {
        expect(stored, contains('"$key"'), reason: 'missing stored key $key');
      }

      container.dispose();
      final reloaded = openContainer().read(themePrefsProvider);

      expect(reloaded, state);
      expect(reloaded.useAmoled, isTrue);
      expect(reloaded.useGradients, isTrue);
      expect(reloaded.useNoiseOverlay, isTrue);
      expect(reloaded.blendLevel, 24);
      expect(reloaded.gradientStyle, BackgroundGradientStyle.radial);
      expect(
        reloaded.gradientDirection,
        BackgroundGradientDirection.horizontal,
      );
      expect(
        reloaded.gradientColorPair,
        BackgroundGradientColorPair.vibrantMix,
      );
      expect(reloaded.gradientIntensity, 0.72);
      expect(reloaded.noiseOpacity, 0.11);
      expect(reloaded.uiRoundness, 18.0);
      expect(reloaded.fontScaleFactor, 1.15);
      expect(reloaded.uiScaleFactor, 0.92);
      expect(reloaded.useImageColors, isTrue);

      final wallpaper = reloaded.wallpaperSettings;
      expect(wallpaper, isNotNull);
      expect(wallpaper!.imagePath, wallpaperPath);
      expect(wallpaper.processedPath, wallpaperPath);
      expect(wallpaper.blur, 6.5);
      expect(wallpaper.opacity, 0.78);
      expect(wallpaper.saturation, 1.4);
      expect(wallpaper.brightness, 1.2);
      expect(wallpaper.imageColorSeed, 0xFF336699);
      expect(reloaded.backgroundImageOpacity, 0.78);
    },
  );

  test(
    'default preferences survive toJson and fromJson with documented defaults',
    () {
      const defaults = ThemePrefsState();
      final restored = ThemePrefsState.fromJson(defaults.toJson());

      expect(restored, defaults);
      expect(restored.flexScheme, AppScheme.deepBlue);
      expect(restored.themeVariant, AppThemeVariant.classic);
      expect(restored.blendLevel, 10);
      expect(restored.gradientIntensity, 0.35);
      expect(restored.noiseOpacity, 0.03);
      expect(restored.uiRoundness, 12.0);
      expect(restored.fontScaleFactor, 1.0);
      expect(restored.uiScaleFactor, 1.0);
      expect(restored.wallpaperSettings, isNull);
    },
  );
}
