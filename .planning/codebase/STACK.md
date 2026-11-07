---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
# Technology Stack

**Analysis Date:** 2026-11-07

## Languages

**Primary:**
- Dart `^3.9.2` (via Flutter `3.41.9` pinned in `.fvmrc`) - Application codebase across `lib/` and core logic
- C++ (C++17) - Native desktop plugin runtime bridges in `packages/anymex_extension_bridge/linux` and `packages/anymex_extension_bridge/windows`
- Kotlin - Android native bridge implementation in `packages/anymex_extension_bridge/RuntimeBridges/Android/app/src/main/kotlin`
- Swift / Objective-C - iOS/macOS integration stubs and platform channels in `ios/` and `macos/`
- Nix - Package definition and build flake in `flake.nix` and `nix/package.nix`

**Secondary:**
- Bash / Shell - Build automation, installation script `install.sh`, and utility scripts in `scripts/`
- CMake - Native build configurations for Linux and Windows targets in `linux/CMakeLists.txt` and `windows/CMakeLists.txt`
- YAML - Flutter package definitions (`pubspec.yaml`), workflow specs (`.github/workflows/`), and linter configuration (`analysis_options.yaml`)

## Runtime

**Environment:**
- Flutter SDK `3.41.9` (Dart SDK `>=3.9.2 <4.0.0`) configured via `.fvm/` and `.fvmrc`
- Target platforms: Android, iOS, Linux (Flatpak/Native), macOS, Windows (Inno Setup)

**Package Manager:**
- Flutter Pub (`pubspec.yaml`, lockfile `pubspec.lock` present and committed)
- Git Submodules for ecosystem packages (`.gitmodules` tracking `packages/anymex_extension_bridge`, `packages/byte_me`, `packages/commentum_client`, `packages/flutter_web_auth`, and `lib/source_engine/inbuilt_sources`)

## Frameworks

**Core:**
- Flutter (Material Design 3 via `flex_color_scheme: ^8.4.0` and `dynamic_color: 1.8.1`) - Cross-platform UI toolkit
- Riverpod (`flutter_riverpod: ^3.3.1`) - Declarative state management and dependency injection across `lib/`
- GoRouter (`go_router: ^17.2.1`) - Declarative navigation and deep-link routing in `lib/core/router/app_router.dart`
- Isar Community (`isar_community: 3.3.2`, `isar_community_flutter_libs: 3.3.2`) - High-performance NoSQL embedded database for local storage

**Testing:**
- `flutter_test` (Flutter SDK) - Testing framework in `pubspec.yaml`
- `test: ^1.25.6` - Dart test runner in `packages/byte_me/pubspec.yaml`

**Build/Dev:**
- `build_runner: ^2.15.1` - Code generation tool for Isar schemas (`isar_community_generator: 3.3.2`)
- `inno_bundle: ^0.11.2` - Windows installer generator configured in `pubspec.yaml`
- `package_rename: ^1.10.1` - App metadata and identity manager
- `flutter_launcher_icons: ^0.14.4` - Multi-platform app launcher icon generator (`flutter_launcher_icons.yaml`)
- `flutter_lints: ^5.0.0` - Official Flutter linting rule presets in `analysis_options.yaml`

## Key Dependencies

**Critical:**
- `media_kit` (git fork: `https://github.com/Predidit/media-kit.git`, ref `78d4cce7b49d5b6b918f78b18ec1fbb7c400b9da`) - High-performance video playback engine leveraging mpv/FFmpeg in `lib/features/player/engine/media_kit/media_kit_engine.dart`
- `better_player_plus: ^1.0.8` - Alternative/fallback video playback engine based on ExoPlayer in `lib/features/player/engine/better_player/better_player_engine.dart`
- `rhttp: ^0.18.0` - High-performance Rust-backed HTTP client used for media scraping and network calls
- `isar_community: 3.3.2` - Embedded local database engine powering library, history, caching, and tracker links in `lib/app_init.dart`
- `flutter_riverpod: ^3.3.1` - Foundational application state architecture
- `go_router: ^17.2.1` - Stateful shell routing and deep-link handler

**Infrastructure:**
- `flutter_secure_storage: ^10.3.1` (with Linux rewrite fork `EchoEllet/flutter_secure_storage`) - Keytar/SecretService encrypted token storage in `lib/core/network/secure_storage.dart`
- `shared_preferences: ^2.5.5` - User preference persistence in `lib/shared/providers/storage_provider.dart`
- `window_manager: ^0.5.1` - Desktop window controls, frameless window support, and tiling WM detection in `lib/app_init.dart`
- `flutter_single_instance: ^1.7.0` - IPC and single application instance enforcement on desktop in `lib/main.dart`
- `flutter_local_notifications: ^20.1.0` & `timezone: ^0.10.1` - Airing episode alerts and scheduled notifications in `lib/core/services/notification_service.dart`
- `flutter_discord_rpc_fork` (git `kodjodevf/flutter-discord-rpc.git`) - Rich Presence integration for Discord in `lib/features/discord/services/discord_rpc_service.dart`
- `webview_all: ^1.4.4` / `flutter_inappwebview: 6.2.0-beta.2` - Headless and interactive web views for Cloudflare challenge resolution in `lib/core/widgets/cloudflare_webview.dart`
- `logger: ^2.8.0` - Structured contextual logging in `lib/core/utils/app_logger.dart`

## Configuration

**Environment:**
- Defined via `--dart-define-from-file=keys.json` in `lib/core/utils/env.dart`:
  - `ANILIST_CLIENT_ID` / `ANILIST_CLIENT_SECRET` (pipe-delimited for mobile/desktop credentials)
  - `MAL_CLIENT_ID` / `MAL_CLIENT_SECRET` (pipe-delimited for mobile/desktop credentials)
  - `SIMKL_CLIENT_ID` / `SIMKL_CLIENT_SECRET`
  - `COMMENTUM_API_URL`
  - `RELEASE_REPO`
- Template provided in `keys.example.json`

**Build:**
- Flutter build configs: `pubspec.yaml`, `build.dart` (Dart native assets hooks), `flutter_launcher_icons.yaml`, `package_rename_config.yaml`
- Linux packaging: `flatpak/io.github.roshancodespace.shonenx.yml`, `flatpak/shonenx.desktop`, `nix/package.nix`, `flake.nix`
- Windows installer: `inno_bundle` section in `pubspec.yaml`
- Analysis & code quality: `analysis_options.yaml`

## Platform Requirements

**Development:**
- Flutter SDK `3.41.9` (via FVM: `fvm flutter`)
- Dart SDK `^3.9.2`
- CMake, Ninja, C++ compiler, GTK-3, and mpv libraries for Linux desktop development
- Android SDK 34+ / NDK for Android targets
- Xcode 15+ / CocoaPods for macOS/iOS targets

**Production:**
- Linux: Flatpak (`io.github.roshancodespace.shonenx`), AppImage, or Nix package (`nix build .#shonenx`)
- Windows: Windows 10/11 x64 installer built via `inno_bundle`
- Android: APK / AAB targeting Android 5.0+ (API 21+)
- macOS / iOS: Native App bundles

---

*Stack analysis: 2026-11-07*
