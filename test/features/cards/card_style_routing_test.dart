import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';
import 'package:shonenx/shared/widgets/card/components/card_content.dart';
import 'package:shonenx/shared/widgets/card/styles/cinematic_card.dart';
import 'package:shonenx/shared/widgets/card/styles/classic_card.dart';
import 'package:shonenx/shared/widgets/card/styles/compact_card.dart';
import 'package:shonenx/shared/widgets/card/styles/editorial_card.dart';
import 'package:shonenx/shared/widgets/card/styles/expressive_card.dart';
import 'package:shonenx/shared/widgets/card/styles/material_card.dart';
import 'package:shonenx/shared/widgets/card/styles/minimal_card.dart';
import 'package:shonenx/shared/widgets/card/styles/neon_card.dart';
import 'package:shonenx/shared/widgets/card/styles/wide_banner_card.dart';

const String pinnedTitle = 'T';

final Map<MediaCardStyle, Type> expectedStyleWidgets = <MediaCardStyle, Type>{
  MediaCardStyle.classic: ClassicCard,
  MediaCardStyle.minimal: MinimalCard,
  MediaCardStyle.expressive: ExpressiveCard,
  MediaCardStyle.material: MaterialCard,
  MediaCardStyle.cinematic: CinematicCard,
  MediaCardStyle.neon: NeonCard,
  MediaCardStyle.compact: CompactCard,
  MediaCardStyle.editorial: EditorialCard,
  MediaCardStyle.wideBanner: WideBannerCard,
};

CardContent contentOf(Widget widget) {
  if (widget is ClassicCard) return widget.content;
  if (widget is MinimalCard) return widget.content;
  if (widget is ExpressiveCard) return widget.content;
  if (widget is MaterialCard) return widget.content;
  if (widget is CinematicCard) return widget.content;
  if (widget is NeonCard) return widget.content;
  if (widget is CompactCard) return widget.content;
  if (widget is EditorialCard) return widget.content;
  if (widget is WideBannerCard) return widget.content;
  throw StateError('Unrecognized card style widget: $widget');
}

Widget pumpCard(MediaCardStyle style, {bool isLoading = false}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    ),
    home: Center(
      child: SizedBox(
        width: 400,
        height: 230,
        child: CardRenderer(
          style: style,
          media: UnifiedMedia(
            id: 'route-${style.name}',
            type: MediaType.ANIME,
            title: MediaTitle(english: pinnedTitle),
          ),
          width: 400,
          height: 230,
          isActive: false,
          isWideMode: false,
          showRatings: true,
          showYear: true,
          showGenres: true,
          isLoading: isLoading,
        ),
      ),
    ),
  );
}

void main() {
  test('all nine styles map to nine pairwise-distinct widget types', () {
    expect(MediaCardStyle.values.length, 9);
    expect(expectedStyleWidgets.length, 9);
    expect(expectedStyleWidgets.values.toSet().length, 9);
    for (final style in MediaCardStyle.values) {
      expect(
        expectedStyleWidgets.containsKey(style),
        isTrue,
        reason: '${style.displayName} has no expected widget type',
      );
    }
  });

  for (final entry in expectedStyleWidgets.entries) {
    final style = entry.key;
    final widgetType = entry.value;

    testWidgets('$widgetType receives CardContent and renders the title', (
      tester,
    ) async {
      await tester.pumpWidget(pumpCard(style));
      expect(tester.takeException(), isNull);

      final styleFinder = find.byType(widgetType);
      expect(styleFinder, findsOneWidget);

      final styleWidget = tester.widget(styleFinder);
      expect(styleWidget.runtimeType, widgetType);

      final content = contentOf(styleWidget);
      expect(content, isA<CardContent>());
      expect(content.media.title.getPreferedTitle, pinnedTitle);
      expect(find.text(pinnedTitle), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('$widgetType stays in the tree under the loading overlay', (
      tester,
    ) async {
      await tester.pumpWidget(pumpCard(style, isLoading: true));
      expect(tester.takeException(), isNull);

      expect(find.byType(widgetType), findsOneWidget);
      expect(find.text(pinnedTitle), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  }
}
