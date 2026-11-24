import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/core/router/nav_bar_theme.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

void main() {
  final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));

  NavBarThemeData resolve(NavBarStyle style, {bool downloadActive = false}) =>
      NavBarThemeData.resolve(style, cs, downloadActive);

  group('NavBarThemeData.resolve', () {
    test('every nav bar style resolves a complete theme', () {
      for (final style in NavBarStyle.values) {
        final theme = resolve(style);
        expect(theme.barDecoration, isNotNull);
        expect(theme.barRadius(80), greaterThanOrEqualTo(0));
        expect(theme.itemRadius(80), greaterThanOrEqualTo(0));
      }
    });

    test('docked is solid, sharp and shows the dot indicator', () {
      final theme = resolve(NavBarStyle.docked);
      expect(theme.blurSigma, isNull);
      expect(theme.barRadius(80), 0);
      expect(theme.itemRadius(80), GlobalUI.uiRoundness);
      expect(theme.showDotIndicator, isTrue);
    });

    test('material is solid, fully rounded and material-3', () {
      final theme = resolve(NavBarStyle.material);
      expect(theme.blurSigma, isNull);
      expect(theme.itemRadius(37), 100);
      expect(theme.isMaterial3, isTrue);
    });

    test('minimal and frosted blur; minimal shows the dot indicator', () {
      final minimal = resolve(NavBarStyle.minimal);
      final frosted = resolve(NavBarStyle.frosted);
      expect(minimal.blurSigma, isNotNull);
      expect(frosted.blurSigma, isNotNull);
      expect(minimal.showDotIndicator, isTrue);
    });

    test('download-active flag changes classic and frosted icon color', () {
      for (final style in [NavBarStyle.classic, NavBarStyle.frosted]) {
        final inactive = resolve(style);
        final active = resolve(style, downloadActive: true);
        expect(active.downloadIconColor, isNot(inactive.downloadIconColor));
      }
    });
  });
}
