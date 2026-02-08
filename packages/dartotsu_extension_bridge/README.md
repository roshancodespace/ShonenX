# Dartotsu Extension Bridge

A Flutter plugin that bridges **Aniyomi** and **Mangayomi** style extension sources into a unified Dart API.

It is designed for apps that need to:
- Discover extension repositories and installed extensions.
- Install, update, and uninstall extensions.
- Call source APIs in a consistent way (`popular`, `latest`, `search`, details, pages/videos, preferences).
- Reuse optional UI components for extension management.

## Features

- Unified extension manager abstraction (`ExtensionManager`) across backends.
- Runtime backend switching (`ExtensionType.mangayomi` / `ExtensionType.aniyomi`).
- Source-level API wrappers through `SourceMethods`.
- Built-in models for content and stream/page payloads.
- Optional ready-to-use UI helpers (`ExtensionManagerScreen`, `ExtensionList`).

## Platform support

Plugin platforms declared in `pubspec.yaml`:
- Android
- iOS
- Linux
- macOS
- Windows

> Note: **Aniyomi extensions are Android-only**. On non-Android platforms, use the Mangayomi backend.

## Requirements

- Dart SDK: `^3.8.1`
- Flutter: `>=3.3.0`

## Dependencies

### Runtime dependencies

Core dependencies used by this package (from `pubspec.yaml`):

- `plugin_platform_interface`
- `http`, `http_interceptor`
- `isar_community`, `isar_community_flutter_libs`
- `get`
- `path`, `path_provider`
- `html`, `intl`, `crypto`, `encrypt`
- `xpath_selector_html_parser`, `js_packer`, `pseudom`, `fjs`, `d4rt`
- `flutter_inappwebview`
- `install_plugin`, `device_apps`
- `flutter_qjs` (git dependency)
- `epubx` (git dependency)

### Development dependencies

- `flutter_test`
- `flutter_lints`
- `isar_community_generator`
- `build_runner`

### Notes on dependency behavior

- `flutter_inappwebview` is used for webview-based runtime behavior on supported platforms.
- `isar_community` is used for persistent storage (settings/source metadata/cache).
- Android extension install workflows rely on `install_plugin` and (in parts of the flow) device app visibility helpers.
- Git dependencies (`flutter_qjs`, `epubx`) require network access when resolving packages.

## Installation

Add `dartotsu_extension_bridge` to your project:

```yaml
dependencies:
  dartotsu_extension_bridge:
    git:
      url: https://github.com/<your-org-or-user>/DartotsuExtensionBridge.git
      ref: <branch-or-tag>
```

Then fetch packages:

```bash
flutter pub get
```

## Quick start

### 1) Initialize the bridge early

Call `init` during app startup (before accessing extensions):

```dart
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

final bridge = DartotsuExtensionBridge();

await bridge.init(
  null,               // pass an Isar instance, or null to auto-create
  'my_app_data_dir',  // desktop data dir hint
);
```

### 2) Access and configure manager backend

```dart
import 'package:get/get.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

final extensionManager = Get.find<ExtensionManager>();

// Optional: switch backend at runtime
extensionManager.setCurrentManager(ExtensionType.mangayomi);

final manager = extensionManager.currentManager;
```

### 3) Query installed/available extensions

```dart
// Installed
final installedAnime = await manager.getInstalledAnimeExtensions();
final installedManga = await manager.getInstalledMangaExtensions();

// Remote repo index -> available
final availableAnime = await manager.fetchAvailableAnimeExtensions([
  'https://raw.githubusercontent.com/your/repo/index.min.json',
]);
```

### 4) Call source methods

```dart
final source = installedAnime.first;
final methods = source.methods;

final popular = await methods.getPopular(1);
final latest = await methods.getLatestUpdates(1);
final search = await methods.search('one piece', 1, []);

final detailed = await methods.getDetail(search.list.first);
```

### 5) Fetch pages/videos and manage preferences

```dart
final item = detailed.episodes!.first;

final pages = await methods.getPageList(item);
final videos = await methods.getVideoList(item);

final prefs = await methods.getPreference();
if (prefs.isNotEmpty) {
  await methods.setPreference(prefs.first, true);
}
```

## Public API overview

Main import:

```dart
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
```

Commonly used exports include:
- `DartotsuExtensionBridge`
- `ExtensionManager`, `ExtensionType`
- `Extension`, `SourceMethods`
- `Source`, `DMedia`, `DEpisode`, `PageUrl`, `Pages`, `Video`, `SourcePreference`

## UI helpers

Use these prebuilt widgets if you want a quick extension UI scaffold:
- `ExtensionManagerScreen`
- `ExtensionList`

## Development

```bash
flutter pub get
flutter analyze
```

## Operational notes

- Settings and source metadata are persisted via Isar.
- On Windows, `flutter_inappwebview` setup is initialized when available.
- Android Aniyomi APK install behavior depends on OS permissions and device settings.

## License

See [LICENSE](LICENSE).
