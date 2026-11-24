import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';

void main() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  final icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.bookmark_rounded,
  ];

  List<PickerOption> optionsFor({
    int selectedIndex = -1,
    List<String>? taps,
  }) => [
    for (var i = 0; i < icons.length; i++)
      PickerOption(
        icon: icons[i],
        title: 'Option $i',
        subtitle: 'Subtitle $i',
        selected: i == selectedIndex,
        onTap: () {
          taps?.add('Option $i');
        },
      ),
  ];

  Widget appFor(List<PickerOption> options) => MaterialApp(
    theme: ThemeData(colorScheme: colorScheme),
    home: Scaffold(
      body: SingleChildScrollView(
        child: UiSettingsSheetLayout(
          preview: const Text('picker-preview'),
          optionsTitle: 'Preset',
          options: PickerOptionsGrid(
            options: options,
            selectedColor: colorScheme.primary,
          ),
          togglesTitle: 'Toggles',
          toggles: const Text('picker-toggles'),
        ),
      ),
    ),
  );

  Finder cardWithTitle(String title) => find.byWidgetPredicate(
    (widget) => widget is PickerOptionCard && widget.title == title,
  );

  testWidgets('the layout owns every region and the grid maps every option', (
    tester,
  ) async {
    await tester.pumpWidget(appFor(optionsFor()));

    expect(find.text('picker-preview'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    for (final icon in icons) {
      final index = icons.indexOf(icon);
      expect(find.text('Option $index'), findsOneWidget);
    }
    expect(find.text('Toggles'), findsOneWidget);
    expect(find.text('picker-toggles'), findsOneWidget);
    expect(find.byType(PickerOptionCard), findsNWidgets(3));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('only the selected card shows the check affordance', (
    tester,
  ) async {
    await tester.pumpWidget(appFor(optionsFor(selectedIndex: 1)));

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: cardWithTitle('Option 1'),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cardWithTitle('Option 0'),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping an option fires its own callback exactly once', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(appFor(optionsFor(taps: taps)));

    await tester.tap(cardWithTitle('Option 2'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(taps, ['Option 2']);
  });
}
