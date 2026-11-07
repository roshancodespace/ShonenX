---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
<!-- refreshed: 2026-11-07 -->
# Architecture

**Analysis Date:** 2026-11-07

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Presentation Layer (UI)                               │
├───────────────────┬─────────────────────┬───────────────────┬───────────────────┤
│   HomeScreen /    │    PlayerScreen     │   ReaderScreen    │  Settings / Nav   │
│  DetailsScreen    │                     │                   │                   │
│ `lib/features/`   │  `lib/features/`    │ `lib/features/`   │ `lib/features/`   │
│  `discovery/`     │     `player/`       │    `reader/`      │   `settings/`     │
└─────────┬─────────┴──────────┬──────────┴─────────┬─────────┴─────────┬─────────┘
          │                    │                    │                   │
          ▼                    ▼                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      Application Layer (Riverpod Providers)                      │
│       `lib/features/*/providers/` & `lib/shared/providers/`                     │
│  (StateNotifier, Notifier, AsyncNotifier, UI / Theme / Settings Notifiers)      │
└─────────┬────────────────────┬────────────────────┬───────────────────┬─────────┘
          │                    │                    │                   │
          ▼                    ▼                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Domain & Core Engines Layer                              │
├───────────────────┬─────────────────────┬───────────────────┬───────────────────┤
│   SourceEngine    │     VideoEngine     │   TrackingEngine  │  Download Engine  │
│ `lib/source_`     │  `lib/features/`    │  `lib/features/`  │ `packages/`       │
│    `engine/`      │   `player/engine/`  │  `tracking/`      │    `byte_me/`     │
└─────────┬─────────┴──────────┬──────────┴─────────┬─────────┴─────────┬─────────┘
          │                    │                    │                   │
          ▼                    ▼                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     Infrastructure & Data Access Layer                          │
├──────────────────────────┬──────────────────────────┬───────────────────────────┤
│  Local Database (Isar)   │   Local Stream Server    │  Network & Integrations   │
│ `lib/shared/providers/`  │  `lib/core/network/`     │ `lib/core/network/`       │
│   `database_provider`    │     `stream_server/`     │ `rhttp` / `DoHResolver`   │
└──────────────────────────┴──────────────────────────┴───────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `main()` | Application bootstrapping, desktop single instance enforcement, error boundaries | `lib/main.dart` |
| `AppInit` | Service orchestration (Rhttp, window manager, database initialization, schema migrations) | `lib/app_init.dart` |
| `routerProvider` | Declarative routing, URI parameter parsing, deep-link routing | `lib/core/router/app_router.dart` |
| `SourceEngine` | In-built and external content source aggregation, scraping, and metadata resolution | `lib/source_engine/source_registry.dart` |
| `VideoEngine` | Abstract video player interface controlling MediaKit and BetterPlayer engines | `lib/features/player/engine/video_engine.dart` |
| `StreamServer` | Local HTTP proxy server handling HLS key decryption and stream header spoofing | `lib/core/network/stream_server/stream_server.dart` |
| `TrackingService` | Multi-tracker sync engine scrobbling progress to AniList, MAL, Kitsu, and Simkl | `lib/features/tracking/engine/tracking_service.dart` |
| `CacheManager` | Isar-backed persistent caching with configurable TTL for API queries | `lib/core/caching/cache_manager.dart` |
| `DohResolver` | DNS over HTTPS client for bypassing DNS filtering and ISP blocks | `lib/core/network/doh/doh_resolver.dart` |
| `CloudflareWebView` | Fallback browser container to clear Cloudflare challenges and sync cookies | `lib/core/widgets/cloudflare_webview.dart` |
| `BackupService` | JSON export and import for user library, history, preferences, and tracker links | `lib/core/services/backup_service.dart` |
| `NotificationService` | Local scheduled notifications and background airing alerts | `lib/core/services/notification_service.dart` |

## Pattern Overview

**Overall:** Feature-First Clean Architecture with Riverpod and Strategy/Adapter Patterns

**Key Characteristics:**
- **Feature-First Organization:** High cohesion per domain (`lib/features/<feature>/presentation`, `domain`, `providers`, `data`)
- **Strategy Pattern for Engines:** Pluggable engines for video playback (`MediaKitEngine` vs `BetterPlayerEngine`) and trackers (`AniListTracker`, `MALTracker`, `KitsuTracker`, `SimklTracker`)
- **Adapter Pattern for Sources:** `BaseSourceAdapter` normalizes heterogeneous manga/anime providers into unified media contracts
- **Repository & In-Memory Providers:** Riverpod providers bridge between UI widgets and reactive Isar query watchers

## Layers

**Presentation Layer:**
- Purpose: Render Material 3 UI widgets, handle user input, animate transitions, and respond to screen sizing
- Location: `lib/features/*/presentation/` and `lib/shared/widgets/`
- Contains: Screens, dialogs, bottom sheets, UI components
- Depends on: Application Layer (Riverpod providers) and domain models
- Used by: Flutter framework rendering tree

**Application / Provider Layer:**
- Purpose: Manage state, respond to user actions, perform asynchronous operations, coordinate domain services
- Location: `lib/features/*/providers/` and `lib/shared/providers/`
- Contains: `StateNotifier`, `Notifier`, `AsyncNotifier`, and computed `Provider`s
- Depends on: Domain layer models and infrastructure services
- Used by: Presentation layer widgets

**Domain & Engine Layer:**
- Purpose: Pure business logic, source scraping, video player abstraction, tracking logic, data validation
- Location: `lib/features/*/domain/`, `lib/source_engine/`, `lib/features/tracking/engine/`
- Contains: Data entities, repository interfaces, abstract engines, parser utilities
- Depends on: Shared models (`lib/shared/models/`) and core utilities
- Used by: Provider layer

**Data & Infrastructure Layer:**
- Purpose: Persistence, raw network transport, platform channel communication, external service APIs
- Location: `lib/core/network/`, `lib/core/caching/`, `lib/core/services/`
- Contains: Isar database access, HTTP clients (`rhttp`, `http`), SecureStorage, native desktop bridge
- Depends on: Flutter plugins, platform SDKs, native binaries
- Used by: Domain and Provider layers

## Data Flow

### Primary Request Path (Anime Streaming)

1. **User Selection:** User taps anime episode in `lib/features/discovery/presentation/details_screen.dart`
2. **Navigation:** GoRouter activates `/player` route via `lib/core/router/app_router.dart` passing `UnifiedMedia`
3. **Source Resolution:** `SourceEngineProvider` calls `SourceRegistry.getSource()` (`lib/source_engine/source_registry.dart`)
4. **Stream Extraction:** Extractor fetches video streams and subtitles via `rhttp`/`http` (`lib/source_engine/inbuilt_sources/`)
5. **Proxy Setup:** If custom headers or decryption are required, stream URL is proxied through `StreamServer` (`lib/core/network/stream_server/stream_server.dart`)
6. **Playback:** `PlayerController` (`lib/features/player/providers/player_controller.dart`) initializes selected `VideoEngine` (`lib/features/player/engine/media_kit/media_kit_engine.dart`)
7. **AniSkip Matching:** AniSkip service queries timestamps for intro/outro skips (`lib/features/player/data/aniskip_service.dart`)
8. **Progress Scrobble:** `ProgressTracker` invokes `TrackingService` (`lib/features/tracking/engine/tracking_service.dart`) to sync watch time with Isar history and remote trackers (AniList/MAL)

### Secondary Flow (Manga Reading)

1. **User Selection:** User selects chapter in `lib/features/reader/presentation/reader_screen.dart`
2. **Page Extraction:** `ReaderProvider` (`lib/features/reader/providers/reader_provider.dart`) requests chapter pages from source adapter
3. **Image Fetching:** Pages are loaded through `ReaderImage` with headers configured via `ImageHeaders` (`lib/core/utils/image_headers.dart`)
4. **Progress Persistence:** Reading progress updates `ReadHistoryEntry` and updates linked remote trackers

**State Management:**
- Riverpod state container (`ProviderScope` in `lib/main.dart`)
- Fine-grained reactive subscriptions via `ref.watch()` in presentation widgets
- Persistent settings automatically synchronized to `SharedPreferences` and `Isar`

## Key Abstractions

**`BaseTracker` (`lib/features/tracking/engine/base_tracker.dart`):**
- Purpose: Contract for remote tracking services (authentication, searching, profile retrieval, progress scrobbling)
- Examples: `AniListTracker` (`lib/features/tracking/engine/trackers/anilist/anilist_tracker.dart`), `MALTracker` (`lib/features/tracking/engine/trackers/mal/mal_tracker.dart`)
- Pattern: Strategy Pattern

**`VideoEngine` (`lib/features/player/engine/video_engine.dart`):**
- Purpose: Unified playback control interface decoupling UI controls from the underlying player implementation
- Examples: `MediaKitEngine` (`lib/features/player/engine/media_kit/media_kit_engine.dart`), `BetterPlayerEngine` (`lib/features/player/engine/better_player/better_player_engine.dart`)
- Pattern: Strategy Pattern

**`BaseSourceAdapter` (`lib/source_engine/adapters/base_source_adapter.dart`):**
- Purpose: Normalized interface for anime and manga scrapers/extensions
- Examples: `AnimeSourceAdapter`, `MangaSourceAdapter`
- Pattern: Adapter Pattern

**`CacheManager` (`lib/core/caching/cache_manager.dart`):**
- Purpose: Unified TTL-aware query caching layer using Isar schemas
- Pattern: Cache-Aside / Repository

## Entry Points

**`main(List<String> args)` (`lib/main.dart`):**
- Location: `lib/main.dart:27`
- Triggers: Application binary launch by OS or CLI
- Responsibilities: Error boundary configuration (`FlutterError.onError`, `PlatformDispatcher.onError`), desktop single-instance check, logging initialization, bootstrapping `AppInit`, and launching `ProviderScope`

**`AppInit.init()` (`lib/app_init.dart`):**
- Location: `lib/app_init.dart:40`
- Triggers: Called by `main()` during initial splash phase
- Responsibilities: Initialize `Rhttp`, configure window manager and tiling WM rules, open Isar database, run schema migrations, start notification listeners

**Deep Link Router (`lib/core/router/app_router.dart`):**
- Location: `lib/core/router/app_router.dart:73`
- Triggers: Incoming deep links (`shonenx://`, `aniyomi://`, `tachiyomi://`, `mangayomi://`)
- Responsibilities: Parse target path, extract route parameters, and direct navigation

## Architectural Constraints

- **Threading:** Flutter single-threaded event loop; heavy decoding and native video rendering handled in background C++ threads by `media_kit` / `mpv` and Dart background isolates in `byte_me`
- **Global state:** Singletons used for infrastructure services: `AppLogger` (`lib/core/utils/app_logger.dart`), `SessionManager` (`lib/core/network/session_manager.dart`), `DohResolver` (`lib/core/network/doh/doh_resolver.dart`), `NotificationService` (`lib/core/services/notification_service.dart`)
- **Local Proxy Server:** Embedded Dart HTTP server runs locally on localhost (`StreamServer` in `lib/core/network/stream_server/stream_server.dart`) to rewrite HLS headers and decrypt media streams
- **Platform Discrepancies:** Linux tiling window managers (Hyprland, Niri) require explicit title bar and window option handling in `lib/app_init.dart:97`

## Anti-Patterns

### Dual State Management Library Imports
**What happens:** Occasional `import 'package:get/get.dart'` lingering in `lib/app_init.dart:8` while the entire app is built on Riverpod.
**Why it's wrong:** Introduces unnecessary dependency coupling and confuses developers on which state paradigm to follow.
**Do this instead:** Use Riverpod state providers and native Flutter context navigation exclusively, removing GetX references.

### In-App Cloudflare Bypass Reliance
**What happens:** Using interactive WebViews (`CloudflareWebView` in `lib/core/widgets/cloudflare_webview.dart`) to extract cookies and inject them into subsequent HTTP requests.
**Why it's wrong:** Third-party websites frequently rotate anti-bot challenges and headers, causing high maintenance overhead and fragile scraping.
**Do this instead:** Maintain modular extension scrapers in external repositories (`AnymeXExtensionRuntimeBridge`) so updates do not require full app releases.

## Error Handling

**Strategy:** Layered error boundaries with graceful degradation and persistent logging.

**Patterns:**
- Root error boundary in `lib/main.dart:86` catches unhandled bootstrapping exceptions and renders a red panic screen with readable stack trace.
- Scoped contextual logging via `AppLogger.scope('ComponentName')` capturing error details and stack traces without leaking secrets.
- Network calls wrap HTTP failures and fall back to cached Isar entries via `CacheManager`.

## Cross-Cutting Concerns

**Logging:** Scoped file and console logging via `AppLogger` in `lib/core/utils/app_logger.dart`.
**Validation:** Schema validation during JSON parsing and Isar entity persistence.
**Authentication:** Secure token storage via `FlutterSecureStorage` with multi-tracker OAuth flows.
**Theming & Styling:** Material 3 theming with `FlexColorScheme` and dynamic device wallpaper accents (`dynamic_color`).

---

*Architecture analysis: 2026-11-07*
