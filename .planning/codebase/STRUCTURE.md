---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
# Codebase Structure

**Analysis Date:** 2026-11-07

## Directory Layout

```text
shonenx/
├── .agents/                 # GSD workflows, skills, and agent runtime configurations
├── .github/                 # GitHub Actions workflows (release, docs, notification CI)
├── assets/                  # Icons, fonts, images, and static graphics
├── flatpak/                 # Flatpak build manifest and desktop integration metadata
├── nix/                     # Nix package definition
├── packages/                # Internal packages and git submodules
│   ├── anymex_extension_bridge/  # Native runtime bridge for AnymeX extensions
│   ├── byte_me/                  # Download and HLS remuxing engine
│   ├── commentum_client/         # Dart client for Commentum comments API
│   └── flutter_web_auth/         # Fork of flutter_web_auth_2 with WebView fallback
├── lib/                     # Main Flutter application source code
│   ├── core/                # Cross-cutting foundational modules (network, caching, router, theme)
│   ├── features/            # Feature-first domain modules
│   ├── shared/              # Reusable models, providers, and shared UI widgets
│   ├── source_engine/       # Anime & manga scraping, extractors, and source adapters
│   ├── app_init.dart        # Application pre-flight initialization & database setup
│   └── main.dart            # Flutter entry point and root error boundaries
├── scripts/                 # Standalone maintenance and source generation scripts
├── analysis_options.yaml    # Dart and Flutter linter rules
├── build.dart               # Dart native assets build hook
├── flake.nix                # Nix flake definition
└── pubspec.yaml             # Flutter dependencies, package metadata, and Inno Setup config
```

## Directory Purposes

**`lib/core/`:**
- Purpose: Infrastructure and cross-cutting capabilities used throughout the app
- Contains: Caching mechanisms, DNS over HTTPS (DoH), network session management, stream proxy server, GoRouter configuration, AppTheme, and logging utilities
- Key files: `lib/core/caching/cache_manager.dart`, `lib/core/router/app_router.dart`, `lib/core/network/session_manager.dart`, `lib/core/utils/app_logger.dart`

**`lib/features/`:**
- Purpose: Domain-specific feature modules implemented using feature-first clean architecture
- Contains:
  - `calendar/`: Airing anime schedules and countdowns
  - `comments/`: Episode comment threads via Commentum
  - `discord/`: Discord RPC integration and rich presence
  - `discovery/`: Media browsing, trending anime/manga lists, and media details
  - `downloads/`: Download manager and offline task tracking
  - `episode_metadata/`: Episode titles and thumbnail resolution (Tenrai, AniZip, Jikan)
  - `extensions/`: Third-party extension management, repository browsing, and testing
  - `history/`: Watch and read progress history tracking
  - `library/`: User bookmarked and organized media collections
  - `notifications/`: Local airing alert scheduling and notifications
  - `player/`: Video streaming player supporting MediaKit and BetterPlayer engines
  - `reader/`: Manga reader supporting vertical webtoon and paged modes
  - `security/`: App lock, biometric gate, and PIN authorization
  - `settings/`: User settings panels (theming, storage, player, tracking, logs)
  - `tracking/`: Multi-service tracker synchronization (AniList, MAL, Kitsu, Simkl)
  - `updates/`: GitHub Release checking and in-app updating

**`lib/source_engine/`:**
- Purpose: Extensible media source system and scraper engines
- Contains: Built-in anime/manga extractors (Hianime, AnimePahe, AniKoto, etc.), matchmaker engine for title resolution, and unified source adapters
- Key files: `lib/source_engine/source_registry.dart`, `lib/source_engine/adapters/base_source_adapter.dart`, `lib/source_engine/matchmaker/match_service.dart`

**`lib/shared/`:**
- Purpose: Shared components, domain models, and global providers
- Contains: `UnifiedMedia` entity, global database provider (`databaseProvider`), SharedPreferences provider, and reusable UI components (`AppButton`, `MediaCard`)
- Key files: `lib/shared/models/unified_media.dart`, `lib/shared/providers/database_provider.dart`

**`packages/`:**
- Purpose: Monorepo sub-packages and submodules maintaining decoupled functionality
- Contains:
  - `anymex_extension_bridge/`: Kotlin and C++ runtime bridges
  - `byte_me/`: Download engine with HLS chunk assembly and encryption support
  - `commentum_client/`: HTTP client for user comments and replies
  - `flutter_web_auth/`: Multi-platform OAuth webview bridge

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Root Flutter entry point and window initializers
- `lib/app_init.dart`: Service bootstrapper and Isar database initializer
- `lib/core/router/app_router.dart`: Navigation routes and deep-link dispatcher

**Configuration:**
- `pubspec.yaml`: App dependencies, assets, and Inno Setup configuration
- `analysis_options.yaml`: Dart analyzer and linter presets
- `.fvmrc`: Pinned Flutter SDK version (`3.41.9`)
- `keys.example.json`: Schema for compile-time environment flags

**Core Logic:**
- `lib/source_engine/source_registry.dart`: Source engine registry
- `lib/features/player/engine/video_engine.dart`: Abstract video playback engine
- `lib/features/tracking/engine/tracking_service.dart`: Media progress synchronization service
- `lib/core/caching/cache_manager.dart`: Response caching engine
- `lib/core/network/stream_server/stream_server.dart`: Local HTTP stream server

**Testing:**
- Root level currently lacks a `test/` folder (unit and widget tests for core application need implementation)
- Sub-package tests: `packages/flutter_web_auth/flutter_web_auth_2/test/flutter_web_auth_2_test.dart`

## Naming Conventions

**Files:**
- Dart files: snake_case ending with component role: `*_screen.dart`, `*_provider.dart`, `*_service.dart`, `*_model.dart`, `*_widget.dart` (e.g. `lib/features/player/presentation/player_screen.dart`)

**Directories:**
- Directories: lowercase snake_case (e.g. `lib/features/episode_metadata/`)

**Classes & Types:**
- Classes: UpperCamelCase (e.g. `PlayerController`, `UnifiedMedia`, `TrackingService`)
- Riverpod Providers: lowerCamelCase ending with `Provider` (e.g. `playerControllerProvider`, `databaseProvider`)
- Isar Schemas: UpperCamelCase with `Schema` suffix for generated schemas (e.g. `LibraryEntrySchema`)

## Where to Add New Code

**New Feature:**
- Add a new directory under `lib/features/<new_feature>/`
- Implement 3 to 4 standard subdirectories:
  - `domain/`: Models and business contracts
  - `providers/`: Riverpod `Notifier` or `StateNotifier` classes
  - `presentation/`: UI screens and private widgets
  - `data/` (optional): Repositories, REST clients, or external service helpers
- Register new routes in `lib/core/router/app_router.dart`

**New Media Source or Scraper:**
- Implement scraper class under `lib/source_engine/inbuilt_sources/anime/` or `manga/`
- Inherit from `BaseSourceAdapter` (`lib/source_engine/adapters/base_source_adapter.dart`)
- Register the new source in `lib/source_engine/source_registry.dart`

**New Tracking Provider:**
- Implement provider class under `lib/features/tracking/engine/trackers/<tracker_name>/`
- Inherit from `BaseTracker` (`lib/features/tracking/engine/base_tracker.dart`)
- Register in `lib/features/tracking/providers/tracker_registry.dart`

**New Database Entity:**
- Define class annotated with `@collection` under corresponding feature `domain/models/`
- Run code generation: `dart run build_runner build --delete-conflicting-outputs`
- Register the generated `*Schema` in `Isar.open([...])` inside `lib/app_init.dart:134`

**Utilities:**
- Shared helper functions: `lib/core/utils/`
- Reusable UI widgets: `lib/shared/widgets/`

## Special Directories

**`packages/`:**
- Sub-packages managed as Git submodules or separate Dart packages. Do not commit changes here without committing to their respective repositories.

**`.dart_tool/` & `build/`:**
- Generated by Dart and Flutter build processes. Excluded from git.

**`flatpak/` & `nix/`:**
- Linux packaging recipes and system manifests maintained for distribution.

---

*Structure analysis: 2026-11-07*
