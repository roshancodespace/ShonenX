import 'package:material_ui/material_ui.dart' as mui;
import 'package:material_ui/material_ui.dart' hide GlobalMaterialLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/core/localization/cantonese_localizations_delegate.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/l10n/generated/app_localizations.dart';

void main() {
  final delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    const CantoneseMaterialLocalizationsDelegate(),
    const CantoneseCupertinoLocalizationsDelegate(),
    ...mui.GlobalMaterialLocalizations.delegates,
    ...GlobalMaterialLocalizations.delegates,
  ];

  Widget appFor(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('every settings tile uses the shared horizontal padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      appFor(
        Column(
          children: [
            SettingsNavTile(title: 'nav', onTap: () {}),
            SettingsSwitchTile(title: 'switch', value: false),
            SettingsActionTile(title: 'action'),
            SettingsSliderTile(
              icon: Icons.speed,
              title: 'slider',
              value: 0.5,
              label: 'half',
            ),
            SettingsDropdownTile<String>(
              icon: Icons.list,
              title: 'dropdown',
              value: 'a',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('a')),
              ],
            ),
            SettingsRadioTile<String>(
              title: 'radio',
              value: 'a',
              groupValue: 'a',
              onChanged: null,
            ),
            const SettingsSelectionTile(
              title: 'selection',
              subtitle: 'description',
              isSelected: false,
            ),
          ],
        ),
      ),
    );

    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(7));
    for (final element in tiles.evaluate()) {
      expect(
        (element.widget as ListTile).contentPadding,
        EdgeInsets.symmetric(horizontal: 10),
      );
    }
  });

  testWidgets('section headers render an uppercased label', (tester) async {
    await tester.pumpWidget(
      appFor(
        const SettingsSection(title: 'general label', children: [SizedBox()]),
      ),
    );

    expect(find.text('GENERAL LABEL'), findsOneWidget);
  });

  testWidgets('dropdown info tooltip resolves through AppLocalizations', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      appFor(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return SettingsDropdownTile<String>(
              icon: Icons.list,
              title: 'dropdown',
              value: 'a',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('a')),
              ],
              onInfoCallback: () {},
            );
          },
        ),
        locale: const Locale('es'),
      ),
    );

    final infoButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip != null,
    );
    expect(infoButton, findsOneWidget);
    expect(tester.widget<IconButton>(infoButton).tooltip, l10n.settingsInfo);
    expect(l10n.settingsInfo, isNot('Info'));
  });

  testWidgets('selection tile customize label falls back to the localized label', (
    tester,
  ) async {
    late AppLocalizations l10n;

    Widget selection({String? customizeLabel}) => SettingsSelectionTile(
      title: 'style',
      subtitle: 'description',
      isSelected: false,
      onCustomize: () {},
      customizeLabel: customizeLabel,
    );

    await tester.pumpWidget(
      appFor(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return selection();
          },
        ),
      ),
    );
    expect(find.text(l10n.settingsCustomize), findsOneWidget);

    await tester.pumpWidget(
      appFor(Builder(builder: (context) => selection(customizeLabel: 'Edit this'))),
    );
    expect(find.text('Edit this'), findsOneWidget);
    expect(find.text(l10n.settingsCustomize), findsNothing);
  });

  testWidgets('value chip renders its label without a list tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      appFor(const SettingsValueChip(label: 'Standard')),
    );

    expect(find.text('Standard'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
