# Architecture Overview

ShonenX relies heavily on Riverpod for state management and dependency injection, GoRouter for declarative routing, and Isar for high-performance local persistence.

## Layer Boundaries

The codebase enforces a strict feature-first folder structure. Cross-feature dependencies should be actively minimized to prevent tightly coupled code.

### `lib/features/`
Owns the domain business logic and the presentation layer for distinct vertical slices of the app. Each feature isolate its layers:
*   `domain/`: Abstract data models and interface definitions.
*   `engine/` (or `data/`): Internal logic, API fetchers, and repository implementations.
*   `providers/`: Riverpod providers. This is the **only** layer that should expose state or engines to the `presentation/` layer.
*   `presentation/`: UI screens and widgets. These must consume state exclusively via `ConsumerWidget` and Riverpod.

### `lib/core/`
Provides cross-cutting infrastructure that multiple features depend on.
*   **Networking:** Abstractions over the HTTP client (using `rhttp`).
*   **Routing:** The `GoRouter` configuration in [`app_router.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/router/app_router.dart).
*   **Caching:** General-purpose caching utilities (see [Infrastructure](./infrastructure.md)).
*   **Theme:** Global styling and `flex_color_scheme` initialization.

### `lib/shared/`
Exposes reusable data models and UI components. If a model (like `UnifiedMedia`) or a widget (like a standard Anime Card) is required by both the `library` and the `discovery` features, it belongs here.

### `lib/source_engine/`
Acts as a unified facade. It resolves and normalizes media payloads from both internal sources and dynamic extensions (via the `anymex_extension_bridge`). See the [Extensions Guide](../extensions/) for details.
