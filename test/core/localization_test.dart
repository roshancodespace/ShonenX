import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/localization/cantonese_localizations_delegate.dart';
import 'package:shonenx/l10n/generated/app_localizations.dart';
import 'package:shonenx/shared/providers/locale_prefs_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization Infrastructure Tests', () {
    test('AppLocalizations supports all 10 target locales', () {
      final supportedCodes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      const expectedCodes = {
        'en',
        'hi',
        'ja',
        'es',
        'pt',
        'fr',
        'de',
        'ar',
        'bn',
        'yue',
      };

      for (final code in expectedCodes) {
        expect(
          supportedCodes.contains(code),
          isTrue,
          reason: 'Locale $code must be supported by AppLocalizations',
        );
      }
    });

    test('CantoneseMaterialLocalizationsDelegate supports yue and loads zh_HK fallback', () async {
      const delegate = CantoneseMaterialLocalizationsDelegate();
      expect(delegate.isSupported(const Locale('yue')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isFalse);

      final materialLocalizations = await delegate.load(const Locale('yue'));
      expect(materialLocalizations, isNotNull);
      expect(materialLocalizations.okButtonLabel, isNotEmpty);
    });

    test('CantoneseCupertinoLocalizationsDelegate supports yue', () async {
      const delegate = CantoneseCupertinoLocalizationsDelegate();
      expect(delegate.isSupported(const Locale('yue')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isFalse);

      final cupertinoLocalizations = await delegate.load(const Locale('yue'));
      expect(cupertinoLocalizations, isNotNull);
    });

    const delegates = <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      CantoneseMaterialLocalizationsDelegate(),
      CantoneseCupertinoLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets('AppLocalizations loads translations and handles plurals', (tester) async {
      late AppLocalizations l10nEn;
      late AppLocalizations l10nYue;
      late AppLocalizations l10nBn;
      late AppLocalizations l10nAr;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10nEn = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10nEn.navHome, 'Home');
      expect(l10nEn.homeGoodMorning, 'Good morning');
      expect(l10nEn.readerNextPage, 'Next Page');
      expect(l10nEn.episodesCount(0), 'No episodes');
      expect(l10nEn.episodesCount(1), '1 episode');
      expect(l10nEn.episodesCount(12), '12 episodes');

      // Test Cantonese
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('yue'),
          home: Builder(
            builder: (context) {
              l10nYue = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10nYue.navHome, '主頁');
      expect(l10nYue.settingsLanguage, '介面語言');
      expect(l10nYue.homeGoodMorning, '早晨');
      expect(l10nYue.readerNextPage, '下一頁');
      expect(l10nYue.episodesCount(0), '冇任何集數');
      expect(l10nYue.episodesCount(5), '5 集');

      // Test Bengali
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('bn'),
          home: Builder(
            builder: (context) {
              l10nBn = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10nBn.navHome, 'হোম');
      expect(l10nBn.settingsLanguage, 'ভাষা');
      expect(l10nBn.homeGoodMorning, 'সুপ্রভাত');
      expect(l10nBn.readerNextPage, 'পরবর্তী পৃষ্ঠা');

      // Test Arabic
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              l10nAr = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10nAr.navHome, 'الرئيسية');
      expect(l10nAr.settingsLanguage, 'اللغة');
      expect(l10nAr.homeGoodMorning, 'صباح الخير');
      expect(l10nAr.readerNextPage, 'الصفحة التالية');
    });

    test('AppLocaleNotifier persists and updates locale state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final testContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      addTearDown(testContainer.dispose);

      // Initial state should be null (System Default)
      expect(testContainer.read(appLocaleProvider), isNull);
      expect(
        testContainer.read(appLocaleProvider.notifier).currentDisplayName,
        'System Default',
      );

      // Change locale to Hindi
      await testContainer
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('hi'));
      expect(testContainer.read(appLocaleProvider), const Locale('hi'));
      expect(prefs.getString('app_locale_code'), 'hi');
      expect(
        testContainer.read(appLocaleProvider.notifier).currentDisplayName,
        'हिन्दी',
      );

      // Change locale to Cantonese
      await testContainer
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('yue'));
      expect(testContainer.read(appLocaleProvider), const Locale('yue'));
      expect(prefs.getString('app_locale_code'), 'yue');
      expect(
        testContainer.read(appLocaleProvider.notifier).currentDisplayName,
        '廣東話',
      );

      // Reset to System Default
      await testContainer.read(appLocaleProvider.notifier).setLocale(null);
      expect(testContainer.read(appLocaleProvider), isNull);
      expect(prefs.containsKey('app_locale_code'), isFalse);
    });

    test('Supported languages accurately flag Arabic as RTL', () {
      final arInfo =
          kSupportedAppLanguages.firstWhere((l) => l.code == 'ar');
      expect(arInfo.isRtl, isTrue);

      final enInfo =
          kSupportedAppLanguages.firstWhere((l) => l.code == 'en');
      expect(enInfo.isRtl, isFalse);
    });
  });
}
