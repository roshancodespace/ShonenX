# Architecture Walkthrough

ShonenX enforces strict layer boundaries to prevent tightly coupled code. Understanding where files belong is the first step to contributing.

## The `lib/` Directory

### 1. `lib/core/`
This folder contains cross-cutting infrastructure. It does **not** contain product features.
- `caching/`: The `CacheManager` intercepts HTTP requests and saves them to Isar.
- `network/`: Abstractions over the raw HTTP client (using `rhttp`).
- `router/`: GoRouter setup (`app_router.dart`).
- `theme/`: Global styling logic.

### 2. `lib/features/`
This is where the actual business logic and UI reside. Each folder represents a vertical slice (e.g., `downloads/`, `tracking/`, `player/`).

Inside a typical feature folder, you will find:
- `domain/`: Abstract data models and interface definitions (e.g., `DownloadTask`).
- `engine/` or `data/` or `api/`: The internal logic, fetchers, and repositories.
- `providers/`: Riverpod providers. This is the **only** layer that should expose state to the presentation layer.
- `presentation/`: UI screens and widgets. These consume state exclusively via Riverpod. Providers should never be inside the `presentation/` directory.

### 3. `lib/shared/`
Reusable data models (`UnifiedMedia`) and generalized UI components (like standard Manga Cards). If a widget is required by both the `library` and the `discovery` features, it belongs here.

### 4. `lib/source_engine/`
A unified facade that resolves and normalizes media payloads from internal sources and dynamic Javascript extensions (via the `anymex_extension_bridge`). This operates almost like an independent package.

## Initialization Flow

When the app starts, the entry point is `lib/main.dart`, but the heavy lifting happens in [`lib/app_init.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart).

`AppInit.init()` runs sequentially:
1. Initializes `Rhttp`.
2. Configures `window_manager` (handling Linux/Windows desktop APIs).
3. Initializes `media_kit` for native video decoding.
4. Opens the Isar database.
5. Fires asynchronous setups (like loading cached trackers).
6. Post-launch: `setupBridge` is called lazily to spin up the JS runtime for extensions.
