import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/settings/presentation/widgets/episode_mode_picker.dart';

void main() {
  final cs = ColorScheme.fromSeed(seedColor: Colors.indigo);

  final expectations = <EpisodeViewMode, ({Type tileType, String key})>{
    EpisodeViewMode.classic: (
      tileType: EpisodeClassicTile,
      key: 'episode_preview_classic',
    ),
    EpisodeViewMode.grid: (
      tileType: EpisodeGridTile,
      key: 'episode_preview_grid',
    ),
    EpisodeViewMode.box: (
      tileType: EpisodeBoxTile,
      key: 'episode_preview_box',
    ),
    EpisodeViewMode.compact: (
      tileType: EpisodeCompactTile,
      key: 'episode_preview_compact',
    ),
    EpisodeViewMode.cover: (
      tileType: EpisodeCoverTile,
      key: 'episode_preview_cover',
    ),
  };

  const legacyKeys = [
    'classic_flat',
    'grid_flat',
    'box_flat',
    'compact_flat',
    'cover_flat',
  ];

  Future<void> pumpPreview(WidgetTester tester, EpisodeViewMode mode) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: cs),
        home: Scaffold(
          body: SizedBox(height: 300, child: EpisodeModePreview(mode: mode)),
        ),
      ),
    );
    // Finite step: AnimatedSize and the tiles' ink animations never settle.
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('all five modes render a production tile with a mode key and stay inert', (
    tester,
  ) async {
    for (final entry in expectations.entries) {
      final mode = entry.key;
      final expected = entry.value;

      await pumpPreview(tester, mode);
      expect(tester.takeException(), isNull, reason: '$mode threw on pump');

      expect(
        find.byType(expected.tileType),
        findsWidgets,
        reason: '$mode did not render ${expected.tileType}',
      );
      expect(
        find.byKey(ValueKey(expected.key)),
        findsOneWidget,
        reason: '$mode did not render its own key',
      );
      for (final legacy in legacyKeys) {
        expect(
          find.byKey(ValueKey(legacy)),
          findsNothing,
          reason: '$mode retained legacy key $legacy',
        );
      }

      await tester.tap(find.byType(expected.tileType).first, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$mode tile tap threw');
    }
  });
}
