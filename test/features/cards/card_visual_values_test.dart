import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import 'package:shonenx/shared/widgets/card/components/card_badges.dart';

const _styleNames = <String>[
  'expressive',
  'material',
  'minimal',
  'neon',
  'editorial',
  'cinematic',
  'classic',
];

ThemeData _theme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    ),
  );
}

BoxDecoration _ratingDecoration(String style) {
  final widget = CardBadgeOverlay.buildStyleRatingBadge(_theme(), style, '8.5');
  return (widget as Container).decoration! as BoxDecoration;
}

void main() {
  test('named card values match the literals they replace', () {
    expect(UiSpace.xs, 4);
    expect(UiSpace.sm, 8);
    expect(UiSpace.md, 12);
    expect(UiSpace.lg, 16);
    expect(UiSpace.xl, 24);

    expect(UiRadius.sm, 4);
    expect(UiRadius.md, 6);
    expect(UiRadius.card, 12);
    expect(UiRadius.wide, 10);

    expect(UiAlpha.chip, 0.12);
    expect(UiAlpha.faint, 0.15);
    expect(UiAlpha.subtle, 0.22);
    expect(UiAlpha.outline, 0.28);
    expect(UiAlpha.medium, 0.3);
    expect(UiAlpha.placeholder, 0.35);
    expect(UiAlpha.border, 0.4);
    expect(UiAlpha.glowBorder, 0.45);
    expect(UiAlpha.glow, 0.48);
    expect(UiAlpha.half, 0.5);
    expect(UiAlpha.scrimSoft, 0.65);
    expect(UiAlpha.scrim, 0.78);
    expect(UiAlpha.scrimStrong, 0.82);
    expect(UiAlpha.solidSoft, 0.85);
    expect(UiAlpha.solid, 0.88);
    expect(UiAlpha.solidHigh, 0.9);
    expect(UiAlpha.solidMid, 0.92);
    expect(UiAlpha.strong, 0.95);

    expect(UiBlur.soft, 4);
    expect(UiBlur.glow, 6);
    expect(UiBlur.glowWide, 10);
    expect(UiBlur.glowActive, 20);

    expect(UiElevation.resting, 1);
    expect(UiElevation.active, 6);
  });

  test('all seven style rating badges keep distinct decoration colors', () {
    final colors = <String, Color>{};
    for (final style in _styleNames) {
      colors[style] = _ratingDecoration(style).color!;
    }
    expect(colors.length, 7);

    final values = colors.values.toList();
    for (var i = 0; i < values.length; i++) {
      for (var j = i + 1; j < values.length; j++) {
        expect(
          values[i],
          isNot(values[j]),
          reason: 'badge colors ${i + 1} and ${j + 1} collapsed',
        );
      }
    }
  });

  test('rating badges keep their original surfaces, borders and radii', () {
    final cs = _theme().colorScheme;
    final expected = <String, BoxDecoration>{
      'expressive': BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      'material': BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      'minimal': BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      'neon': BoxDecoration(
        color: cs.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.primary, width: 1.2),
      ),
      'editorial': BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      'cinematic': BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFB703).withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      'classic': BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFB703).withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
    };

    for (final style in _styleNames) {
      final actual = _ratingDecoration(style);
      final want = expected[style]!;
      expect(actual.color, want.color, reason: '$style surface drifted');
      expect(
        actual.borderRadius,
        want.borderRadius,
        reason: '$style radius drifted',
      );
      expect(actual.border, want.border, reason: '$style border drifted');
    }
  });

  test('only the two neon glow shadows remain in the badge component', () {
    final source = File(
      'lib/shared/widgets/card/components/card_badges.dart',
    ).readAsStringSync();

    expect(RegExp(r'BoxShadow\(').allMatches(source).length, 2);

    final neonCases = RegExp(r"case 'neon':").allMatches(source).toList();
    expect(neonCases.length, 2);
    for (final neon in neonCases) {
      final nextCase = source.indexOf('case ', neon.end);
      final branch = source.substring(
        neon.start,
        nextCase < 0 ? source.length : nextCase,
      );
      expect(
        RegExp(r'BoxShadow\(').hasMatch(branch),
        isTrue,
        reason: 'a neon branch lost its glow',
      );
      expect(branch, contains('UiBlur.glow'));
    }
  });

  test('neon card keeps its dark surface and named glow', () {
    final source = File(
      'lib/shared/widgets/card/styles/neon_card.dart',
    ).readAsStringSync();
    for (final token in const [
      'Color(0xFF0C0E14)',
      'UiAlpha.glow',
      'UiAlpha.subtle',
      'UiBlur.glowActive',
      'UiBlur.glowWide',
    ]) {
      expect(source, contains(token), reason: 'neon lost $token');
    }
  });
}
