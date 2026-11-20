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

UnifiedMedia mediaWith({
  String format = 'anime',
  int? year = 2024,
  String? status = 'Airing',
  List<String> genres = const ['Action'],
  double? score = 8.5,
  String title = 'Test Title',
}) {
  return UnifiedMedia(
    id: 'm1',
    type: MediaType.ANIME,
    title: MediaTitle(english: title),
    format: format,
    year: year,
    status: status,
    genres: genres,
    score: score,
  );
}

CardContent contentWith({
  String? subtitle,
  double? progress,
  String? progressText,
  bool showYear = true,
  bool showGenres = true,
  Widget? topLeftBadge,
  Widget? topRightBadge,
  Widget? bottomLeftBadge,
  Widget? bottomRightBadge,
}) {
  return CardContent(
    media: mediaWith(),
    width: 140,
    height: 230,
    isActive: false,
    isWideMode: false,
    showRatings: true,
    showYear: showYear,
    showGenres: showGenres,
    subtitle: subtitle,
    progress: progress,
    progressText: progressText,
    heroTag: null,
    topLeftBadge: topLeftBadge,
    topRightBadge: topRightBadge,
    bottomLeftBadge: bottomLeftBadge,
    bottomRightBadge: bottomRightBadge,
  );
}

UnifiedMedia routingMedia() {
  return UnifiedMedia(
    id: 'routing',
    type: MediaType.ANIME,
    title: MediaTitle(english: 'T'),
  );
}

Widget renderCard(MediaCardStyle style, {String? subtitle}) {
  return MaterialApp(
    home: Center(
      child: SizedBox(
        width: 140,
        height: 230,
        child: CardRenderer(
          style: style,
          media: routingMedia(),
          width: 140,
          height: 230,
          isActive: false,
          isWideMode: false,
          showRatings: true,
          showYear: true,
          showGenres: true,
          subtitle: subtitle,
        ),
      ),
    ),
  );
}

void main() {
  test('explicit subtitle wins over year, status and genres', () {
    final content = contentWith(subtitle: 'Explicit subtitle');
    expect(content.resolvedSubtitle, 'Explicit subtitle');
    expect(resolveCardSubtitle(content), 'Explicit subtitle');
  });

  test(
    'resolved subtitle honours the visibility flags and absent metadata',
    () {
      final flagged = contentWith(showYear: false, showGenres: false);
      expect(flagged.resolvedSubtitle, 'Airing');

      final allMetadata = contentWith(showYear: true, showGenres: true);
      expect(allMetadata.resolvedSubtitle, '2024 • Airing • Action');

      final bare = CardContent(
        media: UnifiedMedia(id: 'bare', type: MediaType.ANIME),
        width: 140,
        height: 230,
        isActive: false,
        isWideMode: false,
        showRatings: false,
        showYear: true,
        showGenres: true,
      );
      expect(bare.resolvedSubtitle, isNull);
      expect(resolveCardSubtitle(bare), isNull);
    },
  );

  test(
    'copyWith changes only the requested field and clears explicit nulls',
    () {
      final topLeft = Container(key: const Key('top-left'));
      final topRight = Container(key: const Key('top-right'));
      final bottomLeft = Container(key: const Key('bottom-left'));
      final bottomRight = Container(key: const Key('bottom-right'));
      final original = contentWith(
        subtitle: 'Original',
        progress: 0.2,
        progressText: '20%',
        topLeftBadge: topLeft,
        topRightBadge: topRight,
        bottomLeftBadge: bottomLeft,
        bottomRightBadge: bottomRight,
      );

      final copy = original.copyWith(progress: 0.5);
      expect(copy.progress, 0.5);
      expect(original.progress, 0.2);
      expect(copy.media, same(original.media));
      expect(copy.width, original.width);
      expect(copy.height, original.height);
      expect(copy.isActive, original.isActive);
      expect(copy.isWideMode, original.isWideMode);
      expect(copy.showRatings, original.showRatings);
      expect(copy.showYear, original.showYear);
      expect(copy.showGenres, original.showGenres);
      expect(copy.subtitle, original.subtitle);
      expect(copy.progressText, original.progressText);
      expect(copy.heroTag, original.heroTag);
      expect(copy.topLeftBadge, same(topLeft));
      expect(copy.topRightBadge, same(topRight));
      expect(copy.bottomLeftBadge, same(bottomLeft));
      expect(copy.bottomRightBadge, same(bottomRight));

      final cleared = original.copyWith(progress: null, progressText: null);
      expect(cleared.progress, isNull);
      expect(cleared.progressText, isNull);
      expect(cleared.subtitle, 'Original');
    },
  );

  testWidgets('CardMediaStack composes the thumbnail and badge overlay', (
    tester,
  ) async {
    final content = contentWith(progress: 0.5, progressText: '50%');
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 140,
          height: 230,
          child: CardMediaStack(
            content: content,
            styleName: 'classic',
            thumbWidth: 140,
            thumbHeight: 230,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('ANIME'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('CardRenderer routes all nine styles to distinct widgets', (
    tester,
  ) async {
    final expected = <MediaCardStyle, Type>{
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
    expect(expected.length, 9);
    expect(expected.values.toSet().length, 9);

    for (final style in MediaCardStyle.values) {
      await tester.pumpWidget(renderCard(style));
      expect(
        tester.takeException(),
        isNull,
        reason: '${style.displayName} threw',
      );
      expect(
        find.byType(expected[style]!),
        findsOneWidget,
        reason: '${style.displayName} did not render its own widget',
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: '${style.displayName} showed the loading overlay',
      );
    }
  });

  testWidgets(
    'Classic renders the shared subtitle through the content object',
    (tester) async {
      await tester.pumpWidget(
        renderCard(MediaCardStyle.classic, subtitle: 'Explicit subtitle'),
      );
      expect(find.text('Explicit subtitle'), findsOneWidget);
    },
  );
}
