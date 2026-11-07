import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Provides Flutter framework MaterialLocalizations for Cantonese (`yue`).
///
/// Since Flutter's [GlobalMaterialLocalizations] delegates do not natively include
/// the 'yue' subtag in [kMaterialSupportedLanguages], this delegate bridges framework-level
/// widget localizations (such as DatePicker, TimePicker, Material Text Selection)
/// to Traditional Chinese (Hong Kong - `zh_HK`), while all application-level strings
/// are resolved from `app_yue.arb`.
class CantoneseMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const CantoneseMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'yue';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('zh', 'HK'));
  }

  @override
  bool shouldReload(CantoneseMaterialLocalizationsDelegate old) => false;
}

/// Provides Flutter framework CupertinoLocalizations for Cantonese (`yue`).
class CantoneseCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CantoneseCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'yue';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('zh', 'HK'));
  }

  @override
  bool shouldReload(CantoneseCupertinoLocalizationsDelegate old) => false;
}
