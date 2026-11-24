import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/core/router/bottom_nav_bar.dart';
import 'package:shonenx/core/router/nav_bar_destinations.dart';
import 'package:shonenx/core/router/nav_download_button.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

void main() {
  final cs = ColorScheme.fromSeed(seedColor: Colors.indigo);
  const destinations = <NavBarDestination>[
    NavBarDestination(Icons.home_outlined, 'Home'),
    NavBarDestination(Icons.search_rounded, 'Search'),
    NavBarDestination(Icons.library_books_outlined, 'Library'),
  ];
  const downloadLabel = 'Downloads';
  const floatingStyles = [
    NavBarStyle.classic,
    NavBarStyle.minimal,
    NavBarStyle.frosted,
    NavBarStyle.material,
  ];

  Widget harness(Widget child, {double width = 360}) {
    return MaterialApp(
      theme: ThemeData(colorScheme: cs),
      home: Scaffold(body: SizedBox(width: width, height: 120, child: child)),
    );
  }

  Future<void> pumpFloating(
    WidgetTester tester,
    NavBarStyle style, {
    int currentIndex = 0,
    double width = 360,
    NavBarSelect? onSelect,
  }) async {
    await tester.pumpWidget(
      harness(
        BottomNavBarView(
          navBarStyle: style,
          currentIndex: currentIndex,
          destinations: destinations,
          onSelect: onSelect,
          download: DownloadActivity.none,
          metrics: NavBarMetrics.preview,
        ),
        width: width,
      ),
    );
    // Finite step: the inactive circular progress indicator animates
    // indefinitely, so pumpAndSettle would never complete.
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('floating bar renders all four non-docked styles', (tester) async {
    for (final style in floatingStyles) {
      await pumpFloating(tester, style);
      expect(tester.takeException(), isNull, reason: '$style threw');
      expect(find.text('Home'), findsOneWidget);
      for (final destination in destinations) {
        expect(find.byIcon(destination.icon), findsOneWidget);
      }
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    }
  });

  testWidgets('active label moves with currentIndex', (tester) async {
    for (final style in floatingStyles) {
      // The active "Library" pill is wider than "Home"; give this synthetic
      // off-preview index enough room so the assertion is about the pill move.
      await pumpFloating(tester, style, currentIndex: 2, width: 400);
      expect(tester.takeException(), isNull, reason: '$style threw');
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    }
  });

  testWidgets('docked bar renders all four destinations', (tester) async {
    await tester.pumpWidget(
      harness(
        DockedBottomNavBar(
          destinations: destinations,
          currentIndex: 0,
          onSelect: null,
          download: DownloadActivity.none,
          downloadLabel: downloadLabel,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    for (final destination in destinations) {
      expect(find.text(destination.label), findsOneWidget);
    }
    expect(find.text(downloadLabel), findsOneWidget);
  });

  testWidgets('null callback is inert and a real callback receives the tap', (
    tester,
  ) async {
    await pumpFloating(tester, NavBarStyle.classic);
    await tester.tap(find.byIcon(Icons.home_outlined), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);

    final tapped = <int>[];
    await pumpFloating(
      tester,
      NavBarStyle.classic,
      onSelect: (index, {resetOnReselect = false}) => tapped.add(index),
    );
    await tester.tap(find.byIcon(Icons.home_outlined), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tapped, [0]);
  });
}
