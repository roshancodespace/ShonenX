import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/settings/presentation/widgets/card_style_picker.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card style sheet previews live, persists and restores selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    const openKey = ValueKey('open-card-style-sheet');

    Widget app({Key? key}) => ProviderScope(
      key: key,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            final notifier = ref.read(uiPrefsProvider.notifier);
            final theme = Theme.of(context);
            return Scaffold(
              body: ElevatedButton(
                key: openKey,
                onPressed: () =>
                    showCardStyleSheet(context, ref, notifier, theme),
                child: const Text('open card style sheet'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpWidget(app());

    Future<void> openSheet() async {
      await tester.tap(find.byKey(openKey));
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> selectStyle(String label) async {
      final card = tester.widget<PickerOptionCard>(
        find.byWidgetPredicate(
          (widget) => widget is PickerOptionCard && widget.title == label,
        ),
      );
      card.onTap();
      await tester.pump(const Duration(milliseconds: 350));
    }

    MediaCard preview() => tester.widget<MediaCard>(find.byType(MediaCard));

    await openSheet();
    expect(find.byType(MediaCard), findsOneWidget);
    expect(preview().style, MediaCardStyle.classic);

    await selectStyle(MediaCardStyle.neon.displayName);
    expect(find.byType(MediaCard), findsOneWidget);
    expect(preview().style, MediaCardStyle.neon);

    final saved = prefs.getString('ui_preferences');
    expect(saved, isNotNull);
    expect(saved, contains('"cardStyle":"neon"'));

    await tester.pumpWidget(app(key: const ValueKey('reopened')));
    await openSheet();
    expect(find.byType(MediaCard), findsOneWidget);
    expect(preview().style, MediaCardStyle.neon);
    final neonCard = find.byWidgetPredicate(
      (widget) =>
          widget is PickerOptionCard &&
          widget.title == MediaCardStyle.neon.displayName,
    );
    expect(
      find.descendant(of: neonCard, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
