---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
# Coding Conventions

**Analysis Date:** 2026-11-07

## Naming Patterns

**Files:**
- Dart files: `snake_case.dart` reflecting component role (e.g. `lib/features/history/data/history_repository.dart`, `lib/features/player/presentation/player_screen.dart`, `lib/features/discovery/providers/home_provider.dart`)
- Presentation components: `*_screen.dart` for top-level pages, `*_dialog.dart` or `*_sheet.dart` for overlays, `*_tile.dart` or `*_card.dart` for UI widgets
- Providers: `*_provider.dart`

**Classes:**
- UpperCamelCase for all classes, enums, extensions, and mixins (e.g. `HistoryRepository`, `UnifiedMedia`, `TrackingService`, `DohResolver`)
- Enums: UpperCamelCase with descriptive names (e.g. `BackupCategory`, `MediaType`, `TrackerType`)

**Functions & Methods:**
- lowerCamelCase for functions and class methods (e.g. `saveProgress()`, `deleteByMediaId()`, `fetchRemoteConfig()`)
- Private helper methods prefixed with an underscore (e.g. `_initDatabase()`, `_initWindowManager()`)

**Variables & Parameters:**
- lowerCamelCase for local variables and parameters (e.g. `mediaType`, `sharedPreference`)
- Private fields and local file-scoped singletons prefixed with an underscore (e.g. `_log`, `_currentConfig`, `_isar`)
- Global constant environment keys in UPPER_SNAKE_CASE (e.g. `ANILIST_CLIENT_ID` in `lib/core/utils/env.dart`)

**Types & Records:**
- Dart 3 Records using parenthesis syntax with named fields (e.g. `({String mediaType, int limit})` in `lib/features/history/providers/history_provider.dart`)
- Isar collections annotated with `@collection` using UpperCamelCase (e.g. `@collection class HistoryEntry`)

## Code Style

**Formatting:**
- Official Dart formatting enforced via `dart format` (120/80 line width standard, trailing commas on multi-line parameter lists and widgets)
- Analysis configuration in `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml`

**Linting:**
- Linter configured via `analysis_options.yaml`
- `experimental_member_use: ignore` permitted in analyzer error settings
- Excluded paths: `build/**`, `android/**`, `ios/**`, `windows/**`, `macos/**`, `linux/**`

## Import Organization

**Order:**
1. Dart core libraries (`dart:async`, `dart:io`, `dart:ui`, `dart:convert`)
2. External 3rd-party packages (`package:flutter/material.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:isar_community/isar.dart`)
3. Internal project modules using absolute package paths (`package:shonenx/core/...`, `package:shonenx/features/...`, `package:shonenx/shared/...`)
4. Relative imports for tightly-coupled sibling files (e.g. `./widgets/custom_button.dart`)

**Path Aliases:**
- Standard package import root: `package:shonenx/...`
- Path package import convention: `import 'package:path/path.dart' as p;`
- Timezone package convention: `import 'package:timezone/timezone.dart' as tz;`

## Error Handling

**Patterns:**
- Root error boundary in `lib/main.dart` catching both Flutter widget errors (`FlutterError.onError`) and unhandled platform dispatcher errors (`PlatformDispatcher.instance.onError`)
- Explicit try/catch blocks around asynchronous I/O and network operations with error logging:
  ```dart
  try {
    // async work
  } catch (e, st) {
    _log.e('Operation failed', e, st);
    // fallback or graceful rethrow
  }
  ```
- Presentation error states handled using Riverpod `AsyncValue.when`:
  ```dart
  asyncData.when(
    data: (data) => ContentWidget(data),
    loading: () => const LoadingIndicator(),
    error: (err, stack) => ErrorDisplay(err),
  );
  ```

## Logging

**Framework:**
- Structured, level-filtered custom logging engine in `lib/core/utils/app_logger.dart` wrapping `logger: ^2.8.0`

**Patterns:**
- Instantiate a file/class scoped logger:
  ```dart
  static final _log = AppLogger.scope('ComponentName');
  ```
- Hierarchical child logging for sub-operations:
  ```dart
  final log = _log.child('subOperation');
  log.i('Processing item');
  log.s('Completed successfully');
  log.w('Warning encountered');
  log.e('Fatal failure', error, stackTrace);
  ```
- File-based log rotation with a 2MB cap and in-app viewing via `lib/features/settings/presentation/logs_screen.dart`

## Comments

**When to Comment:**
- Document public API contracts and rationale for platform-specific quirks (e.g. Linux tiling window managers in `lib/app_init.dart:97`)
- Annotate complex regular expressions and stream cipher operations (e.g. `lib/core/network/stream_server/hls/hls_crypto.dart`)

**JSDoc/TSDoc / DartDoc:**
- DartDoc triple-slash `///` comments used on public service interfaces and helper methods:
  ```dart
  /// Helper to push this route and await resolution.
  static Future<bool> open(BuildContext context, String url) { ... }
  ```

## Function Design

**Size:**
- Single-responsibility functions kept concise (<50 lines where practical)
- Complex UI trees decomposed into dedicated widget classes or private sub-methods

**Parameters:**
- Named parameters preferred for widgets and multi-argument service methods with `required` modifiers
- Dart 3 records used for multi-parameter provider families:
  ```dart
  final historyProvider = StreamProvider.autoDispose
      .family<List<HistoryEntry>, ({String mediaType, int limit})>((ref, args) { ... });
  ```

**Return Values:**
- Explicit return types declared for all public functions (`Future<void>`, `Stream<T>`, `Widget`)

## Module Design

**Exports:**
- Feature public APIs grouped and exported from clean boundary files where appropriate
- Internal feature widgets kept inside feature `presentation/widgets/`

**Barrel Files:**
- Used for grouping related domain entities (e.g. `lib/features/tracking/engine/trackers/index.dart`)

---

*Convention analysis: 2026-11-07*
