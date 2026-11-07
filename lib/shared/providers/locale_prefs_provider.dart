import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

/// Represents a supported language in ShonenX.
class AppLanguageInfo {
  final String code;
  final String nativeName;
  final String englishName;
  final bool isRtl;

  const AppLanguageInfo({
    required this.code,
    required this.nativeName,
    required this.englishName,
    this.isRtl = false,
  });

  Locale get locale => Locale(code);

  String get displayName => '$nativeName ($englishName)';
}

/// 10 Supported application interface languages in ShonenX.
const List<AppLanguageInfo> kSupportedAppLanguages = [
  AppLanguageInfo(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
  ),
  AppLanguageInfo(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
  ),
  AppLanguageInfo(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
  ),
  AppLanguageInfo(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
  ),
  AppLanguageInfo(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
  ),
  AppLanguageInfo(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
  ),
  AppLanguageInfo(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
  ),
  AppLanguageInfo(
    code: 'ar',
    nativeName: 'العربية',
    englishName: 'Arabic',
    isRtl: true,
  ),
  AppLanguageInfo(
    code: 'bn',
    nativeName: 'বাংলা',
    englishName: 'Bengali',
  ),
  AppLanguageInfo(
    code: 'yue',
    nativeName: '廣東話',
    englishName: 'Cantonese',
  ),
];

class AppLocaleNotifier extends Notifier<Locale?> {
  static const _keyLocale = 'app_locale_code';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  Locale? build() {
    final storage = ref.watch(sharedPreferencesProvider);
    final savedCode = storage.getString(_keyLocale);

    if (savedCode == null || savedCode.isEmpty) {
      return null; // System Default
    }

    final matched = kSupportedAppLanguages.any((lang) => lang.code == savedCode);
    if (!matched) {
      return null;
    }

    return Locale(savedCode);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _storage.remove(_keyLocale);
    } else {
      await _storage.setString(_keyLocale, locale.languageCode);
    }
  }

  /// Helper to get the display title of the current locale.
  String get currentDisplayName {
    if (state == null) {
      return 'System Default';
    }
    final info = kSupportedAppLanguages.firstWhere(
      (lang) => lang.code == state!.languageCode,
      orElse: () => const AppLanguageInfo(
        code: 'en',
        nativeName: 'English',
        englishName: 'English',
      ),
    );
    return info.nativeName;
  }
}

final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

