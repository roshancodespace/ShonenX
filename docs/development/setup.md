# Development Setup

## Environment Requirements

1.  **Flutter SDK**: ShonenX explicitly requires **Flutter 3.41.9** for development. Newer or older versions are known to cause plugin or build failures.
2.  **API Secrets**: To test tracking functionalities (AniList, MyAnimeList), you must duplicate [`keys.example.json`](https://github.com/roshancodespace/shonenx/blob/main/keys.example.json) as `keys.json` in the root and inject your valid API credentials.

## Code Generation

ShonenX relies on `build_runner` for Isar schemas (`.g.dart`) and complex Riverpod providers.

When altering any model annotated with `@collection`, regenerate the schemas:
```bash
dart run build_runner build -d
```

## Platform-Specific Configurations

### Windows

The native Flutter webview implementation is insufficient for specific authentication flows. ShonenX bundles a custom Windows-tailored fork of `flutter_inappwebview`. Ensure you have the [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) installed locally, or the application will fail to initialize in [`main.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/main.dart).

### Linux

To support borderless window framing without breaking modern tiling window managers (e.g., Hyprland, Niri), window initialization is executed conditionally. Check the `isTilingWm` logic within `_initWindowManager` in [`app_init.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart) if you encounter window decoration bugs.
