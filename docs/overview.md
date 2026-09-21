# Overview

ShonenX is a cross-platform Anime and Manga client built with Flutter. It aggregates content from multiple online sources (via an extensible bridge) and synchronizes user progress seamlessly with major tracking services (AniList, MyAnimeList, Simkl, Kitsu).

## Core Capabilities

*   **Universal Media Engine**: Integrates natively with Mangayomi, Cloudstream, and Aniyomi extensions, executing their format-specific logic within ShonenX.
*   **Matchmaking**: Automatically binds source-specific media IDs to global tracker IDs using a robust title-matching and metadata algorithm.
*   **Media Consumption**: Features a native video player via `media_kit`, torrent streaming via `libtorrent_flutter`, and a fully functional offline download manager.
*   **Synchronization**: Reconciles local database state (Isar) with remote REST/GraphQL tracker APIs, guaranteeing progress is preserved even when offline.

## Repository Map

The repository separates generic UI frameworks from domain logic. Read the [Architecture Overview](/setup/architecture) for a deep dive into the layer boundaries.

| Directory | Purpose |
| --- | --- |
| [`lib/core/`](https://github.com/roshancodespace/shonenx/tree/main/lib/core/) | Core infrastructure: networking (`rhttp`), routing (`go_router`), caching, theme configuration, and services. |
| [`lib/features/`](https://github.com/roshancodespace/shonenx/tree/main/lib/features/) | Domain-driven feature slices (e.g., `player`, `library`, `tracking`, `downloads`). Each feature contains its own domain models, providers, and presentation layers. |
| [`lib/shared/`](https://github.com/roshancodespace/shonenx/tree/main/lib/shared/) | Reusable data models (`UnifiedMedia`) and generalized UI components (cards, lists, buttons) used across multiple features. |
| [`lib/source_engine/`](https://github.com/roshancodespace/shonenx/tree/main/lib/source_engine/) | The facade that resolves and normalizes media payloads from inbuilt sources and extensions. |
| [`packages/anymex_extension_bridge/`](https://github.com/roshancodespace/shonenx/tree/main/packages/anymex_extension_bridge/) | The runtime bridge that executes foreign extension logic natively in ShonenX. |
