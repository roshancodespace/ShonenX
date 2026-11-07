# ShonenX Localization Guide (i18n & L10n)

This document explains the architecture, translation workflows, conventions, and maintenance guidelines for the ShonenX application localization system.

---

## 1. Overview & Architecture

ShonenX uses Flutter's official localization infrastructure built around:
- `flutter_localizations` (from Flutter SDK)
- `intl`
- Flutter `gen_l10n` tool
- ARB (Application Resource Bundle) translation files in `lib/l10n/`
- Riverpod state management for reactive, zero-restart locale switching
- Persistent storage via `SharedPreferences`

### Architecture Diagram

```
lib/l10n/app_*.arb (10 Locales)
           │
           ▼ (flutter gen-l10n)
lib/l10n/generated/app_localizations.dart
           │
           ▼
lib/main.dart (MaterialApp.router)
    ├── localizationsDelegates:
    │     ├── AppLocalizations.delegate
    │     ├── CantoneseMaterialLocalizationsDelegate()
    │     ├── CantoneseCupertinoLocalizationsDelegate()
    │     ├── GlobalMaterialLocalizations.delegate
    │     ├── GlobalWidgetsLocalizations.delegate
    │     └── GlobalCupertinoLocalizations.delegate
    ├── supportedLocales: AppLocalizations.supportedLocales
    └── locale: ref.watch(appLocaleProvider)
```

---

## 2. Supported Languages

| Language | Locale Code | Native Name | Script & Direction | Special Handling |
|---|---|---|---|---|
| **English** | `en` | English | Latin (LTR) | Primary source & fallback language |
| **Hindi** | `hi` | हिन्दी | Devanagari (LTR) | Font fallback via Noto Sans Devanagari |
| **Japanese** | `ja` | 日本語 | Kanji/Kana (LTR) | Font fallback via Noto Sans JP |
| **Spanish** | `es` | Español | Latin (LTR) | Standard LTR |
| **Portuguese** | `pt` | Português | Latin (LTR) | Standard LTR |
| **French** | `fr` | Français | Latin (LTR) | Single quotes escaped as `''` in ARB |
| **German** | `de` | Deutsch | Latin (LTR) | Accommodates longer compound words |
| **Arabic** | `ar` | العربية | Arabic (RTL) | Native RTL directionality + ICU plurals (zero, one, two, few, many, other) |
| **Bengali** | `bn` | বাংলা | Bengali (LTR) | Standard Bengali script + Noto Sans Bengali font fallback |
| **Cantonese** | `yue` | 廣東話 | Traditional Chinese (LTR) | Traditional Chinese characters, authentic Cantonese phrasing, custom framework delegate bridge |

---

## 3. Cantonese (`yue`) Architecture

### The Framework Bridge
Flutter's `GlobalMaterialLocalizations` does not include `yue` in `kMaterialSupportedLanguages`. To prevent runtime crashes when users select Cantonese, ShonenX provides:
- `CantoneseMaterialLocalizationsDelegate` in `lib/core/localization/cantonese_localizations_delegate.dart`
- `CantoneseCupertinoLocalizationsDelegate` in `lib/core/localization/cantonese_localizations_delegate.dart`

These delegates map low-level framework widgets (such as DatePicker, TimePicker, and Copy/Paste tooltips) to Traditional Chinese (Hong Kong - `zh_HK`), while all application-level strings are strictly loaded from `lib/l10n/app_yue.arb` using authentic Cantonese phrasing (e.g., 睇緊, 搵嘢, 搞掂, 介面語言).

---

## 4. Typography & Font Fallbacks

To prevent missing glyphs or tofu boxes (`□`) on Linux, Windows, and Android for Bengali, Arabic, Devanagari, and CJK characters, `AppTheme` in `lib/core/theme/app_theme.dart` configures a comprehensive `fontFamilyFallback` across all text styles:

```dart
fontFamilyFallback: const [
  'Noto Sans',
  'Noto Sans Arabic',
  'Noto Sans Bengali',
  'Noto Sans Devanagari',
  'Noto Sans JP',
  'Noto Sans TC',
  'Noto Sans HK',
  'sans-serif',
]
```

---

## 5. Adding or Modifying Translations

### Step 1: Update the Template File
Always add or modify keys in `lib/l10n/app_en.arb` first:

```json
"myNewFeature": "My Feature Title",
"@myNewFeature": {
  "description": "Explains where this string is used"
}
```

### Step 2: Add Translations to All ARB Files
Add the translation to all corresponding `lib/l10n/app_<locale>.arb` files:
- `app_hi.arb`
- `app_ja.arb`
- `app_es.arb`
- `app_pt.arb`
- `app_fr.arb` (Note: escape apostrophes as `''`, e.g. `l''application`)
- `app_de.arb`
- `app_ar.arb`
- `app_bn.arb`
- `app_yue.arb`

### Step 3: Regenerate Localization Files
Run the Flutter code generator:

```bash
flutter gen-l10n
```

Generated files are output into `lib/l10n/generated/`.

### Step 4: Consume in Widgets
Import the extension and use `context.l10n`:

```dart
import 'package:shonenx/core/localization/l10n_extension.dart';

// Inside build method:
Text(context.l10n.myNewFeature)
```

---

## 6. ARB Key Naming Conventions

Keys should follow a domain-scoped camelCase convention:

| Domain | Key Prefix | Example |
|---|---|---|
| Common actions / state | `common*` | `commonCancel`, `commonSave`, `commonLoading` |
| Navigation labels | `nav*` | `navHome`, `navSearch`, `navLibrary` |
| Home & Discovery | `home*`, `discovery*` | `homeTrendingAnime`, `discoverySearchHint` |
| Media Details | `details*` | `detailsEpisodes`, `detailsWatchNow` |
| Video Player | `player*` | `playerQuality`, `playerServer`, `playerSpeed` |
| Manga Reader | `reader*` | `readerMode`, `readerLeftToRight` |
| Tracking & Accounts | `tracking*` | `trackingConnectedAs`, `trackingStatusWatching` |
| Downloads | `downloads*` | `downloadsTitle`, `downloadsPauseAll` |
| Settings | `settings*` | `settingsTitle`, `settingsLanguage`, `settingsThemeMode` |
| TV Interface | `tv*` | `tvTitle`, `tvHome`, `tvDiscover` |

---

## 7. Pluralization & Parameter Placeholders

Use standard ICU message formats with placeholders:

### Simple Parameter
```json
"greeting": "Hello {username}!",
"@greeting": {
  "placeholders": {
    "username": { "type": "String" }
  }
}
```

### Plurals
```json
"episodesCount": "{count, plural, =0{No episodes} =1{1 episode} other{{count} episodes}}",
"@episodesCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

---

## 8. Verification & Tests

To verify that localization resources compile and pass all tests:

```bash
flutter test test/core/localization_test.dart
flutter analyze lib/l10n/ lib/core/localization/
```

